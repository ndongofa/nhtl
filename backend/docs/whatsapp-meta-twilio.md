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

## Étape 2 — Créer un Content Template dans Twilio

Les notifications de l'application utilisent un **template générique à une variable** (`{{1}}`),
qui sera remplacée par le texte de la notification au moment de l'envoi.

1. Aller dans **Twilio Console → Content Template Builder** (ou rechercher "Content").
2. Cliquer sur **"Create new Content Template"**.
3. Configurer le template :
   - **Friendly name** : `nhtl_notification` (ou similaire)
   - **Language** : `French (fr)` *(ou la langue principale de vos utilisateurs)*
   - **Category** : `UTILITY` (pour les notifications transactionnelles)
   - **Body** : `{{1}}`
   
   > Le body `{{1}}` permet d'envoyer n'importe quel texte de notification sans créer un
   > template séparé pour chaque type d'événement.

4. Cliquer sur **"Submit for WhatsApp Approval"**.
5. Attendre l'approbation de Meta (généralement 24–48 h).
6. Une fois approuvé, copier le **Content SID** du template (format `HXxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx`).

---

## Étape 3 — Configurer les variables d'environnement

Dans votre environnement de production (Railway, Docker, serveur), configurer les variables :

```env
TWILIO_ACCOUNT_SID=ACxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
TWILIO_AUTH_TOKEN=your-auth-token
TWILIO_WHATSAPP_FROM=whatsapp:+XXXXXXXXXXX      # votre numéro sender approuvé par Meta
TWILIO_WHATSAPP_CONTENT_SID=HXxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx  # SID du template approuvé
ADMIN_WHATSAPP_NUMBER=+XXXXXXXXXXX              # numéro admin en E.164 (sans préfixe whatsapp:)
```

> `TWILIO_WHATSAPP_CONTENT_SID` est la clé ajoutée pour activer le mode template.
> Sans elle, l'application envoie du texte libre (sandbox uniquement).

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
5. Une fois validé, passer au sender de production et configurer `TWILIO_WHATSAPP_CONTENT_SID`.

---

## Architecture dans le code

```
NotificationDispatcher
  └─ sendWhatsAppWithSmsFallback(to, message)
       ├─ TwilioWhatsAppProvider.sendWhatsApp(to, message)
       │    ├─ Si TWILIO_WHATSAPP_CONTENT_SID configuré :
       │    │    → Message.creator(to, from, "")
       │    │         .setContentSid(HX…)
       │    │         .setContentVariables({"1": "<message>"})
       │    │         .create()
       │    └─ Sinon (sandbox) :
       │         → Message.creator(to, from, message).create()
       └─ En cas d'échec : TwilioSmsProvider.sendSms(to, message)
```

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
