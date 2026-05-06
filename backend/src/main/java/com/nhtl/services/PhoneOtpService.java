package com.nhtl.services;

import java.time.Instant;
import java.time.temporal.ChronoUnit;

import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.nhtl.models.PhoneOtpToken;
import com.nhtl.notifications.providers.SmsProvider;
import com.nhtl.notifications.providers.WhatsAppProvider;
import com.nhtl.repositories.PhoneOtpTokenRepository;
import com.nhtl.security.OtpUtil;

import lombok.extern.slf4j.Slf4j;

/**
 * Service OTP pour la confirmation du numéro de téléphone lors du signup.
 *
 * <p>Génère un code à 6 chiffres, le persiste en base de données avec une
 * expiration, puis l'envoie via WhatsApp en priorité, avec fallback automatique
 * sur SMS Twilio.
 *
 * <p>Le stockage en base survit aux redémarrages du serveur et fonctionne
 * correctement en mode multi-instance.
 */
@Slf4j
@Service
public class PhoneOtpService {

    static final int OTP_EXPIRY_MINUTES = 10;
    /** Intervalle de purge des tokens expirés en ms (1 heure). */
    private static final long PURGE_INTERVAL_MS = 60 * 60 * 1_000L;

    private final PhoneOtpTokenRepository otpTokenRepository;
    private final WhatsAppProvider whatsAppProvider;
    private final SmsProvider smsProvider;

    public PhoneOtpService(PhoneOtpTokenRepository otpTokenRepository,
                           WhatsAppProvider whatsAppProvider,
                           SmsProvider smsProvider) {
        this.otpTokenRepository = otpTokenRepository;
        this.whatsAppProvider = whatsAppProvider;
        this.smsProvider = smsProvider;
    }

    /**
     * Génère un OTP pour le numéro donné, le persiste en base et l'envoie via WhatsApp → SMS.
     *
     * @param phone numéro E.164 (ex: +221783042838)
     * @throws RuntimeException si ni WhatsApp ni SMS ne fonctionnent
     */
    @Transactional
    public void sendOtp(String phone) {
        if (phone == null || phone.isBlank()) {
            throw new IllegalArgumentException("Numéro de téléphone requis.");
        }
        final String normalizedPhone = phone.trim();
        final String otp = OtpUtil.generateOtp();
        final Instant expiresAt = Instant.now().plus(OTP_EXPIRY_MINUTES, ChronoUnit.MINUTES);

        otpTokenRepository.save(new PhoneOtpToken(normalizedPhone, otp, expiresAt));

        log.info("[PhoneOtpService] OTP generated for phone={}", maskPhone(normalizedPhone));

        final String message = "SAMA - Votre code de confirmation est : " + otp
                + " (valide " + OTP_EXPIRY_MINUTES + " minutes).";
        sendViaWhatsAppOrSms(normalizedPhone, message);
    }

    /**
     * Vérifie le code OTP pour le numéro donné.
     *
     * @return {@code true} si le code est correct et non expiré ; {@code false} sinon
     */
    @Transactional
    public boolean verifyOtp(String phone, String otp) {
        if (phone == null || otp == null) return false;
        final String normalizedPhone = phone.trim();

        PhoneOtpToken entry = otpTokenRepository.findById(normalizedPhone).orElse(null);

        if (entry == null) {
            log.info("[PhoneOtpService] No OTP found for phone={}", maskPhone(normalizedPhone));
            return false;
        }
        if (Instant.now().isAfter(entry.getExpiresAt())) {
            otpTokenRepository.deleteById(normalizedPhone);
            log.info("[PhoneOtpService] OTP expired for phone={}", maskPhone(normalizedPhone));
            return false;
        }
        if (!entry.getOtp().equals(otp.trim())) {
            log.info("[PhoneOtpService] Wrong OTP for phone={}", maskPhone(normalizedPhone));
            return false;
        }
        otpTokenRepository.deleteById(normalizedPhone);
        log.info("[PhoneOtpService] OTP verified for phone={}", maskPhone(normalizedPhone));
        return true;
    }

    /**
     * Purge automatique des tokens expirés toutes les heures.
     */
    @Scheduled(fixedRate = PURGE_INTERVAL_MS)
    @Transactional
    public void purgeExpiredTokens() {
        int deleted = otpTokenRepository.deleteAllExpiredBefore(Instant.now());
        if (deleted > 0) {
            log.info("[PhoneOtpService] Purged {} expired OTP token(s)", deleted);
        }
    }

    // ── Internal helpers ──────────────────────────────────────────────────────

    private void sendViaWhatsAppOrSms(String phone, String message) {
        try {
            whatsAppProvider.sendWhatsApp(phone, message);
            log.info("[PhoneOtpService] OTP sent via WhatsApp to phone={}", maskPhone(phone));
        } catch (Exception waEx) {
            log.warn("[PhoneOtpService] WhatsApp failed for phone={}, falling back to SMS: {}",
                    maskPhone(phone), waEx.getMessage());
            try {
                smsProvider.sendSms(phone, message);
                log.info("[PhoneOtpService] OTP sent via SMS fallback to phone={}", maskPhone(phone));
            } catch (Exception smsEx) {
                log.error("[PhoneOtpService] Both WhatsApp and SMS failed for phone={}: {}",
                        maskPhone(phone), smsEx.getMessage());
                throw new RuntimeException(
                        "Impossible d'envoyer le code. Vérifiez votre numéro et réessayez dans quelques instants.",
                        smsEx);
            }
        }
    }

    private static String maskPhone(String phone) {
        if (phone == null || phone.length() < 5) return "***";
        return phone.substring(0, 4) + "***" + phone.substring(phone.length() - 2);
    }
}
