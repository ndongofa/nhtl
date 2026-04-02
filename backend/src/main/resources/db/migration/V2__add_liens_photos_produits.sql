-- Migration V2 : Ajout des colonnes liens_produits et photos_produits
-- À exécuter manuellement sur la base de données de production
-- avant de déployer le backend avec cette version.

ALTER TABLE commandes
    ADD COLUMN IF NOT EXISTS liens_produits TEXT,
    ADD COLUMN IF NOT EXISTS photos_produits TEXT;
