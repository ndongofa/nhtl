package com.nhtl.notifications.providers;

import org.springframework.context.annotation.Profile;
import org.springframework.stereotype.Component;
import lombok.extern.slf4j.Slf4j;

@Slf4j
@Component
@Profile({ "default", "dev" })
public class StubWhatsAppProvider implements WhatsAppProvider {

    @Override
    public void sendWhatsApp(String to, String message) {
        if (to == null || to.isBlank()) return;
        log.info("[WHATSAPP-STUB] to={} message={}", to, message);
    }
}