-- ============================================
-- Migration 010 : Ajout de created_at à utilisateurs
-- ============================================
-- Créé: 2026-04-18
-- Description:
--   1. Ajoute la colonne created_at (TIMESTAMPTZ) à public.utilisateurs
--   2. Backfille la date de création depuis auth.users pour les lignes existantes
--   3. Crée/remplace la fonction trigger handle_new_user pour synchroniser
--      created_at lors de l'insertion d'un nouvel auth.users
--   4. Pose (ou repose) le trigger on_auth_user_created

-- ============================================
-- ÉTAPE 1 : Ajouter la colonne si elle n'existe pas
-- ============================================
ALTER TABLE public.utilisateurs
  ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ DEFAULT now();

-- ============================================
-- ÉTAPE 2 : Backfiller depuis auth.users
-- ============================================
UPDATE public.utilisateurs u
SET    created_at = au.created_at
FROM   auth.users au
WHERE  u.id = au.id
  AND  u.created_at IS NULL;

-- ============================================
-- ÉTAPE 3 : Fonction de synchronisation (trigger)
-- ============================================
-- Cette fonction est appelée lors de l'insertion d'un utilisateur dans
-- auth.users (par Supabase Auth). Elle crée / met à jour la ligne
-- correspondante dans public.utilisateurs.
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO public.utilisateurs (
    id,
    email,
    phone,
    prenom,
    nom,
    role,
    created_at
  )
  VALUES (
    NEW.id,
    NEW.email,
    NEW.phone,
    COALESCE(NEW.raw_user_meta_data->>'prenom', NULL),
    COALESCE(NEW.raw_user_meta_data->>'nom',    NULL),
    COALESCE(NEW.raw_user_meta_data->>'role',   'user'),
    NEW.created_at
  )
  ON CONFLICT (id) DO UPDATE SET
    email      = EXCLUDED.email,
    phone      = EXCLUDED.phone,
    prenom     = COALESCE(EXCLUDED.prenom, public.utilisateurs.prenom),
    nom        = COALESCE(EXCLUDED.nom,    public.utilisateurs.nom),
    role       = COALESCE(EXCLUDED.role,   public.utilisateurs.role),
    created_at = COALESCE(public.utilisateurs.created_at, EXCLUDED.created_at);

  RETURN NEW;
END;
$$;

-- ============================================
-- ÉTAPE 4 : Créer (ou recréer) le trigger
-- ============================================
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE PROCEDURE public.handle_new_user();

-- ============================================
-- ÉTAPE 5 : Index pour les performances
-- ============================================
CREATE INDEX IF NOT EXISTS idx_utilisateurs_created_at
  ON public.utilisateurs (created_at DESC);
