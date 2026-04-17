-- Migration V10 : Ajout du champ service_type pour cibler les publicités par service
-- NULL = publicité globale (visible sur la page d'accueil)
-- Valeur (ex: 'maad', 'teranga', 'bestseller') = publicité spécifique à un service

ALTER TABLE ads
    ADD COLUMN IF NOT EXISTS service_type VARCHAR(50) DEFAULT NULL;

-- Index pour optimiser les requêtes filtrées par service
CREATE INDEX IF NOT EXISTS idx_ads_service_type ON ads (service_type);
