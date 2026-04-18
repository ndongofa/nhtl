package com.nhtl.services;

import java.time.Instant;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.TimeUnit;

import org.springframework.stereotype.Service;

import com.nhtl.notifications.providers.SmsProvider;
import com.nhtl.notifications.providers.WhatsAppProvider;
import com.nhtl.security.OtpUtil;

import lombok.extern.slf4j.Slf4j;

/**
 * Service OTP pour la confirmation du numéro de téléphone lors du signup.
 *
 * <p>Génère un code à 6 chiffres, le stocke en mémoire avec une expiration,
 * puis l'envoie via WhatsApp en priorité, avec fallback automatique sur SMS Twilio.
 *
 * <p>Le store en mémoire suffit pour des OTP de courte durée (10 min) ; il ne
 * survit pas aux redémarrages du serveur, ce qui est acceptable pour ce cas d'usage.
 */
@Slf4j
@Service
public class PhoneOtpService {

    private static final int OTP_EXPIRY_MINUTES = 10;

    private record OtpEntry(String otp, long expiryMs) {}

    private final ConcurrentHashMap<String, OtpEntry> store = new ConcurrentHashMap<>();

    private final WhatsAppProvider whatsAppProvider;
    private final SmsProvider smsProvider;

    public PhoneOtpService(WhatsAppProvider whatsAppProvider, SmsProvider smsProvider) {
        this.whatsAppProvider = whatsAppProvider;
        this.smsProvider = smsProvider;
    }

    /**
     * Génère un OTP pour le numéro donné et l'envoie via WhatsApp → SMS.
     *
     * @param phone numéro E.164 (ex: +221783042838)
     * @throws RuntimeException si ni WhatsApp ni SMS ne fonctionnent
     */
    public void sendOtp(String phone) {
        if (phone == null || phone.isBlank()) {
            throw new IllegalArgumentException("Numéro de téléphone requis.");
        }
        final String normalizedPhone = phone.trim();
        final String otp = OtpUtil.generateOtp();
        final long expiry = Instant.now().toEpochMilli() + TimeUnit.MINUTES.toMillis(OTP_EXPIRY_MINUTES);
        store.put(normalizedPhone, new OtpEntry(otp, expiry));

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
    public boolean verifyOtp(String phone, String otp) {
        if (phone == null || otp == null) return false;
        final String normalizedPhone = phone.trim();
        final OtpEntry entry = store.get(normalizedPhone);

        if (entry == null) {
            log.info("[PhoneOtpService] No OTP found for phone={}", maskPhone(normalizedPhone));
            return false;
        }
        if (Instant.now().toEpochMilli() > entry.expiryMs()) {
            store.remove(normalizedPhone);
            log.info("[PhoneOtpService] OTP expired for phone={}", maskPhone(normalizedPhone));
            return false;
        }
        if (!entry.otp().equals(otp.trim())) {
            log.info("[PhoneOtpService] Wrong OTP for phone={}", maskPhone(normalizedPhone));
            return false;
        }
        store.remove(normalizedPhone);
        log.info("[PhoneOtpService] OTP verified for phone={}", maskPhone(normalizedPhone));
        return true;
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
