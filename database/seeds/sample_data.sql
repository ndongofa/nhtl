-- ============================================
-- NHTL Project - Sample Data
-- ============================================
-- Créé: 2026-02-17
-- Description: Données d'exemple pour tester

-- Insérer un admin de test
INSERT INTO users (email, username, password_hash, auth_method, role, is_verified)
VALUES (
  'admin@ngom-holding.com',
  'admin',
  crypt('admin123', gen_salt('bf')),
  'email',
  'admin',
  TRUE
);

-- Insérer un utilisateur de test
INSERT INTO users (phone_number, username, password_hash, auth_method, role, is_verified)
VALUES (
  '+221770000001',
  'user1',
  crypt('user123', gen_salt('bf')),
  'phone',
  'user',
  TRUE
);

-- Insérer un guest de test
INSERT INTO users (email, username, password_hash, auth_method, role, is_verified)
VALUES (
  'guest@ngom-holding.com',
  'guest',
  crypt('guest123', gen_salt('bf')),
  'email',
  'guest',
  FALSE
);

-- Ajouter des permissions aux utilisateurs
INSERT INTO user_permissions (user_id, permission)
SELECT id, 'admin.manage_users' FROM users WHERE role = 'admin';

INSERT INTO user_permissions (user_id, permission)
SELECT id, 'user.read_profile' FROM users WHERE role = 'user';

INSERT INTO user_permissions (user_id, permission)
SELECT id, 'guest.limited_access' FROM users WHERE role = 'guest';