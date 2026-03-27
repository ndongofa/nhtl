package com.nhtl.notifications.providers;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Profile;
import org.springframework.stereotype.Component;
import com.twilio.Twilio;
import com.twilio.exception.ApiException;
import com.twilio.rest.api.v2010.account.Message;
import com.twilio.type.PhoneNumber;
import lombok.extern.slf4j.Slf4j;

@Slf4j
@Component
@Profile("prod")
public class TwilioWhatsAppProvider implements WhatsAppProvider {

    @Value("${twilio.accountSid:}")
    private String accountSid;

    @Value("${twilio.authToken:}")
    private String authToken;

    @Value("${twilio.whatsapp.fromNumber:whatsapp:+14155238886}")
    private String fromNumber;

    private volatile boolean initialized = false;

    private void initIfNeeded() {
        if (initialized || accountSid == null || accountSid.isBlank()) return;
        if (authToken == null || authToken.isBlank()) return;
        Twilio.init(accountSid, authToken);
        initialized = true;
        log.info("[TWILIO-WA] Initialized accountSid={}", maskSid(accountSid));
    }

    @Override
    public void sendWhatsApp(String to, String message) {
        if (to == null || to.isBlank()) {
            log.info("[TWILIO-WA] Skipped: empty recipient");
            return;
        }
        if (message == null || message.isBlank()) return;

        initIfNeeded();
        if (!initialized) {
            log.warn("[TWILIO-WA] Skipped: not initialized (missing SID/token) to='{}'", to);
            return;
        }

        String waTo = to.startsWith("whatsapp:") ? to : "whatsapp:" + normalizePhone(to);

        log.info("[TWILIO-WA] Sending to='{}' from='{}' msg='{}'",
                waTo, fromNumber, truncate(message, 140));
        try {
            Message msg = Message.creator(
                    new PhoneNumber(waTo),
                    new PhoneNumber(fromNumber),
                    message
            ).create();
            log.info("[TWILIO-WA] Accepted sid={} status={}", msg.getSid(), msg.getStatus());
        } catch (ApiException e) {
            log.warn("[TWILIO-WA] Failed to='{}' code={} msg='{}'",
                    waTo, e.getCode(), e.getMessage());
            throw e;
        } catch (Exception e) {
            log.warn("[TWILIO-WA] Failed to='{}' err='{}'", waTo, e.getMessage());
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

    private static String maskSid(String sid) {
        if (sid == null || sid.length() <= 10) return sid;
        return sid.substring(0, 10) + "...";
    }
}