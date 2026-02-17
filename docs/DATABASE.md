# Documentation Base de Données

## Vue d'ensemble

La base de données utilise **PostgreSQL via Supabase** avec:
- ✅ Authentification (email/téléphone)
- ✅ Rôles (admin/user/guest)
- ✅ Row-Level Security (RLS)
- ✅ Hashing bcrypt pour les mots de passe

## Scripts à exécuter

### 1️⃣ Schéma de base
```sql
-- Exécutez: database/migrations/001_init_schema.sql
```

### 2️⃣ Fonctions d'authentification
```sql
-- Exécutez: database/migrations/002_auth_functions.sql
```

### 3️⃣ Politiques RLS
```sql
-- Exécutez: database/migrations/003_rls_policies.sql
```

### 4️⃣ Données de test (Optionnel)
```sql
-- Exécutez: database/seeds/sample_data.sql
```