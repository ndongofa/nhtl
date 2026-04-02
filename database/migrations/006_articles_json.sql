-- Migration 006 : ajout du champ articles_json pour le formulaire multi-articles
-- Commandes : articles_json stocke la liste détaillée des articles (liens + photos)
ALTER TABLE commandes ADD COLUMN IF NOT EXISTS articles_json TEXT;

-- Achats : articles_json + liens_produits + photos_produits pour supporter liens et photos
ALTER TABLE achats ADD COLUMN IF NOT EXISTS articles_json TEXT;
ALTER TABLE achats ADD COLUMN IF NOT EXISTS liens_produits TEXT;
ALTER TABLE achats ADD COLUMN IF NOT EXISTS photos_produits TEXT;
