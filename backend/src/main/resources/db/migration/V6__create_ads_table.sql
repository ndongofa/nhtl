-- Migration V6 : Table des publicités pour le carousel dynamique
-- Permet à l'admin d'ajouter/modifier/supprimer les publicités du carousel sur la page d'accueil

CREATE TABLE IF NOT EXISTS ads (
    id           BIGSERIAL PRIMARY KEY,
    emoji        VARCHAR(20)  NOT NULL DEFAULT '📢',
    title        VARCHAR(255) NOT NULL,
    subtitle     TEXT         NOT NULL DEFAULT '',
    color_hex    VARCHAR(20)  NOT NULL DEFAULT '#004EDA',
    color_end_hex VARCHAR(20) NOT NULL DEFAULT '#0D5BBF',
    position     INT          NOT NULL DEFAULT 0,
    is_active    BOOLEAN      NOT NULL DEFAULT TRUE,
    created_at   TIMESTAMP,
    updated_at   TIMESTAMP
);

-- Publicités initiales (les 3 annonces actuelles hardcodées)
INSERT INTO ads (emoji, title, subtitle, color_hex, color_end_hex, position, is_active, created_at, updated_at)
VALUES
    ('✈️', 'Prochain départ Paris → Dakar', 'Envoyez vos colis en 5 à 10 jours · Tarifs compétitifs', '#004EDA', '#0D5BBF', 0, TRUE, NOW(), NOW()),
    ('🛒', 'Commandez depuis Amazon, Temu & Shein', 'Livraison directe chez vous — Paris · Casablanca · Dakar', '#FBBF24', '#E65100', 1, TRUE, NOW(), NOW()),
    ('🌿', 'Sama Maad — Fraîcheur du Sénégal', 'Maad de qualité directement depuis le terroir sénégalais', '#16A34A', '#14532D', 2, TRUE, NOW(), NOW());
