-- ============================================
-- NHTL Project - Migration 008: RLS sur tables e-commerce et achats
-- ============================================
-- Créé: 2026-04-08
-- Description: Active Row Level Security (RLS) sur les tables créées
--              dans les migrations 004 et 005, qui n'en disposaient pas.
--              Résout l'alerte critique Supabase "rls_disabled_in_public".

-- ============================================
-- ACTIVER RLS
-- ============================================
ALTER TABLE achats                  ENABLE ROW LEVEL SECURITY;
ALTER TABLE produits                ENABLE ROW LEVEL SECURITY;
ALTER TABLE panier_items            ENABLE ROW LEVEL SECURITY;
ALTER TABLE commandes_ecommerce     ENABLE ROW LEVEL SECURITY;
ALTER TABLE commande_ecommerce_items ENABLE ROW LEVEL SECURITY;

-- ============================================
-- HELPER: is_admin()
-- Renvoie true si l'utilisateur connecté a le rôle 'admin'
-- ============================================
CREATE OR REPLACE FUNCTION is_admin()
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
  SELECT EXISTS (
    SELECT 1 FROM users WHERE id = auth.uid()::uuid AND role = 'admin'
  );
$$;

-- ============================================
-- POLITIQUES: achats
-- ============================================

-- Lecture : chacun voit ses propres achats ; les admins voient tout
CREATE POLICY "achats: users select own"
  ON achats FOR SELECT
  USING (auth.uid()::text = user_id::text OR is_admin());

-- Création : l'utilisateur connecté peut créer un achat avec son user_id,
-- ou sans user_id (formulaire invité)
CREATE POLICY "achats: users insert own"
  ON achats FOR INSERT
  WITH CHECK (
    user_id IS NULL
    OR auth.uid()::text = user_id::text
    OR is_admin()
  );

-- Modification : l'utilisateur ne peut modifier que ses propres achats
CREATE POLICY "achats: users update own"
  ON achats FOR UPDATE
  USING (auth.uid()::text = user_id::text OR is_admin());

-- Suppression : admins uniquement
CREATE POLICY "achats: admins delete"
  ON achats FOR DELETE
  USING (is_admin());

-- ============================================
-- POLITIQUES: produits
-- ============================================

-- Lecture publique : le catalogue est visible par tous (y compris anon)
CREATE POLICY "produits: public select"
  ON produits FOR SELECT
  USING (true);

-- Création, modification, suppression : admins uniquement
CREATE POLICY "produits: admins insert"
  ON produits FOR INSERT
  WITH CHECK (is_admin());

CREATE POLICY "produits: admins update"
  ON produits FOR UPDATE
  USING (is_admin());

CREATE POLICY "produits: admins delete"
  ON produits FOR DELETE
  USING (is_admin());

-- ============================================
-- POLITIQUES: panier_items
-- ============================================

-- Lecture : chacun voit son propre panier
CREATE POLICY "panier_items: users select own"
  ON panier_items FOR SELECT
  USING (auth.uid()::text = user_id::text OR is_admin());

-- Création : l'utilisateur connecté ne peut ajouter que pour lui-même
CREATE POLICY "panier_items: users insert own"
  ON panier_items FOR INSERT
  WITH CHECK (auth.uid()::text = user_id::text OR is_admin());

-- Modification : l'utilisateur ne peut modifier que son panier
CREATE POLICY "panier_items: users update own"
  ON panier_items FOR UPDATE
  USING (auth.uid()::text = user_id::text OR is_admin());

-- Suppression : l'utilisateur ne peut supprimer que ses articles
CREATE POLICY "panier_items: users delete own"
  ON panier_items FOR DELETE
  USING (auth.uid()::text = user_id::text OR is_admin());

-- ============================================
-- POLITIQUES: commandes_ecommerce
-- ============================================

-- Lecture : chacun voit ses propres commandes ; les admins voient tout
CREATE POLICY "commandes_ecommerce: users select own"
  ON commandes_ecommerce FOR SELECT
  USING (auth.uid()::text = user_id::text OR is_admin());

-- Création : l'utilisateur connecté crée des commandes avec son user_id
CREATE POLICY "commandes_ecommerce: users insert own"
  ON commandes_ecommerce FOR INSERT
  WITH CHECK (auth.uid()::text = user_id::text OR is_admin());

-- Modification : l'utilisateur ne peut modifier que ses propres commandes
CREATE POLICY "commandes_ecommerce: users update own"
  ON commandes_ecommerce FOR UPDATE
  USING (auth.uid()::text = user_id::text OR is_admin());

-- Suppression : admins uniquement
CREATE POLICY "commandes_ecommerce: admins delete"
  ON commandes_ecommerce FOR DELETE
  USING (is_admin());

-- ============================================
-- POLITIQUES: commande_ecommerce_items
-- ============================================

-- Lecture : un utilisateur ne voit les articles que de ses propres commandes
CREATE POLICY "commande_ecommerce_items: users select own"
  ON commande_ecommerce_items FOR SELECT
  USING (
    is_admin()
    OR EXISTS (
      SELECT 1 FROM commandes_ecommerce ce
      WHERE ce.id = commande_ecommerce_id
        AND auth.uid()::text = ce.user_id::text
    )
  );

-- Création : liée à une commande appartenant à l'utilisateur
CREATE POLICY "commande_ecommerce_items: users insert own"
  ON commande_ecommerce_items FOR INSERT
  WITH CHECK (
    is_admin()
    OR EXISTS (
      SELECT 1 FROM commandes_ecommerce ce
      WHERE ce.id = commande_ecommerce_id
        AND auth.uid()::text = ce.user_id::text
    )
  );

-- Modification : liée à une commande appartenant à l'utilisateur
CREATE POLICY "commande_ecommerce_items: users update own"
  ON commande_ecommerce_items FOR UPDATE
  USING (
    is_admin()
    OR EXISTS (
      SELECT 1 FROM commandes_ecommerce ce
      WHERE ce.id = commande_ecommerce_id
        AND auth.uid()::text = ce.user_id::text
    )
  );

-- Suppression : admins uniquement
CREATE POLICY "commande_ecommerce_items: admins delete"
  ON commande_ecommerce_items FOR DELETE
  USING (is_admin());
