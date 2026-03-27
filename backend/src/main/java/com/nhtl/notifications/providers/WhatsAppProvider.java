package com.nhtl.notifications.providers;

public interface WhatsAppProvider {
    void sendWhatsApp(String to, String message);
}