# NHTL – Guide de configuration

## 1. Authentification par SMS via Brevo

L'application utilise Supabase pour l'authentification par numéro de téléphone.
Les OTP SMS sont envoyés via **Brevo** (ex-Sendinblue) à travers un Auth Hook Supabase.

### Étapes de configuration

#### 1.1 Créer un compte Brevo et obtenir une API Key

1. Connectez-vous sur [https://app.brevo.com](https://app.brevo.com)
2. Allez dans **Paramètres → Clés API**
3. Créez une nouvelle clé API avec les droits **Transactional SMS**
4. Notez votre clé API (`api-key`)

> **Prérequis Brevo** : Votre compte doit avoir accès aux SMS transactionnels.
> Les numéros de téléphone doivent être au format E.164 (ex: `+33652383258`).

#### 1.2 Déployer la fonction Edge `send-sms-brevo`

```bash
# Installez le CLI Supabase
npm install -g supabase

# Liez le projet (remplacez par votre project-ref)
supabase link --project-ref <votre-project-ref>

# Configurez les secrets (remplacez par vos valeurs)
supabase secrets set BREVO_API_KEY=votre_cle_api_brevo
supabase secrets set BREVO_SMS_SENDER=NHTL

# Optionnel : personnalisez le message (utilisez {otp} comme placeholder)
# supabase secrets set BREVO_SMS_TEMPLATE="Votre code NHTL : {otp}. Valable 10 min."

# Déployez la fonction
supabase functions deploy send-sms-brevo --no-verify-jwt
```

#### 1.3 Configurer l'Auth Hook dans Supabase Dashboard

1. Ouvrez [https://supabase.com/dashboard](https://supabase.com/dashboard) → votre projet
2. Allez dans **Authentication → Hooks**
3. Activez le hook **"Send SMS"**
4. Choisissez **"Supabase Edge Functions"**
5. Sélectionnez la fonction **`send-sms-brevo`**
6. Cliquez **Save**

#### 1.4 Désactiver Twilio dans Supabase

1. Dans **Authentication → Providers → Phone**
2. Désactivez ou supprimez les identifiants Twilio existants
3. Le SMS sera maintenant géré exclusivement par l'Auth Hook Brevo

#### 1.5 Vérification

Pour tester, essayez de créer un compte avec un numéro de téléphone valide.
Les logs de la fonction sont visibles dans :
- Supabase Dashboard → **Edge Functions → send-sms-brevo → Logs**
- Brevo Dashboard → **Transactional → SMS → Logs**

### Format des numéros de téléphone

Tous les numéros de téléphone doivent être en format **E.164** avec le `+` :
- ✅ `+33652383258` (France)
- ✅ `+221783042838` (Sénégal)
- ❌ `33652383258` (sans le `+`)

---

## 2. Configuration Backend Spring Boot

Copiez `.env.example` en `.env` et renseignez les variables :

```bash
cp backend/.env.example backend/.env
```

| Variable | Description | Obligatoire |
|---|---|---|
| `SPRING_PROFILES_ACTIVE` | Profil actif : `prod` en production, `dev` en local | Oui |
| `PORT` | Port d'écoute du serveur (défaut : 8080) | Non |
| `PGHOST` | Hôte PostgreSQL | Oui (prod) |
| `PGPORT` | Port PostgreSQL | Oui (prod) |
| `PGDATABASE` | Nom de la base de données | Oui (prod) |
| `PGUSER` | Utilisateur PostgreSQL | Oui (prod) |
| `PGPASSWORD` | Mot de passe PostgreSQL | Oui (prod) |
| `SUPABASE_URL` | URL de votre projet Supabase | Oui |
| `SUPABASE_ANON_KEY` | Clé anonyme Supabase | Oui |
| `SUPABASE_JWT_SECRET` | Secret JWT Supabase (Settings → API → JWT Secret) | Oui |
| `BREVO_API_KEY` | Clé API Brevo pour l'envoi d'emails transactionnels | Recommandé |
| `MAIL_FROM` | Adresse expéditeur des emails | Non |
| `MAIL_FROMNAME` | Nom affiché de l'expéditeur | Non |
| `SMTP_HOST` | Hôte SMTP (alternative à Brevo API) | Non |
| `SMTP_PORT` | Port SMTP (défaut : 587) | Non |
| `SMTP_USERNAME` | Identifiant SMTP | Non |
| `SMTP_PASSWORD` | Mot de passe SMTP | Non |
| `BREVO_SMS_FROM` | Nom expéditeur SMS Brevo (max 11 car.) | Non |
| `TWILIO_ACCOUNT_SID` | Account SID Twilio (WhatsApp) | Non |
| `TWILIO_AUTH_TOKEN` | Auth Token Twilio (WhatsApp) | Non |
| `TWILIO_FROM_NUMBER` | Numéro Twilio SMS (E.164) | Non |
| `TWILIO_WHATSAPP_FROM` | Expéditeur WhatsApp Twilio (ex : `whatsapp:+14155238886`) | Non |

---

## 3. Configuration WhatsApp via Twilio

Les notifications WhatsApp sont envoyées via **Twilio** uniquement en profil `prod`.
En profil `dev`, un stub log les messages sans les envoyer réellement.

### 3.1 Créer un compte Twilio

1. Inscrivez-vous sur [https://www.twilio.com](https://www.twilio.com)
2. Dans la **Console Twilio** (console.twilio.com), notez :
   - **Account SID** (commence par `AC…`)
   - **Auth Token**

### 3.2 Configurer le sandbox WhatsApp (développement/test)

Le sandbox Twilio WhatsApp permet de tester sans numéro approuvé :

1. Dans la Console Twilio, allez dans **Messaging → Try it out → Send a WhatsApp message**
2. Suivez les instructions pour rejoindre le sandbox depuis votre téléphone
   (envoyez le code d'activation au numéro sandbox, ex : `+1 415 523 8886`)
3. Utilisez `whatsapp:+14155238886` comme `TWILIO_WHATSAPP_FROM`

### 3.3 Passer en production (numéro WhatsApp Business approuvé)

1. Dans la Console Twilio → **Messaging → Senders → WhatsApp senders**
2. Soumettez votre numéro pour approbation Meta/WhatsApp (délai : quelques jours)
3. Une fois approuvé, remplacez `TWILIO_WHATSAPP_FROM` par `whatsapp:+VOTRE_NUMERO`

### 3.4 Configurer les variables d'environnement

```bash
# Sur Railway / votre hébergeur
TWILIO_ACCOUNT_SID=ACxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
TWILIO_AUTH_TOKEN=your-twilio-auth-token
TWILIO_FROM_NUMBER=+33700000000   # optionnel si SMS géré par Brevo
TWILIO_WHATSAPP_FROM=whatsapp:+14155238886
```

### 3.5 Canaux de notification — vue d'ensemble

| Canal | Profil `dev` | Profil `prod` | Fournisseur |
|---|---|---|---|
| In-app | ✅ | ✅ | BDD (Supabase/PostgreSQL) |
| Email | Stub (log) | ✅ | Brevo API ou SMTP |
| SMS | Stub (log) | ✅ | Brevo SMS |
| WhatsApp | Stub (log) | ✅ si Twilio configuré | Twilio |

> **Note** : Si `TWILIO_ACCOUNT_SID` est absent en prod, les notifications WhatsApp
> sont simplement ignorées (warn dans les logs) sans lever d'erreur.

### 3.6 Vérification

Pour confirmer que les notifications WhatsApp fonctionnent :

1. Déployez en profil `prod` avec les variables Twilio renseignées
2. Déclenchez un changement de statut sur une commande ou un transport
3. Vérifiez les logs Spring Boot : `[TWILIO-WA] Accepted sid=…`
4. Vérifiez dans la Console Twilio → **Monitor → Logs → Messaging**
