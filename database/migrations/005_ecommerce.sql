-- ============================================
-- NHTL Project - Migration 005: E-commerce
-- ============================================
-- Créé: 2026-04-02
-- Description: Tables e-commerce partagées (Sama Maad, Téranga Apéro, Best Seller)

-- ============================================
-- TABLE: produits
-- ============================================
CREATE TABLE IF NOT EXISTS produits (
  id               BIGSERIAL PRIMARY KEY,
  service_type     VARCHAR(20) NOT NULL CHECK (service_type IN ('MAAD', 'TERANGA', 'BESTSELLER')),
  nom              VARCHAR(255) NOT NULL,
  description      TEXT,
  prix             DECIMAL(12, 2) NOT NULL,
  devise           VARCHAR(10)  DEFAULT 'EUR',
  categorie        VARCHAR(100),
  image_url        TEXT,
  stock            INTEGER      DEFAULT 0,
  unite            VARCHAR(50),
  actif            BOOLEAN      DEFAULT TRUE,
  date_ajout       TIMESTAMP    DEFAULT CURRENT_TIMESTAMP,
  date_modification TIMESTAMP   DEFAULT CURRENT_TIMESTAMP
);

-- ============================================
-- TABLE: panier_items
-- ============================================
CREATE TABLE IF NOT EXISTS panier_items (
  id              BIGSERIAL PRIMARY KEY,
  user_id         UUID NOT NULL,
  produit_id      BIGINT NOT NULL REFERENCES produits(id) ON DELETE CASCADE,
  service_type    VARCHAR(20) NOT NULL,
  quantite        INTEGER     NOT NULL DEFAULT 1,
  prix_unitaire   DECIMAL(12, 2) NOT NULL,
  devise          VARCHAR(10)  DEFAULT 'EUR',
  date_ajout      TIMESTAMP    DEFAULT CURRENT_TIMESTAMP,
  UNIQUE (user_id, produit_id)
);

-- ============================================
-- TABLE: commandes_ecommerce
-- ============================================
CREATE TABLE IF NOT EXISTS commandes_ecommerce (
  id                  BIGSERIAL PRIMARY KEY,
  user_id             UUID NOT NULL,
  nom                 VARCHAR(255),
  prenom              VARCHAR(255),
  numero_telephone    VARCHAR(50),
  email               VARCHAR(255),
  pays_livraison      VARCHAR(100),
  ville_livraison     VARCHAR(100),
  adresse_livraison   VARCHAR(500),
  service_type        VARCHAR(20) NOT NULL CHECK (service_type IN ('MAAD', 'TERANGA', 'BESTSELLER')),
  prix_total          DECIMAL(12, 2) NOT NULL DEFAULT 0,
  devise              VARCHAR(10)   DEFAULT 'EUR',
  statut              VARCHAR(30)   DEFAULT 'EN_ATTENTE',
  archived            BOOLEAN       DEFAULT FALSE,
  notes_speciales     TEXT,
  date_commande       TIMESTAMP     DEFAULT CURRENT_TIMESTAMP,
  date_modification   TIMESTAMP     DEFAULT CURRENT_TIMESTAMP
);

-- ============================================
-- TABLE: commande_ecommerce_items
-- ============================================
CREATE TABLE IF NOT EXISTS commande_ecommerce_items (
  id                     BIGSERIAL PRIMARY KEY,
  commande_ecommerce_id  BIGINT NOT NULL REFERENCES commandes_ecommerce(id) ON DELETE CASCADE,
  produit_id             BIGINT NOT NULL,
  produit_nom            VARCHAR(255),
  quantite               INTEGER NOT NULL,
  prix_unitaire          DECIMAL(12, 2) NOT NULL,
  sous_total             DECIMAL(12, 2) NOT NULL,
  devise                 VARCHAR(10)  DEFAULT 'EUR'
);

-- ============================================
-- INDEX pour les performances
-- ============================================
CREATE INDEX IF NOT EXISTS idx_produits_service_type ON produits(service_type);
CREATE INDEX IF NOT EXISTS idx_produits_actif        ON produits(actif);
CREATE INDEX IF NOT EXISTS idx_panier_user_id        ON panier_items(user_id);
CREATE INDEX IF NOT EXISTS idx_panier_service        ON panier_items(service_type);
CREATE INDEX IF NOT EXISTS idx_cmd_eco_user_id       ON commandes_ecommerce(user_id);
CREATE INDEX IF NOT EXISTS idx_cmd_eco_service       ON commandes_ecommerce(service_type);
CREATE INDEX IF NOT EXISTS idx_cmd_eco_statut        ON commandes_ecommerce(statut);
CREATE INDEX IF NOT EXISTS idx_cmd_eco_items_cmd     ON commande_ecommerce_items(commande_ecommerce_id);
