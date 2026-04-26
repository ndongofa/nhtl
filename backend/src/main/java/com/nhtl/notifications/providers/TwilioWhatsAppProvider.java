package com.nhtl.notifications.providers;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Profile;
import org.springframework.stereotype.Component;
import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
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

    /**
     * Twilio Content API SID (starts with HX…) for a Meta-approved WhatsApp Business message template.
     * Required for business-initiated messages sent outside the 24-hour customer service window.
     *
     * How to obtain:
     *   1. Go to Twilio Console → Content Template Builder and create a template
     *      with a single variable {{1}} that will contain the notification text.
     *   2. Submit the template to Meta for approval (category: UTILITY).
     *   3. Once approved, copy the Content SID (HX…) and set it as TWILIO_WHATSAPP_CONTENT_SID.
     *
     * Leave blank to use free-form text (Twilio sandbox only or within the 24-hour service window).
     */
    @Value("${twilio.whatsapp.contentSid:}")
    private String contentSid;

    private volatile boolean initialized = false;
    private static final ObjectMapper OBJECT_MAPPER = new ObjectMapper();

    private synchronized void initIfNeeded() {
        if (initialized) return;
        if (accountSid == null || accountSid.isBlank()) return;
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

        boolean useTemplate = contentSid != null && !contentSid.isBlank();
        if (useTemplate) {
            log.info("[TWILIO-WA] Sending to='{}' from='{}' template='{}' msg='{}'",
                    waTo, fromNumber, contentSid, truncate(message, 140));
        } else {
            log.warn("[TWILIO-WA] Sending FREE-FORM WhatsApp to='{}' – TWILIO_WHATSAPP_CONTENT_SID is not set. "
                    + "Free-form messages require the recipient to be inside the 24-hour reply window or Twilio sandbox. "
                    + "If delivery fails, SMS fallback will be attempted automatically.",
                    waTo);
        }

        try {
            Message msg;
            if (useTemplate) {
                // Business-initiated message via Meta-approved Content Template.
                // Variable {{1}} in the template is replaced with the notification text.
                String variables = buildContentVariables(message);
                msg = Message.creator(new PhoneNumber(waTo), new PhoneNumber(fromNumber), "")
                        .setContentSid(contentSid)
                        .setContentVariables(variables)
                        .create();
            } else {
                // Free-form text — Twilio sandbox or within the 24-hour customer service window.
                msg = Message.creator(new PhoneNumber(waTo), new PhoneNumber(fromNumber), message)
                        .create();
            }
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

    /**
     * Builds the ContentVariables JSON string for the Twilio Content API.
     * Uses Jackson to ensure all control characters are properly escaped.
     * Format: {"1": "<message>"}
     */
    private static String buildContentVariables(String message) {
        try {
            return "{\"1\":" + OBJECT_MAPPER.writeValueAsString(message == null ? "" : message) + "}";
        } catch (JsonProcessingException e) {
            // Should never happen for a plain String; fall back to a safe empty value.
            return "{\"1\":\"\"}";
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