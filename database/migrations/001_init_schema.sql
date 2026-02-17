-- ============================================
-- NHTL Project - Initial Schema
-- ============================================
-- Créé: 2026-02-17
-- Description: Tables de base pour l'authentification et les utilisateurs

-- Activer les extensions nécessaires
CREATE EXTENSION IF NOT EXISTS pgcrypto;
CREATE EXTENSION IF NOT EXISTS uuid-ossp;

-- Supprimer les anciennes tables (si elles existent)
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
  role VARCHAR(50) DEFAULT 'user' CHECK (role IN ('admin', 'user', 'guest')),
  auth_method VARCHAR(50) CHECK (auth_method IN ('email', 'phone')),
  is_verified BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  
  -- Contraintes
  CONSTRAINT email_or_phone CHECK (email IS NOT NULL OR phone_number IS NOT NULL),
  UNIQUE(email),
  UNIQUE(phone_number)
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
-- INDEX pour les performances
-- ============================================
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_phone ON users(phone_number);
CREATE INDEX idx_users_role ON users(role);
CREATE INDEX idx_permissions_user_id ON user_permissions(user_id);
CREATE INDEX idx_login_history_user_id ON user_login_history(user_id);

-- ============================================
-- Afficher les tables créées
-- ============================================
-- SELECT * FROM information_schema.tables WHERE table_schema = 'public';