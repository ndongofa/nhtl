-- ============================================
-- NHTL Project - Migration 004: Sama Achat
-- ============================================
-- Créé: 2026-04-02
-- Description: Table des achats sur mesure (Sama Achat)

-- ============================================
-- TABLE: achats
-- ============================================
CREATE TABLE IF NOT EXISTS achats (
  id                    BIGSERIAL PRIMARY KEY,
  user_id               UUID REFERENCES users(id) ON DELETE CASCADE,
  nom                   VARCHAR(255),
  prenom                VARCHAR(255),
  numero_telephone      VARCHAR(50),
  email                 VARCHAR(255),
  pays_livraison        VARCHAR(100),
  ville_livraison       VARCHAR(100),
  adresse_livraison     VARCHAR(500),
  marche                VARCHAR(255),
  type_produit          VARCHAR(255),
  description_achat     TEXT,
  quantite              INTEGER DEFAULT 1,
  prix_estime           DECIMAL(12, 2),
  prix_total            DECIMAL(12, 2),
  devise                VARCHAR(10) DEFAULT 'EUR',
  notes_speciales       TEXT,
  statut                VARCHAR(50)  DEFAULT 'EN_ATTENTE',
  statut_suivi_achat    VARCHAR(50)  DEFAULT 'EN_ATTENTE',
  archived              BOOLEAN      DEFAULT FALSE,
  gp_id                 BIGINT,
  gp_prenom             VARCHAR(255),
  gp_nom                VARCHAR(255),
  gp_phone_number       VARCHAR(50),
  photo_colis_url       TEXT,
  photo_bordereau_url   TEXT,
  numero_bordereau      VARCHAR(100),
  depose_poste_at       TIMESTAMP,
  date_creation         TIMESTAMP    DEFAULT CURRENT_TIMESTAMP,
  date_modification     TIMESTAMP    DEFAULT CURRENT_TIMESTAMP
);

-- ============================================
-- INDEX pour les performances
-- ============================================
CREATE INDEX IF NOT EXISTS idx_achats_user_id      ON achats(user_id);
CREATE INDEX IF NOT EXISTS idx_achats_statut       ON achats(statut);
CREATE INDEX IF NOT EXISTS idx_achats_statut_suivi ON achats(statut_suivi_achat);
CREATE INDEX IF NOT EXISTS idx_achats_archived     ON achats(archived);
