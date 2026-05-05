package com.nhtl.notifications.providers;

public interface WhatsAppProvider {
    void sendWhatsApp(String to, String message);

    /**
     * Sends a WhatsApp message using the admin template (sama_admin_notification).
     * Falls back to the user template when no dedicated admin Content SID is configured.
     */
    default void sendAdminWhatsApp(String to, String message) {
        sendWhatsApp(to, message);
    }
}