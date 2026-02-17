# 📚 Documentation Base de Données NHTL

## 📋 Table des matières

1. [Vue d'ensemble](#vue-densemble)
2. [Architecture](#-architecture)
3. [Tables](#-tables)
4. [Sécurité](#-sécurité)
5. [Authentification](#-authentification)
6. [Utilisateurs de test](#-utilisateurs-de-test)
7. [Installation](#-installation)
8. [Tests](#-tests)
9. [Dépannage](#-dépannage)

---

## Vue d'ensemble

La base de données NHTL utilise **PostgreSQL via Supabase** avec:

- ✅ Authentification par email/téléphone
- ✅ Rôles (admin/user/guest)
- ✅ Row-Level Security (RLS)
- ✅ Hashing bcrypt pour les mots de passe
- ��� Historique des connexions
- ✅ Système de permissions
- ✅ Gestion des commandes et transports

---

## 🏗️ Architecture

### Vue globale

```
┌─────────────────────────────────────────┐
│         NHTL Database Schema            │
├─────────────────────────────────────────┤
│                                         │
│  ┌──────────────────────────────────┐   │
│  │    users (Authentification)      │   │
│  ├──────────────────────────────────┤   │
│  │ • Email/Téléphone                │   │
│  │ • Rôles (admin/user/guest)       │   │
│  │ • Mot de passe hashé (bcrypt)    │   │
│  │ • Permissions                    │   │
│  └──────────────────────────────────┘   │
│           ↓                              │
│  ┌──────────────────────────────────┐   │
│  │    commandes (Gestion)           │   │
│  ├──────────────────────────────────┤   │
│  │ • Détails client                 │   │
│  │ • Montant et statut              │   │
│  │ • Historique                     │   │
│  └──────────────────────────────────┘   │
│           ↓                              │
│  ┌──────────────────────────────────┐   │
│  │    transports (Logistique)       │   │
│  ├──────────────────────────────────┤   │
│  │ • Détails trajets                │   │
│  │ • Prix et statut                 │   │
│  │ • Dates                          │   │
│  └──────────────────────────────────┘   │
│                                         │
└─────────────────────────────────────────┘
```

---

## 📊 Tables

### 1️⃣ `users` - Utilisateurs et Authentification

**Description:** Stocke les informations des utilisateurs du système NHTL.

**Structure:**

| Colonne | Type | Description |
|---------|------|-------------|
| `id` | UUID | Identifiant unique (auto-généré) |
| `email` | VARCHAR(255) | Email (UNIQUE, optionnel) |
| `phone_number` | VARCHAR(20) | Téléphone (UNIQUE, optionnel) |
| `username` | VARCHAR(255) | Nom d'utilisateur (UNIQUE) |
| `password_hash` | VARCHAR(255) | Mot de passe hashé (bcrypt) |
| `full_name` | VARCHAR(255) | Nom complet |
| `role` | VARCHAR(50) | Rôle: admin / user / guest |
| `auth_method` | VARCHAR(50) | Méthode: email / phone |
| `is_verified` | BOOLEAN | Utilisateur vérifié? |
| `is_active` | BOOLEAN | Compte actif? |
| `created_at` | TIMESTAMP | Date de création |
| `updated_at` | TIMESTAMP | Date de mise à jour |

**Contraintes:**
- Au moins email OU téléphone requis
- Email UNIQUE (si fourni)
- Téléphone UNIQUE (si fourni)
- Username UNIQUE

**Indices:**
- `idx_users_email` - Recherche rapide par email
- `idx_users_phone` - Recherche rapide par téléphone
- `idx_users_username` - Recherche rapide par username
- `idx_users_role` - Filtrage par rôle

---

### 2️⃣ `user_permissions` - Permissions des Utilisateurs

**Description:** Stocke les permissions granulaires de chaque utilisateur.

**Structure:**

| Colonne | Type | Description |
|---------|------|-------------|
| `id` | UUID | Identifiant unique |
| `user_id` | UUID | Référence à `users.id` |
| `permission` | VARCHAR(255) | Code de permission |
| `created_at` | TIMESTAMP | Date d'ajout |

**Permissions disponibles:**
- `admin.manage_users` - Gérer les utilisateurs
- `admin.manage_commandes` - Gérer les commandes
- `admin.manage_transports` - Gérer les transports
- `user.read_profile` - Lire son profil
- `user.create_commandes` - Créer des commandes
- `user.view_commandes` - Voir ses commandes
- `user.create_transports` - Créer des transports
- `guest.limited_access` - Accès limité

**Contraintes:**
- `UNIQUE(user_id, permission)` - Une permission par user

---

### 3️⃣ `user_login_history` - Historique des Connexions

**Description:** Enregistre chaque tentative de connexion.

**Structure:**

| Colonne | Type | Description |
|---------|------|-------------|
| `id` | UUID | Identifiant unique |
| `user_id` | UUID | Référence à `users.id` |
| `login_method` | VARCHAR(50) | Méthode: email / phone |
| `login_ip` | VARCHAR(50) | Adresse IP (optionnel) |
| `created_at` | TIMESTAMP | Timestamp de la connexion |

**Indices:**
- `idx_login_history_user_id` - Historique rapide par utilisateur

---

### 4️⃣ `commandes` - Commandes

**Description:** Stocke les commandes des clients.

**Structure:**

| Colonne | Type | Description |
|---------|------|-------------|
| `id` | SERIAL | Identifiant unique |
| `user_id` | UUID | Référence à `users.id` |
| `nom` | VARCHAR(255) | Nom du client |
| `prenom` | VARCHAR(255) | Prénom du client |
| `numero_telephone` | VARCHAR(20) | Téléphone du client |
| `email` | VARCHAR(255) | Email du client |
| `date_commande` | TIMESTAMP | Date de la commande |
| `statut` | VARCHAR(50) | pending / confirmed / completed / cancelled |
| `montant` | DECIMAL(10,2) | Montant en devises |
| `notes` | TEXT | Notes additionnelles |
| `created_at` | TIMESTAMP | Date de création |
| `updated_at` | TIMESTAMP | Date de mise à jour |

**Statuts disponibles:**
- `pending` - En attente
- `confirmed` - Confirmée
- `completed` - Complétée
- `cancelled` - Annulée

**Indices:**
- `idx_commandes_user_id` - Commandes par utilisateur
- `idx_commandes_statut` - Filtrage par statut

---

### 5️⃣ `transports` - Transports/Trajets

**Description:** Détails des transports associés aux commandes.

**Structure:**

| Colonne | Type | Description |
|---------|------|-------------|
| `id` | SERIAL | Identifiant unique |
| `user_id` | UUID | Référence à `users.id` |
| `commande_id` | INTEGER | Référence à `commandes.id` |
| `type_transport` | VARCHAR(100) | Type: Voiture / Bus / Taxi / etc. |
| `point_depart` | VARCHAR(255) | Lieu de départ |
| `point_arrivee` | VARCHAR(255) | Lieu d'arrivée |
| `date_depart` | TIMESTAMP | Date/heure de départ |
| `date_arrivee` | TIMESTAMP | Date/heure d'arrivée (optionnel) |
| `prix` | DECIMAL(10,2) | Prix du transport |
| `statut` | VARCHAR(50) | pending / confirmed / in_progress / completed / cancelled |
| `notes` | TEXT | Notes additionnelles |
| `created_at` | TIMESTAMP | Date de création |
| `updated_at` | TIMESTAMP | Date de mise à jour |

**Statuts disponibles:**
- `pending` - En attente
- `confirmed` - Confirmé
- `in_progress` - En cours
- `completed` - Complété
- `cancelled` - Annulé

**Indices:**
- `idx_transports_user_id` - Transports par utilisateur
- `idx_transports_commande_id` - Transports par commande
- `idx_transports_statut` - Filtrage par statut

---

## 🔐 Sécurité

### Row-Level Security (RLS)

RLS est activé sur **TOUTES** les tables critiques:
- ✅ `users`
- ✅ `user_permissions`
- ✅ `user_login_history`
- ✅ `commandes`
- ✅ `transports`

### Politiques de sécurité

#### Users

| Politique | Rôle | Action | Condition |
|-----------|------|--------|-----------|
| View own profile | user | SELECT | `auth.uid() = id` |
| View all users | admin | SELECT | role = 'admin' |
| Update own profile | user | UPDATE | `auth.uid() = id` |
| Update all users | admin | UPDATE | role = 'admin' |

#### Commandes

| Politique | Rôle | Action | Condition |
|-----------|------|--------|-----------|
| View own | user | SELECT | `user_id = auth.uid()` |
| View all | admin | SELECT | role = 'admin' |
| Create own | user | INSERT | `user_id = auth.uid()` |
| Update own | user | UPDATE | `user_id = auth.uid()` |
| Update all | admin | UPDATE | role = 'admin' |

#### Transports

| Politique | Rôle | Action | Condition |
|-----------|------|--------|-----------|
| View own | user | SELECT | `user_id = auth.uid()` |
| View all | admin | SELECT | role = 'admin' |
| Create own | user | INSERT | `user_id = auth.uid()` |
| Update own | user | UPDATE | `user_id = auth.uid()` |
| Update all | admin | UPDATE | role = 'admin' |

---

## 🔑 Authentification

### Fonctions d'authentification

#### 1️⃣ `register_user(identifier, password, auth_method, role)`

Crée un nouvel utilisateur.

**Paramètres:**
- `identifier` (VARCHAR) - Email ou téléphone
- `password` (VARCHAR) - Mot de passe en clair (sera hashé)
- `auth_method` (VARCHAR) - 'email' ou 'phone'
- `role` (VARCHAR, optionnel) - 'user' par défaut

**Exemple:**
```sql
SELECT register_user(
  'newuser@ngom-holding.com',
  'password123',
  'email',
  'user'
);
```

**Réponse:**
```json
{
  "success": true,
  "user_id": "550e8400-e29b-41d4-a716-446655440000",
  "message": "Utilisateur créé avec succès"
}
```

**Erreurs possibles:**
- `"Cet identifiant est déjà utilisé"` - Email/téléphone existe
- Message d'erreur de la base de données

---

#### 2️⃣ `login_user(identifier, password)`

Authentifie un utilisateur existant.

**Paramètres:**
- `identifier` (VARCHAR) - Email ou téléphone
- `password` (VARCHAR) - Mot de passe en clair

**Exemple:**
```sql
SELECT login_user('admin@ngom-holding.com', 'admin123');
```

**Réponse réussie:**
```json
{
  "success": true,
  "user_id": "550e8400-e29b-41d4-a716-446655440000",
  "role": "admin",
  "email": "admin@ngom-holding.com",
  "phone": null,
  "auth_method": "email"
}
```

**Erreurs possibles:**
- `"Identifiant ou mot de passe incorrect"` - Email/mot de passe invalide
- Message d'erreur de la base de données

---

### Hashing des mots de passe

Les mots de passe sont hashés avec **bcrypt** (via pgcrypto):

```sql
-- Hashing
crypt('password', gen_salt('bf'))

-- Vérification
password_hash = crypt('password', password_hash)
```

---

## 👥 Utilisateurs de test

Après l'insertion des données de test, vous pouvez utiliser:

| Email | Téléphone | Mot de passe | Rôle | Username |
|-------|-----------|-------------|------|----------|
| admin@ngom-holding.com | - | admin123 | admin | admin |
| - | +221770000001 | user123 | user | user1 |
| guest@ngom-holding.com | - | guest123 | guest | guest |

---

## 🚀 Installation

### Prérequis

- ✅ Compte Supabase
- ✅ Accès au SQL Editor de Supabase
- ✅ Ce repository cloné en local

### Étape 1: Exécuter les migrations

Dans **Supabase SQL Editor**, exécutez dans cet ordre:

#### Migration 1: Schema
```
database/migrations/001_init_schema.sql
```

Crée:
- 5 tables (`users`, `user_permissions`, `user_login_history`, `commandes`, `transports`)
- 11 indices pour les performances
- Contraintes et validations

#### Migration 2: Fonctions
```
database/migrations/002_auth_functions.sql
```

Crée:
- Fonction `register_user()` - Inscription
- Fonction `login_user()` - Connexion
- Triggers pour `updated_at`

#### Migration 3: Politiques RLS
```
database/migrations/003_rls_policies.sql
```

Active et configure:
- RLS sur les 5 tables
- 20+ politiques de sécurité
- Contrôle d'accès par rôle

#### Seed: Données de test
```
database/seeds/sample_data.sql
```

Insère:
- 3 utilisateurs de test (admin, user, guest)
- Permissions associées
- 1 commande de test
- 1 transport de test

### Étape 2: Vérifier dans Supabase

1. Allez à **"Table Editor"**
2. Vérifiez que les 5 tables existent
3. Vérifiez que les données de test sont présentes

```sql
-- Vérification rapide
SELECT COUNT(*) FROM users;        -- doit retourner 3
SELECT COUNT(*) FROM commandes;    -- doit retourner 1
SELECT COUNT(*) FROM transports;   -- doit retourner 1
```

---

## 🧪 Tests

### Test 1: Inscription d'un nouvel utilisateur

```sql
SELECT register_user(
  'test@ngom-holding.com',
  'testpass123',
  'email',
  'user'
);
```

**Résultat attendu:**
```json
{
  "success": true,
  "user_id": "[UUID généré]",
  "message": "Utilisateur créé avec succès"
}
```

---

### Test 2: Connexion admin

```sql
SELECT login_user('admin@ngom-holding.com', 'admin123');
```

**Résultat attendu:**
```json
{
  "success": true,
  "user_id": "[UUID]",
  "role": "admin",
  "email": "admin@ngom-holding.com",
  "phone": null,
  "auth_method": "email"
}
```

---

### Test 3: Connexion utilisateur (par téléphone)

```sql
SELECT login_user('+221770000001', 'user123');
```

**Résultat attendu:**
```json
{
  "success": true,
  "user_id": "[UUID]",
  "role": "user",
  "email": null,
  "phone": "+221770000001",
  "auth_method": "phone"
}
```

---

### Test 4: Voir les commandes

```sql
SELECT * FROM commandes;
```

**Résultat attendu:**
```
id | user_id | nom  | prenom | statut  | montant
---|---------|------|--------|---------|----------
 1 | [UUID]  | Ngom | Jean   | pending | 150000.00
```

---

### Test 5: Voir les transports

```sql
SELECT * FROM transports;
```

**Résultat attendu:**
```
id | user_id | commande_id | type_transport | point_depart | point_arrivee | prix     | statut
---|---------|-------------|----------------|--------------|---------------|----------|--------
 1 | [UUID]  | 1           | Voiture        | Dakar        | Thiès         | 25000.00 | pending
```

---

## 🐛 Dépannage

### Erreur: "syntax error at or near uuid-ossp"

**Cause:** Supabase ne supporte pas l'extension `uuid-ossp`.

**Solution:** Utilisez `gen_random_uuid()` à la place.

```sql
-- ❌ INCORRECT
CREATE EXTENSION IF NOT EXISTS uuid-ossp;

-- ✅ CORRECT
DEFAULT gen_random_uuid()
```

---

### Erreur: Les requêtes RLS retournent 0 lignes

**Cause:** L'utilisateur n'est pas authentifié ou n'a pas les permissions.

**Solution:** 
1. Vérifiez que `auth.uid()` est défini
2. Vérifiez les politiques RLS
3. Vérifiez le rôle de l'utilisateur

```sql
-- Vérifier RLS sur une table
SELECT * FROM information_schema.table_privileges 
WHERE table_name = 'users';

-- Voir les politiques
SELECT * FROM pg_policies 
WHERE tablename = 'users';
```

---

### Erreur: "duplicate key value violates unique constraint"

**Cause:** Email, téléphone ou username existe déjà.

**Solution:** Utilisez une valeur unique ou supprimez l'enregistrement existant.

```sql
-- Voir les utilisateurs existants
SELECT email, phone_number, username FROM users;

-- Supprimer un utilisateur (avec prudence!)
DELETE FROM users WHERE email = 'duplicate@example.com';
```

---

### Les timestamps `updated_at` ne se mettent pas à jour

**Cause:** Les triggers ne sont pas créés.

**Solution:** Vérifiez que `002_auth_functions.sql` a été exécuté.

```sql
-- Vérifier les triggers
SELECT * FROM information_schema.triggers 
WHERE event_object_table IN ('users', 'commandes', 'transports');
```

---

## 📚 Ressources

- [Documentation Supabase](https://supabase.com/docs)
- [PostgreSQL RLS](https://www.postgresql.org/docs/current/ddl-rowsecurity.html)
- [PostgreSQL Crypto (bcrypt)](https://www.postgresql.org/docs/current/pgcrypto.html)
- [PostgreSQL Triggers](https://www.postgresql.org/docs/current/sql-createtrigger.html)

---

## 📝 Notes importantes

1. **Authentification multicanal:**
   - Email OU téléphone requis
   - Permet l'authentification par les deux

2. **Hashing sécurisé:**
   - Utilise bcrypt (standard de l'industrie)
   - Salts automatiques générés

3. **RLS complète:**
   - Chaque utilisateur ne voit que ses données
   - Les admins voient tout
   - Impossible de contourner au niveau base de données

4. **Audit trail:**
   - `user_login_history` trace chaque connexion
   - `created_at` et `updated_at` automatiques

5. **Scalabilité:**
   - Indices optimisés
   - Contraintes au niveau BD
   - Prêt pour la production

---

## ✅ Checklist de déploiement

- [x] Toutes les migrations exécutées
- [x] RLS activé et configuré
- [x] Données de test insérées
- [x] Tests d'authentification réussis
- [x] Documentation complète
- [x] Sécurité validée
- [x] Performance optimisée

---

**Dernière mise à jour:** 2026-02-17

**Maintenu par:** NHTL Team

**Support:** Pour toute question, consultez la documentation Supabase ou ouvrez une issue.