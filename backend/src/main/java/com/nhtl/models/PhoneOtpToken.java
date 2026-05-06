package com.nhtl.models;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.Instant;

/**
 * Stockage persistant des codes OTP signup par numéro de téléphone.
 * <p>
 * Remplace le {@code ConcurrentHashMap} en mémoire de {@code PhoneOtpService}
 * afin que les OTP survivent aux redémarrages du backend et fonctionnent
 * en mode multi-instance.
 */
@Entity
@Table(name = "phone_otp_tokens")
public class PhoneOtpToken {

    /** Numéro E.164 du destinataire (clé primaire). */
    @Id
    @Column(nullable = false)
    private String phone;

    /** Code OTP à 6 chiffres. */
    @Column(nullable = false)
    private String otp;

    /** Timestamp d'expiration (10 min après génération). */
    @Column(name = "expires_at", nullable = false)
    private Instant expiresAt;

    /** Timestamp de création. */
    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt = Instant.now();

    public PhoneOtpToken() {}

    public PhoneOtpToken(String phone, String otp, Instant expiresAt) {
        this.phone = phone;
        this.otp = otp;
        this.expiresAt = expiresAt;
        this.createdAt = Instant.now();
    }

    public String getPhone() { return phone; }
    public void setPhone(String phone) { this.phone = phone; }

    public String getOtp() { return otp; }
    public void setOtp(String otp) { this.otp = otp; }

    public Instant getExpiresAt() { return expiresAt; }
    public void setExpiresAt(Instant expiresAt) { this.expiresAt = expiresAt; }

    public Instant getCreatedAt() { return createdAt; }
    public void setCreatedAt(Instant createdAt) { this.createdAt = createdAt; }
}
