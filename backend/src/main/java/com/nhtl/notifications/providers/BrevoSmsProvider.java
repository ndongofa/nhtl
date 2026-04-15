package com.nhtl.notifications.providers;

import java.util.HashMap;
import java.util.Map;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Profile;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Component;
import org.springframework.web.client.HttpStatusCodeException;
import org.springframework.web.client.RestTemplate;

import lombok.extern.slf4j.Slf4j;

@Slf4j
@Component
@Profile("brevo-sms")
public class BrevoSmsProvider implements SmsProvider {

    private static final String BREVO_SMS_URL = "https://api.brevo.com/v3/transactionalSMS/sms";

    private final RestTemplate restTemplate = new RestTemplate();

    @Value("${brevo.apiKey:}")
    private String apiKey;

    @Value("${brevo.sms.from:SamaService}")
    private String senderName;

    @Override
    public void sendSms(String to, String message) {
        if (to == null || to.isBlank()) {
            log.info("[BREVO-SMS] Skipped: empty recipient");
            return;
        }
        if (message == null || message.isBlank()) {
            log.info("[BREVO-SMS] Skipped: empty message to='{}'", to);
            return;
        }
        if (apiKey == null || apiKey.isBlank()) {
            log.warn("[BREVO-SMS] Skipped: missing Brevo API key to='{}'", to);
            return;
        }

        String recipient = normalizePhone(to);

        log.info("[BREVO-SMS] Sending to='{}' sender='{}' msg='{}'", recipient, senderName, truncate(message, 140));

        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_JSON);
        headers.set("api-key", apiKey);

        Map<String, Object> payload = new HashMap<>();
        payload.put("sender", senderName);
        payload.put("recipient", recipient);
        payload.put("content", message);
        payload.put("type", "transactional");

        HttpEntity<Map<String, Object>> req = new HttpEntity<>(payload, headers);

        try {
            ResponseEntity<String> resp = restTemplate.postForEntity(BREVO_SMS_URL, req, String.class);
            log.info("[BREVO-SMS] Accepted status={} to='{}'", resp.getStatusCode().value(), recipient);
        } catch (HttpStatusCodeException e) {
            String responseBody = e.getResponseBodyAsString();
            log.warn("[BREVO-SMS] Failed status={} to='{}' response='{}'",
                    e.getStatusCode().value(), recipient, truncate(responseBody, 800));
            throw e;
        } catch (Exception e) {
            log.warn("[BREVO-SMS] Failed to='{}' err='{}'", recipient, e.getMessage());
            throw e;
        }
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
}
