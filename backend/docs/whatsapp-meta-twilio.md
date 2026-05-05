# WhatsApp Business via Meta + Twilio — Guide de configuration

Ce guide explique comment configurer l'envoi de notifications WhatsApp en production
via **Meta WhatsApp Business Platform** avec **Twilio** comme fournisseur d'API.

---

## Pourquoi les messages WhatsApp échouent en production

Meta impose des règles strictes pour les messages **business-initiated** (messages envoyés
proactivement par l'application, sans que l'utilisateur n'ait écrit en premier) :

- Les messages en texte libre (**free-form**) sont **bloqués** en dehors de la fenêtre de
  service de 24 heures.
- Tous les messages proactifs (confirmations de commande, alertes de transport, etc.) doivent
  utiliser un **template de message approuvé par Meta** (Content Template).

> Le **sandbox Twilio** est une exception : il accepte les messages en texte libre pour les tests.
> En production, le Content Template est obligatoire.

---

## Prérequis

- Un compte Twilio actif ([console.twilio.com](https://console.twilio.com))
- Un compte Meta Business Manager ([business.facebook.com](https://business.facebook.com))
- Un numéro de téléphone dédié à WhatsApp Business (peut être votre numéro Twilio)

---

## Étape 1 — Créer un WhatsApp Business Account (WABA) avec Meta

1. Aller dans **Twilio Console → Messaging → Senders → WhatsApp Senders**.
2. Cliquer sur **"Connect a WhatsApp Sender"**.
3. Suivre le flux d'intégration Meta (Facebook Business Manager) :
   - Connecter ou créer un **Business Manager Meta**.
   - Créer ou sélectionner un **WhatsApp Business Account (WABA)**.
   - Enregistrer le numéro de téléphone choisi comme sender WhatsApp.
4. Vérifier le numéro (appel ou SMS de Meta).
5. Une fois approuvé, le numéro apparaît dans Twilio Console avec le statut **Active**.

> ⚠️ Le numéro sender doit avoir le préfixe `whatsapp:` dans la configuration :
> ex. `whatsapp:+33600000000`

---

## Étape 2 — Créer les Content Templates dans Twilio

L'application utilise **3 templates** au total :

> ⚠️ **Règles Meta critiques** :
> - La variable `{{1}}` **ne peut pas être au début ni à la fin** du corps du template
>   (subCode 2388299). Elle doit toujours être entourée de texte statique des deux côtés.
> - Le corps ne peut pas être **uniquement** `{{1}}` (variable seule).
> - La **catégorie** doit correspondre à l'usage réel : `AUTHENTICATION` pour les OTP,
>   `UTILITY` pour les notifications transactionnelles. Un mauvais choix entraîne
>   le rejet `INCORRECT_CATEGORY`.

### Template 1 — Notifications utilisateur (`sama_notification`)

1. Aller dans **Twilio Console → Content Template Builder**.
2. Cliquer sur **"Create new Content Template"**.
3. Configurer :
   - **Friendly name** : `sama_notification`
   - **Language** : `French (fr)`
   - **Category** : `UTILITY`
   - **Body** (copier-coller exactement) :
     ```
     Sama Services vous informe : {{1}}. Pour toute question, contactez-nous.
     ```
4. Cliquer sur **"Submit for WhatsApp Approval"**.
5. Une fois approuvé, copier le **Content SID** (`HXxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx`) → `TWILIO_WHATSAPP_CONTENT_SID`.

### Template 2 — Notifications admin (`sama_admin_notification`)

Mêmes étapes, avec :
- **Friendly name** : `sama_admin_notification`
- **Category** : `UTILITY`
- **Body** :
  ```
  Sama Services (Admin) : {{1}}. Merci de traiter cette demande.
  ```
- Content SID → `TWILIO_WHATSAPP_ADMIN_CONTENT_SID`.

> Si `TWILIO_WHATSAPP_ADMIN_CONTENT_SID` est laissé vide, les notifications admin
> utilisent automatiquement le template utilisateur (`sama_notification`).

### Template 3 — Vérification OTP (`sama_otp_verification`)

Utilisé par la Edge Function Supabase `send-sms-twilio` pour envoyer les codes
d'authentification. Ce template est **indépendant** du backend Java.

- **Friendly name** : `sama_otp_verification`
- **Language** : `French (fr)`
- **Category** : `AUTHENTICATION` ← obligatoire pour les codes OTP
- **Body** :
  ```
  Sama Services : {{1}} est votre code de vérification. Valable 10 minutes.
  ```
- Content SID → variable d'environnement Supabase `TWILIO_WHATSAPP_CONTENT_SID`
  (dans **Dashboard → Edge Functions → send-sms-twilio → Secrets**).

> La Edge Function injecte uniquement les **chiffres bruts** du code OTP dans `{{1}}`,
> pas la phrase complète. Le texte statique du template constitue le message final.

**Conseils pour éviter un rejet Meta :**
- La variable `{{1}}` doit toujours être entourée de texte des deux côtés
- Garder un ratio texte statique / variable élevé
- Ne pas inclure de liens, d'emojis ou de mise en forme Markdown
- Utiliser `AUTHENTICATION` pour les OTP, `UTILITY` pour les notifications

Délai d'approbation habituel : quelques minutes à 24 h.

---

## Étape 3 — Configurer les variables d'environnement

```env
TWILIO_ACCOUNT_SID=ACxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
TWILIO_AUTH_TOKEN=your-auth-token
TWILIO_WHATSAPP_FROM=whatsapp:+XXXXXXXXXXX           # votre numéro sender approuvé par Meta
TWILIO_WHATSAPP_CONTENT_SID=HXxxx...                 # SID du template sama_notification
TWILIO_WHATSAPP_ADMIN_CONTENT_SID=HXxxx...           # SID du template sama_admin_notification (optionnel)
ADMIN_WHATSAPP_NUMBER=+XXXXXXXXXXX                   # numéro admin en E.164 (sans préfixe whatsapp:)
```

---

## Étape 4 — Tester en sandbox d'abord

Avant d'utiliser votre numéro de production :

1. Dans **Twilio Console → Messaging → Try it out → WhatsApp**, noter le numéro sandbox
   (`+14155238886`) et le code d'activation.
2. Depuis votre téléphone, envoyer le message d'activation au numéro sandbox.
3. Configurer temporairement :
   ```env
   TWILIO_WHATSAPP_FROM=whatsapp:+14155238886
   TWILIO_WHATSAPP_CONTENT_SID=   # laisser vide pour le sandbox (free-form)
   ```
4. Tester les notifications via l'application.
5. Une fois validé, passer au sender de production et configurer les deux Content SIDs.

---

## Architecture dans le code

```
NotificationDispatcher.dispatch(event)
  ├─ dispatchUser(event)
  │    └─ sendWhatsAppWithSmsFallback(phone, message, type, isAdmin=false)
  │         └─ whatsAppProvider.sendWhatsApp(to, message)
  │              ├─ Si TWILIO_WHATSAPP_CONTENT_SID configuré :
  │              │    → ContentSid=HX…, ContentVariables={"1": "<message>"}
  │              │    Template: "Sama Services vous informe : {{1}}. Pour toute question, contactez-nous."
  │              └─ Sinon (sandbox) : Body=message (texte libre)
  │
  └─ dispatchAdmin(event)
       └─ sendWhatsAppWithSmsFallback(adminPhone, message, type, isAdmin=true)
            └─ whatsAppProvider.sendAdminWhatsApp(to, message)
                 ├─ Si TWILIO_WHATSAPP_ADMIN_CONTENT_SID configuré :
                 │    → ContentSid=HX…(admin), ContentVariables={"1": "<message>"}
                 │    Template: "Sama Services (Admin) : {{1}}. Merci de traiter cette demande."
                 ├─ Sinon si TWILIO_WHATSAPP_CONTENT_SID configuré :
                 │    → utilise le template utilisateur (fallback)
                 └─ Sinon (sandbox) : Body=message (texte libre)

En cas d'échec WhatsApp : TwilioSmsProvider.sendSms(to, message)
```

> Note : La Edge Function Supabase `send-sms-twilio` (OTP auth) utilise le template
> `sama_otp_verification` (catégorie `AUTHENTICATION`) — indépendant du backend Java.
> La variable `{{1}}` reçoit uniquement les chiffres bruts du code OTP.

---

## Codes d'erreur Twilio WhatsApp fréquents

| Code  | Description | Solution |
|-------|-------------|----------|
| 63001 | Channel injoignable / numéro non WhatsApp | Vérifier que le destinataire a WhatsApp |
| 63003 | Template non approuvé ou catégorie incorrecte | Vérifier le statut du template dans Twilio Console |
| 63007 | Fenêtre de 24h expirée sans template | Configurer `TWILIO_WHATSAPP_CONTENT_SID` |
| 63016 | Message trop long pour le template | Tronquer le texte de notification |
| 21211 | Numéro destinataire invalide | Vérifier le format E.164 |

---

## Liens utiles

- [Twilio WhatsApp Business API](https://www.twilio.com/docs/whatsapp/api)
- [Twilio Content Template Builder](https://www.twilio.com/docs/content-api/create-and-send-your-first-content-template-with-whatsapp)
- [Meta WhatsApp Business Platform](https://developers.facebook.com/docs/whatsapp/business-management-api)
- [Tarifs WhatsApp Twilio](https://www.twilio.com/en-us/whatsapp/pricing)
