package com.nhtl.controllers;

import com.nhtl.models.Commande;
import com.nhtl.models.Transport;
import com.nhtl.models.TransportStatus;
import com.nhtl.models.CommandeStatus;
import com.nhtl.notifications.providers.EmailProvider;
import com.nhtl.notifications.providers.SmsProvider;
import com.nhtl.notifications.providers.WhatsAppProvider;
import com.nhtl.repositories.CommandeRepository;
import com.nhtl.repositories.TransportRepository;
import com.nhtl.services.NotificationService;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.util.Map;

/**
 * Suivi postal — dépôt à la poste avec photos.
 *
 * PATCH /api/admin/transports/{id}/postal
 * PATCH /api/admin/commandes/{id}/postal
 *
 * Corps attendu :
 * {
 *   "photoColisUrl":     "https://...",
 *   "photoBordereauUrl": "https://...",
 *   "numeroBordereau":   "3C12345678FR"
 * }
 *
 * Effets :
 * - Enregistre les URLs et le numéro de bordereau
 * - Met le statutSuivi à PRET_RECUPERATION (transport) / PRET_LIVRAISON (commande)
 * - Envoie notifications in-app + SMS + email + WhatsApp
 */
@Slf4j
@RestController
@PreAuthorize("hasRole('ADMIN')")
public class PostalTrackingController {

    private final TransportRepository  transportRepo;
    private final CommandeRepository   commandeRepo;
    private final NotificationService  notifService;
    private final SmsProvider          smsProvider;
    private final EmailProvider        emailProvider;
    private final WhatsAppProvider     whatsAppProvider;

    public PostalTrackingController(
            TransportRepository  transportRepo,
            CommandeRepository   commandeRepo,
            NotificationService  notifService,
            SmsProvider          smsProvider,
            EmailProvider        emailProvider,
            WhatsAppProvider     whatsAppProvider) {
        this.transportRepo   = transportRepo;
        this.commandeRepo    = commandeRepo;
        this.notifService    = notifService;
        this.smsProvider     = smsProvider;
        this.emailProvider   = emailProvider;
        this.whatsAppProvider = whatsAppProvider;
    }

    // ── TRANSPORT ─────────────────────────────────────────────────────────────

    @PatchMapping("/api/admin/transports/{id}/postal")
    public ResponseEntity<?> postalTransport(
            @PathVariable Long id,
            @RequestBody  Map<String, String> body) {

        return transportRepo.findById(id).map(t -> {
            // 1 — Enregistrer les infos postales
            t.setPhotoColisUrl(body.get("photoColisUrl"));
            t.setPhotoBordereauUrl(body.get("photoBordereauUrl"));
            t.setNumeroBordereau(body.getOrDefault("numeroBordereau", ""));
            t.setDeposePosteAt(LocalDateTime.now());

            // 2 — Faire avancer le statut logistique → PRET_RECUPERATION
            t.setStatutSuivi(TransportStatus.PRET_RECUPERATION);
            transportRepo.save(t);

            // 3 — Notifications
            String client    = t.getClientFullName();
            String reference = t.getReference();
            String bordereau = t.getNumeroBordereau();
            String message   = buildMessageTransport(client, reference, bordereau);
            String subject   = "SAMA — Votre colis est en route ! " + reference;

            notify(t.getUserId(), "📬 Colis déposé à la poste",
                    message, subject, t.getNumeroTelephone(), t.getEmail(), "transport", id);

            log.info("[POSTAL] Transport {} déposé à la poste — bordereau={}",
                    id, bordereau);

            return ResponseEntity.ok(Map.of(
                    "success",          true,
                    "id",               id,
                    "statutSuivi",      "PRET_RECUPERATION",
                    "numeroBordereau",  bordereau,
                    "deposePosteAt",    t.getDeposePosteAt().toString()));
        }).orElse(ResponseEntity.notFound().build());
    }

    // ── COMMANDE ──────────────────────────────────────────────────────────────

