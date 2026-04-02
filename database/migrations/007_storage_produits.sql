-- ============================================
-- NHTL Project - Migration 007: Storage bucket sama-produits
-- ============================================
-- Créé: 2026-04-02
-- Description: Crée le bucket Supabase Storage "sama-produits" pour les
--              images des produits e-commerce (Sama Maad, Téranga Apéro,
--              Best Seller) et définit les politiques RLS associées.

-- ============================================
-- BUCKET: sama-produits (public)
-- ============================================
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'sama-produits',
  'sama-produits',
  true,
  5242880,   -- 5 MB max par fichier
  ARRAY['image/jpeg', 'image/png', 'image/webp']
)
ON CONFLICT (id) DO NOTHING;

-- ============================================
-- POLITIQUES RLS: storage.objects (sama-produits)
-- ============================================

-- Lecture publique : tout le monde peut lire les images produits
CREATE POLICY "sama-produits: public read"
  ON storage.objects FOR SELECT
  USING (bucket_id = 'sama-produits');

-- Upload : utilisateurs authentifiés uniquement (admins)
CREATE POLICY "sama-produits: authenticated insert"
  ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id = 'sama-produits'
    AND auth.role() = 'authenticated'
  );

-- Mise à jour : utilisateurs authentifiés uniquement
CREATE POLICY "sama-produits: authenticated update"
  ON storage.objects FOR UPDATE
  USING (
    bucket_id = 'sama-produits'
    AND auth.role() = 'authenticated'
  );

-- Suppression : utilisateurs authentifiés uniquement
CREATE POLICY "sama-produits: authenticated delete"
  ON storage.objects FOR DELETE
  USING (
    bucket_id = 'sama-produits'
    AND auth.role() = 'authenticated'
  );
