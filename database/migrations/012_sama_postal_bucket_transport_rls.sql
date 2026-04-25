-- ============================================
-- NHTL Project - Migration 012: Bucket sama-postal + RLS transports/colis
-- ============================================
-- Créé: 2026-04-25
-- Description:
--   1. Crée le bucket Supabase Storage "sama-postal" s'il n'existe pas encore.
--      Ce bucket est partagé par commandes, achats et transports pour les
--      photos produits et photos colis.
--   2. Ajoute les politiques RLS permettant aux utilisateurs authentifiés
--      d'uploader leurs photos de colis dans transports/colis/.
--
-- IMPORTANT : Si le bucket sama-postal existe déjà (créé manuellement),
-- l'INSERT ci-dessous sera ignoré grâce à ON CONFLICT DO NOTHING.
-- Vérifiez que les politiques RLS ne sont pas en double avant d'exécuter.

-- ============================================
-- BUCKET: sama-postal (public)
-- ============================================
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'sama-postal',
  'sama-postal',
  true,
  10485760,  -- 10 MB max par fichier
  ARRAY['image/jpeg', 'image/png', 'image/webp']
)
ON CONFLICT (id) DO NOTHING;

-- ============================================
-- POLITIQUES RLS: storage.objects (sama-postal)
-- NOTE: CREATE POLICY IF NOT EXISTS n'existe qu'en PG17+.
--       On utilise des blocs DO $$ pour rester compatible PG15 (Supabase).
-- ============================================

-- Lecture publique : les URLs publiques doivent être accessibles à tous
-- (nécessaire pour afficher les photos dans l'app sans authentification)
DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'storage' AND tablename = 'objects'
      AND policyname = 'sama-postal: public read'
  ) THEN
    CREATE POLICY "sama-postal: public read"
      ON storage.objects FOR SELECT
      USING (bucket_id = 'sama-postal');
  END IF;
END $$;

-- ── Sous-dossier commandes/produits ──────────────────────────────────────────

-- Upload : utilisateur authentifié peut uploader ses photos commande
DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'storage' AND tablename = 'objects'
      AND policyname = 'sama-postal commandes: authenticated insert'
  ) THEN
    CREATE POLICY "sama-postal commandes: authenticated insert"
      ON storage.objects FOR INSERT
      WITH CHECK (
        bucket_id = 'sama-postal'
        AND (storage.foldername(name))[1] = 'commandes'
        AND auth.role() = 'authenticated'
      );
  END IF;
END $$;

-- Mise à jour / remplacement (upsert)
DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'storage' AND tablename = 'objects'
      AND policyname = 'sama-postal commandes: authenticated update'
  ) THEN
    CREATE POLICY "sama-postal commandes: authenticated update"
      ON storage.objects FOR UPDATE
      USING (
        bucket_id = 'sama-postal'
        AND (storage.foldername(name))[1] = 'commandes'
        AND auth.role() = 'authenticated'
      );
  END IF;
END $$;

-- ── Sous-dossier achats/produits ─────────────────────────────────────────────

DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'storage' AND tablename = 'objects'
      AND policyname = 'sama-postal achats: authenticated insert'
  ) THEN
    CREATE POLICY "sama-postal achats: authenticated insert"
      ON storage.objects FOR INSERT
      WITH CHECK (
        bucket_id = 'sama-postal'
        AND (storage.foldername(name))[1] = 'achats'
        AND auth.role() = 'authenticated'
      );
  END IF;
END $$;

DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'storage' AND tablename = 'objects'
      AND policyname = 'sama-postal achats: authenticated update'
  ) THEN
    CREATE POLICY "sama-postal achats: authenticated update"
      ON storage.objects FOR UPDATE
      USING (
        bucket_id = 'sama-postal'
        AND (storage.foldername(name))[1] = 'achats'
        AND auth.role() = 'authenticated'
      );
  END IF;
END $$;

-- ── Sous-dossier transports/colis (NOUVEAU) ───────────────────────────────────

-- Upload : utilisateur authentifié peut uploader les photos de son colis
DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'storage' AND tablename = 'objects'
      AND policyname = 'sama-postal transports: authenticated insert'
  ) THEN
    CREATE POLICY "sama-postal transports: authenticated insert"
      ON storage.objects FOR INSERT
      WITH CHECK (
        bucket_id = 'sama-postal'
        AND (storage.foldername(name))[1] = 'transports'
        AND auth.role() = 'authenticated'
      );
  END IF;
END $$;

-- Mise à jour / remplacement (upsert activé dans le code Flutter)
DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'storage' AND tablename = 'objects'
      AND policyname = 'sama-postal transports: authenticated update'
  ) THEN
    CREATE POLICY "sama-postal transports: authenticated update"
      ON storage.objects FOR UPDATE
      USING (
        bucket_id = 'sama-postal'
        AND (storage.foldername(name))[1] = 'transports'
        AND auth.role() = 'authenticated'
      );
  END IF;
END $$;

-- ── Sous-dossier postal (suivi postal admin) ─────────────────────────────────

-- Upload : utilisateurs authentifiés (admin dépose les photos de suivi)
DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'storage' AND tablename = 'objects'
      AND policyname = 'sama-postal postal: authenticated insert'
  ) THEN
    CREATE POLICY "sama-postal postal: authenticated insert"
      ON storage.objects FOR INSERT
      WITH CHECK (
        bucket_id = 'sama-postal'
        AND (storage.foldername(name))[1] = 'postal'
        AND auth.role() = 'authenticated'
      );
  END IF;
END $$;

DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'storage' AND tablename = 'objects'
      AND policyname = 'sama-postal postal: authenticated update'
  ) THEN
    CREATE POLICY "sama-postal postal: authenticated update"
      ON storage.objects FOR UPDATE
      USING (
        bucket_id = 'sama-postal'
        AND (storage.foldername(name))[1] = 'postal'
        AND auth.role() = 'authenticated'
      );
  END IF;
END $$;
