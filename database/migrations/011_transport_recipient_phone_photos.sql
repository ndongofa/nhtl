-- Migration 011 : Ajout du téléphone du destinataire et des photos colis utilisateur
-- sur le service "sama gp" (transports)

ALTER TABLE transports
    ADD COLUMN IF NOT EXISTS telephone_destinataire VARCHAR(30),
    ADD COLUMN IF NOT EXISTS photos_colis_json      TEXT;
