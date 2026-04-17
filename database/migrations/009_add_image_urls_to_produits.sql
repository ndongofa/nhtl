-- ============================================
-- NHTL Project - Migration 009: Multi-image support for products
-- ============================================
-- Créé: 2026-04-17
-- Description: Ajout de la colonne image_urls pour stocker plusieurs photos par produit

ALTER TABLE produits
    ADD COLUMN IF NOT EXISTS image_urls TEXT;
