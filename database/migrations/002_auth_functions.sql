-- ============================================
-- NHTL Project - Authentication Functions
-- ============================================
-- Créé: 2026-02-17
-- Description: Fonctions pour l'inscription et la connexion

-- ============================================
-- FONCTION: register_user
-- ============================================
CREATE OR REPLACE FUNCTION register_user(
  p_identifier VARCHAR,
  p_password VARCHAR,
  p_auth_method VARCHAR,
  p_role VARCHAR DEFAULT 'user'
)
RETURNS JSON AS $$
DECLARE
  v_user_id UUID;
  v_email VARCHAR;
  v_phone VARCHAR;
BEGIN
  -- Déterminer si c'est un email ou un téléphone
  IF p_auth_method = 'email' THEN
    v_email := p_identifier;
    v_phone := NULL;
  ELSIF p_auth_method = 'phone' THEN
    v_phone := p_identifier;
    v_email := NULL;
  ELSE
    RETURN json_build_object('success', FALSE, 'error', 'auth_method doit être email ou phone');
  END IF;

  -- Créer l'utilisateur
  INSERT INTO users (email, phone_number, username, password_hash, auth_method, role)
  VALUES (v_email, v_phone, p_identifier, crypt(p_password, gen_salt('bf')), p_auth_method, p_role)
  RETURNING id INTO v_user_id;

  RETURN json_build_object(
    'success', TRUE,
    'user_id', v_user_id,
    'message', 'Utilisateur créé avec succès'
  );

EXCEPTION 
  WHEN unique_violation THEN
    RETURN json_build_object('success', FALSE, 'error', 'Cet identifiant est déjà utilisé');
  WHEN OTHERS THEN
    RETURN json_build_object('success', FALSE, 'error', SQLERRM);
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- FONCTION: login_user
-- ============================================
CREATE OR REPLACE FUNCTION login_user(
  p_identifier VARCHAR,
  p_password VARCHAR
)
RETURNS JSON AS $$
DECLARE
  v_user_id UUID;
  v_role VARCHAR;
  v_email VARCHAR;
  v_phone VARCHAR;
  v_auth_method VARCHAR;
  v_password_hash VARCHAR;
BEGIN
  -- Chercher l'utilisateur par email ou téléphone
  SELECT id, role, email, phone_number, auth_method, password_hash
  INTO v_user_id, v_role, v_email, v_phone, v_auth_method, v_password_hash
  FROM users
  WHERE email = p_identifier OR phone_number = p_identifier
  LIMIT 1;

  -- Si pas trouvé
  IF v_user_id IS NULL THEN
    RETURN json_build_object('success', FALSE, 'error', 'Identifiant ou mot de passe incorrect');
  END IF;

  -- Vérifier le mot de passe
  IF NOT (v_password_hash = crypt(p_password, v_password_hash)) THEN
    RETURN json_build_object('success', FALSE, 'error', 'Identifiant ou mot de passe incorrect');
  END IF;

  -- Enregistrer la connexion
  INSERT INTO user_login_history (user_id, login_method)
  VALUES (v_user_id, v_auth_method);

  RETURN json_build_object(
    'success', TRUE,
    'user_id', v_user_id,
    'role', v_role,
    'email', v_email,
    'phone', v_phone,
    'auth_method', v_auth_method
  );

EXCEPTION WHEN OTHERS THEN
  RETURN json_build_object('success', FALSE, 'error', SQLERRM);
END;
$$ LANGUAGE plpgsql;