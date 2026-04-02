-- Migration V4 : Ajout des colonnes manquantes dans la table achats
-- Colonnes absentes de V3 mais présentes dans l'entité Achat.java

ALTER TABLE achats
    ADD COLUMN IF NOT EXISTS liens_produits  TEXT,
    ADD COLUMN IF NOT EXISTS photos_produits TEXT,
    ADD COLUMN IF NOT EXISTS articles_json   TEXT;
