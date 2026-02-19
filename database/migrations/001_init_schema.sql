-- ============================================
-- NHTL Project - Initial Schema
-- ============================================
-- Créé: 2026-02-17
-- Description: Schema complet avec auth + commandes + transports

-- Activer les extensions nécessaires
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- Supprimer les anciennes tables (si elles existent)
DROP TABLE IF EXISTS transports CASCADE;
DROP TABLE IF EXISTS commandes CASCADE;
DROP TABLE IF EXISTS user_login_history CASCADE;
DROP TABLE IF EXISTS user_permissions CASCADE;
DROP TABLE IF EXISTS users CASCADE;

-- ============================================
-- TABLE: users
-- ============================================
CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email VARCHAR(255),
  phone_number VARCHAR(20),
  username VARCHAR(255),
  password_hash VARCHAR(255) NOT NULL,
  full_name VARCHAR(255),
  role VARCHAR(50) DEFAULT 'user' CHECK (role IN ('admin', 'user', 'guest')),
  auth_method VARCHAR(50) CHECK (auth_method IN ('email', 'phone')),
  is_verified BOOLEAN DEFAULT FALSE,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  
  -- Contraintes
  CONSTRAINT email_or_phone CHECK (email IS NOT NULL OR phone_number IS NOT NULL),
  UNIQUE(email),
  UNIQUE(phone_number),
  UNIQUE(username)
);

-- ============================================
-- TABLE: user_permissions
-- ============================================
CREATE TABLE user_permissions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  permission VARCHAR(255) NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(user_id, permission)
);

-- ============================================
-- TABLE: user_login_history
-- ============================================
CREATE TABLE user_login_history (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  login_method VARCHAR(50),
  login_ip VARCHAR(50),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================
-- TABLE: commandes
-- ============================================
CREATE TABLE commandes (
  id SERIAL PRIMARY KEY,
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  nom VARCHAR(255) NOT NULL,
  prenom VARCHAR(255) NOT NULL,
  numero_telephone VARCHAR(20) NOT NULL,
  email VARCHAR(255),
  date_commande TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  statut VARCHAR(50) DEFAULT 'pending' CHECK (statut IN ('pending', 'confirmed', 'completed', 'cancelled')),
  montant DECIMAL(10, 2),
  notes TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================
-- TABLE: transports
-- ============================================
CREATE TABLE transports (
  id SERIAL PRIMARY KEY,
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  commande_id INTEGER REFERENCES commandes(id) ON DELETE CASCADE,
  type_transport VARCHAR(100) NOT NULL,
  point_depart VARCHAR(255) NOT NULL,
  point_arrivee VARCHAR(255) NOT NULL,
  date_depart TIMESTAMP NOT NULL,
  date_arrivee TIMESTAMP,
  prix DECIMAL(10, 2),
  statut VARCHAR(50) DEFAULT 'pending' CHECK (statut IN ('pending', 'confirmed', 'in_progress', 'completed', 'cancelled')),
  notes TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================
-- INDEX pour les performances
-- ============================================
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_phone ON users(phone_number);
CREATE INDEX idx_users_username ON users(username);
CREATE INDEX idx_users_role ON users(role);
CREATE INDEX idx_permissions_user_id ON user_permissions(user_id);
CREATE INDEX idx_login_history_user_id ON user_login_history(user_id);
CREATE INDEX idx_commandes_user_id ON commandes(user_id);
CREATE INDEX idx_commandes_statut ON commandes(statut);
CREATE INDEX idx_transports_user_id ON transports(user_id);
CREATE INDEX idx_transports_commande_id ON transports(commande_id);
CREATE INDEX idx_transports_statut ON transports(statut);

-- ============================================
-- Afficher les tables créées
-- ============================================
-- SELECT * FROM information_schema.tables WHERE table_schema = 'public';