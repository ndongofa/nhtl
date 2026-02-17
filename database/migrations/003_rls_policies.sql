-- ============================================
-- NHTL Project - Row Level Security (RLS)
-- ============================================
-- Créé: 2026-02-17
-- Description: Politiques de sécurité au niveau des lignes

-- ============================================
-- ACTIVER RLS
-- ============================================
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_permissions ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_login_history ENABLE ROW LEVEL SECURITY;

-- ============================================
-- POLITIQUES: users
-- ============================================

-- Les utilisateurs ne voient que leur profil
CREATE POLICY "Users can view their own profile"
  ON users FOR SELECT
  USING (auth.uid()::text = id::text);

-- Les admins voient tous les utilisateurs
CREATE POLICY "Admins can view all users"
  ON users FOR SELECT
  USING (
    (SELECT role FROM users WHERE id = auth.uid()::uuid) = 'admin'
  );

-- Les utilisateurs ne peuvent modifier que leur profil
CREATE POLICY "Users can update their own profile"
  ON users FOR UPDATE
  USING (auth.uid()::text = id::text);

-- Les admins peuvent modifier n'importe quel utilisateur
CREATE POLICY "Admins can update all users"
  ON users FOR UPDATE
  USING (
    (SELECT role FROM users WHERE id = auth.uid()::uuid) = 'admin'
  );

-- ============================================
-- POLITIQUES: user_permissions
-- ============================================

-- Chacun voit ses permissions
CREATE POLICY "Users can view their own permissions"
  ON user_permissions FOR SELECT
  USING (auth.uid()::text = user_id::text);

-- Les admins voient les permissions de tous
CREATE POLICY "Admins can view all permissions"
  ON user_permissions FOR SELECT
  USING (
    (SELECT role FROM users WHERE id = auth.uid()::uuid) = 'admin'
  );

-- ============================================
-- POLITIQUES: user_login_history
-- ============================================

-- Chacun voit son historique de connexion
CREATE POLICY "Users can view their own login history"
  ON user_login_history FOR SELECT
  USING (auth.uid()::text = user_id::text);

-- Les admins voient tout l'historique
CREATE POLICY "Admins can view all login history"
  ON user_login_history FOR SELECT
  USING (
    (SELECT role FROM users WHERE id = auth.uid()::uuid) = 'admin'
  );