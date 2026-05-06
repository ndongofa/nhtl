-- 013 : Table de stockage persistant des OTP signup par téléphone
-- Remplace le ConcurrentHashMap en mémoire dans le backend Java.
-- Survit aux redémarrages du serveur et fonctionne avec plusieurs instances.

CREATE TABLE IF NOT EXISTS phone_otp_tokens (
    phone      TEXT PRIMARY KEY,
    otp        TEXT NOT NULL,
    expires_at TIMESTAMPTZ NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Index pour faciliter la purge des tokens expirés
CREATE INDEX IF NOT EXISTS idx_phone_otp_tokens_expires_at ON phone_otp_tokens (expires_at);

-- Seul le rôle service_role a accès (pas d'accès public)
ALTER TABLE phone_otp_tokens ENABLE ROW LEVEL SECURITY;
