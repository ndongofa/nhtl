-- Migration V13 : Table de stockage persistant des OTP signup par téléphone
-- Remplace le ConcurrentHashMap en mémoire dans PhoneOtpService.
-- Survit aux redémarrages du serveur et fonctionne avec plusieurs instances.

CREATE TABLE IF NOT EXISTS phone_otp_tokens (
    phone      VARCHAR(20) PRIMARY KEY,
    otp        VARCHAR(10) NOT NULL,
    expires_at TIMESTAMPTZ NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Index pour faciliter la purge des tokens expirés
CREATE INDEX IF NOT EXISTS idx_phone_otp_tokens_expires_at ON phone_otp_tokens (expires_at);
