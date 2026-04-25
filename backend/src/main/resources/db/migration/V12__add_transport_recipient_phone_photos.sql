-- Migration V12 : Ajout du téléphone du destinataire et des photos colis
-- sur la table transports (service "sama gp")

ALTER TABLE transports
    ADD COLUMN IF NOT EXISTS telephone_destinataire VARCHAR(30),
    ADD COLUMN IF NOT EXISTS photos_colis_json      TEXT;
