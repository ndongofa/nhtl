-- Migration V5 : Ajout des colonnes manquantes dans la table commandes
-- Ces colonnes ont été ajoutées à V1 après la création de la base de production.
-- Flyway avec baseline-version=4 ne rejoue pas V1, donc elles sont absentes en prod.

ALTER TABLE commandes
    ADD COLUMN IF NOT EXISTS articles_json          TEXT,
    ADD COLUMN IF NOT EXISTS statut_suivi_commande  VARCHAR(255) NOT NULL DEFAULT 'EN_ATTENTE',
    ADD COLUMN IF NOT EXISTS photo_colis_url        VARCHAR(255),
    ADD COLUMN IF NOT EXISTS photo_bordereau_url    VARCHAR(255),
    ADD COLUMN IF NOT EXISTS numero_bordereau       VARCHAR(100),
    ADD COLUMN IF NOT EXISTS depose_poste_at        TIMESTAMP;