    @PatchMapping("/api/admin/commandes/{id}/postal")
    public ResponseEntity<?> postalCommande(
            @PathVariable Long id,
            @RequestBody  Map<String, String> body) {

        return commandeRepo.findById(id).map(c -> {
            // 1 — Enregistrer les infos postales
            c.setPhotoColisUrl(body.get("photoColisUrl"));
            c.setPhotoBordereauUrl(body.get("photoBordereauUrl"));
            c.setNumeroBordereau(body.getOrDefault("numeroBordereau", ""));
            c.setDeposePosteAt(LocalDateTime.now());

            // 2 — Faire avancer le statut logistique → PRET_LIVRAISON
            c.setStatutSuivi(CommandeStatus.PRET_LIVRAISON);
            commandeRepo.save(c);

            // 3 — Notifications
            String client    = c.getClientFullName();
            String reference = c.getReference();
            String bordereau = c.getNumeroBordereau();
            String message   = buildMessageCommande(client, reference, bordereau);
            String subject   = "SAMA — Votre commande est en route ! " + reference;

            notify(c.getUserId(), "📬 Colis déposé à la poste",
                    message, subject, c.getNumeroTelephone(), c.getEmail(), "commande", id);

            log.info("[POSTAL] Commande {} déposée à la poste — bordereau={}",
                    id, bordereau);

            return ResponseEntity.ok(Map.of(
                    "success",          true,
                    "id",               id,
                    "statutSuivi",      "PRET_LIVRAISON",
                    "numeroBordereau",  bordereau,
                    "deposePosteAt",    c.getDeposePosteAt().toString()));
        }).orElse(ResponseEntity.notFound().build());
    }

    // ── Helpers ───────────────────────────────────────────────────────────────

    private void notify(String userId, String title, String message,
                        String subject, String phone, String email,
                        String type, Long id) {
        // In-app
        try {
            notifService.create(userId, type.toUpperCase() + "_POSTAL", title, message);
        } catch (Exception e) {
            log.warn("[POSTAL] in-app failed {}/{}: {}", type, id, e.getMessage());
        }
        // SMS
        if (phone != null && !phone.isBlank()) {
            try { smsProvider.sendSms(phone, message); }
            catch (Exception e) { log.warn("[POSTAL] SMS failed: {}", e.getMessage()); }
        }
        // Email
        if (email != null && !email.isBlank()) {
            try { emailProvider.sendEmail(email, subject, message); }
            catch (Exception e) { log.warn("[POSTAL] email failed: {}", e.getMessage()); }
        }
        // WhatsApp
        if (phone != null && !phone.isBlank()) {
            try { whatsAppProvider.sendWhatsApp(phone, message); }
            catch (Exception e) { log.warn("[POSTAL] WhatsApp failed: {}", e.getMessage()); }
        }
    }

    private String buildMessageTransport(String client, String reference,
                                          String bordereau) {
        String g = (client != null && !client.isBlank())
                ? "Bonjour " + client + "," : "Bonjour,";
        String b = (bordereau != null && !bordereau.isBlank())
                ? "\nNuméro de suivi postal : " + bordereau : "";
        return g + "\n\n"
                + "📬 Votre colis " + reference + " a été déposé à la poste "
                + "et est en cours de livraison vers votre domicile." + b + "\n\n"
                + "Vous pouvez suivre votre colis directement sur l'application SAMA.\n\n"
                + "Questions ?\n"
                + "• WhatsApp France : +33 76 891 30 74\n"
                + "• WhatsApp Dakar  : +221 78 304 28 38\n\n"
                + "— L'équipe SAMA Services International\n"
                + "sama-services-intl.com";
    }

    private String buildMessageCommande(String client, String reference,
                                         String bordereau) {
        String g = (client != null && !client.isBlank())
                ? "Bonjour " + client + "," : "Bonjour,";
        String b = (bordereau != null && !bordereau.isBlank())
                ? "\nNuméro de suivi postal : " + bordereau : "";
        return g + "\n\n"
                + "📬 Votre commande " + reference + " a été déposée à la poste "
                + "et est en cours de livraison vers votre domicile." + b + "\n\n"
                + "Vous pouvez suivre votre commande directement sur l'application SAMA.\n\n"
                + "Questions ?\n"
                + "• WhatsApp France : +33 76 891 30 74\n"
                + "• WhatsApp Dakar  : +221 78 304 28 38\n\n"
                + "— L'équipe SAMA Services International\n"
                + "sama-services-intl.com";
    }
}