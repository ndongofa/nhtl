package com.nhtl.notifications.providers;

import java.util.HashMap;
import java.util.Map;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Profile;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestTemplate;

import com.twilio.Twilio;
import com.twilio.exception.ApiException;
import com.twilio.rest.api.v2010.account.Message;
import com.twilio.type.PhoneNumber;

import lombok.extern.slf4j.Slf4j;

/**
 * Provider SMS de production avec basculement automatique : Brevo en premier,
 * Twilio en fallback si Brevo échoue (pas d'interruption de service).
 */
@Slf4j
@Component
@Profile("prod")
public class FallbackSmsProvider implements SmsProvider {

    private static final String BREVO_SMS_URL = "https://api.brevo.com/v3/transactionalSMS/sms";

    private final RestTemplate restTemplate = new RestTemplate();

    // --- Brevo ---
    @Value("${brevo.apiKey:}")
    private String brevoApiKey;

    @Value("${brevo.sms.from:SamaService}")
    private String brevoSenderName;

    // --- Twilio ---
    @Value("${twilio.accountSid:}")
    private String twilioAccountSid;

    @Value("${twilio.authToken:}")
    private String twilioAuthToken;

    @Value("${twilio.fromNumber:}")
    private String twilioFromNumber;

    private volatile boolean twilioInitialized = false;

    @Override
    public void sendSms(String to, String message) {
        if (to == null || to.isBlank()) {
            log.info("[SMS-FALLBACK] Skipped: empty recipient");
            return;
        }
        if (message == null || message.isBlank()) {
            log.info("[SMS-FALLBACK] Skipped: empty message to='{}'", to);
            return;
        }

        // 1. Tentative Brevo
        if (brevoApiKey != null && !brevoApiKey.isBlank()) {
            try {
                sendViaBrevo(to, message);
                return; // succès Brevo → on s'arrête
            } catch (Exception e) {
                log.warn("[SMS-FALLBACK] Brevo failed to='{}', switching to Twilio. err='{}'", to, e.getMessage());
            }
        } else {
            log.info("[SMS-FALLBACK] Brevo not configured, trying Twilio directly for to='{}'", to);
        }

        // 2. Fallback Twilio
        try {
            sendViaTwilio(to, message);
        } catch (Exception e) {
            log.error("[SMS-FALLBACK] Both Brevo and Twilio failed to='{}' — SMS skipped, registration proceeds. err='{}'",
                    to, e.getMessage());
            // Ne pas relancer l'exception : l'inscription ne doit pas être bloquée
            // par une panne SMS. Le message est perdu, mais le flux utilisateur continue.
        }
    }

    private void sendViaBrevo(String to, String message) {
        String recipient = normalizePhone(to);
        log.info("[SMS-FALLBACK][BREVO] Sending to='{}' sender='{}' msg='{}'",
                recipient, brevoSenderName, truncate(message, 140));

        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_JSON);
        headers.set("api-key", brevoApiKey);

        Map<String, Object> payload = new HashMap<>();
        payload.put("sender", brevoSenderName);
        payload.put("recipient", recipient);
        payload.put("content", message);
        payload.put("type", "transactional");

        HttpEntity<Map<String, Object>> req = new HttpEntity<>(payload, headers);
        var resp = restTemplate.postForEntity(BREVO_SMS_URL, req, String.class);
        log.info("[SMS-FALLBACK][BREVO] Accepted status={} to='{}'", resp.getStatusCode().value(), recipient);
    }

    private void sendViaTwilio(String to, String message) {
        initTwilioIfNeeded();
        if (!twilioInitialized) {
            log.warn("[SMS-FALLBACK][TWILIO] Skipped: not initialized (missing SID/token) to='{}'", to);
            return;
        }
        if (twilioFromNumber == null || twilioFromNumber.isBlank()) {
            log.warn("[SMS-FALLBACK][TWILIO] Skipped: missing fromNumber to='{}'", to);
            return;
        }

        log.info("[SMS-FALLBACK][TWILIO] Sending to='{}' from='{}' msg='{}'",
                to, twilioFromNumber, truncate(message, 140));
        try {
            Message msg = Message.creator(new PhoneNumber(to), new PhoneNumber(twilioFromNumber), message).create();
            log.info("[SMS-FALLBACK][TWILIO] Accepted sid={} status={}", msg.getSid(), msg.getStatus());
        } catch (ApiException e) {
            log.warn("[SMS-FALLBACK][TWILIO] Failed to='{}' code={} msg='{}'", to, e.getCode(), e.getMessage());
            throw e;
        }
    }

    private void initTwilioIfNeeded() {
        if (twilioInitialized) return;
        if (twilioAccountSid == null || twilioAccountSid.isBlank()) return;
        if (twilioAuthToken == null || twilioAuthToken.isBlank()) return;
        Twilio.init(twilioAccountSid, twilioAuthToken);
        twilioInitialized = true;
        log.info("[SMS-FALLBACK][TWILIO] Initialized accountSid={}", maskSid(twilioAccountSid));
    }

    private static String normalizePhone(String phone) {
        if (phone == null) return "";
        String clean = phone.replaceAll("[^+\\d]", "");
        return clean.startsWith("+") ? clean : "+" + clean;
    }

    private static String truncate(String s, int max) {
        if (s == null) return "";
        return s.length() <= max ? s : s.substring(0, max) + "...(truncated)";
    }

    private static String maskSid(String sid) {
        if (sid == null || sid.length() <= 10) return sid;
        return sid.substring(0, 10) + "...";
    }
}
