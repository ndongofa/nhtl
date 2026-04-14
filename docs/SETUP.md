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

| Variable | Description |
|---|---|
| `SUPABASE_URL` | URL de votre projet Supabase |
| `SUPABASE_ANON_KEY` | Clé anonyme Supabase |
| `JWT_SECRET` | Secret JWT (même que dans Supabase) |
