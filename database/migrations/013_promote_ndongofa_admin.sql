-- ============================================
-- NHTL Project - Promote ndongofa@hotmail.com to admin
-- ============================================
-- Créé: 2026-04-27
-- Description: Passe l'utilisateur ndongofa@hotmail.com (id: 980ea104-2dcc-43e6-b6db-ce885aec92c1) en rôle admin
--              dans auth.users (raw_user_meta_data) et dans public.users.

-- 1. Mettre à jour le rôle dans les métadonnées Supabase Auth
UPDATE auth.users
SET raw_user_meta_data = raw_user_meta_data || '{"role": "admin"}'::jsonb
WHERE id = '980ea104-2dcc-43e6-b6db-ce885aec92c1';

-- 2. Mettre à jour le rôle dans la table public.users (si l'entrée existe)
UPDATE public.users
SET role = 'admin'
WHERE id = '980ea104-2dcc-43e6-b6db-ce885aec92c1';
