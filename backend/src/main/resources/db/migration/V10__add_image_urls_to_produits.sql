-- Migration V10: Add image_urls column to produits for multi-image support
ALTER TABLE produits
    ADD COLUMN IF NOT EXISTS image_urls TEXT;
