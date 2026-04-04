-- Migration V7 : Ajout des champs media pour le support vidéo / image dans le carousel publicitaire

ALTER TABLE ads
    ADD COLUMN IF NOT EXISTS ad_type   VARCHAR(20) NOT NULL DEFAULT 'text',
    ADD COLUMN IF NOT EXISTS image_url TEXT,
    ADD COLUMN IF NOT EXISTS youtube_id VARCHAR(20);
