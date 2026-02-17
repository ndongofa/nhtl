# Database Setup - NHTL Project

## Structure

```
migrations/    - Scripts de création de tables et structures
seeds/         - Données d'exemple pour tester
```

## Installation

### 1. Exécuter les migrations en ordre:

```
1. 001_init_schema.sql      → Crée les tables
2. 002_auth_functions.sql   → Ajoute les fonctions
3. 003_rls_policies.sql     → Active les politiques RLS
```

### 2. (Optionnel) Charger les données de test:

```
seeds/sample_data.sql
```

## Données de test

| Identifiant | Mot de passe | Rôle |
|-------------|-------------|------|
| admin@ngom-holding.com | admin123 | admin |
| +221770000001 | user123 | user |
| guest@ngom-holding.com | guest123 | guest |

## Supabase SQL Editor

Dans Supabase Dashboard:
1. Allez dans **SQL Editor**
2. Copiez-collez chaque script dans l'ordre
3. Cliquez sur **Run**

## Notes

- Les mots de passe sont hashés avec bcrypt (pgcrypto)
- RLS est activé pour la sécurité
- Les utilisateurs ne voient que leurs données
- Les admins voient tout