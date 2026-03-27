package com.nhtl.controllers;

import java.util.Map;

import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.nhtl.models.Transport;
import com.nhtl.models.StatutTransport;
import com.nhtl.notifications.providers.EmailProvider;
import com.nhtl.notifications.providers.SmsProvider;
import com.nhtl.notifications.providers.WhatsAppProvider;
import com.nhtl.repositories.TransportRepository;
import com.nhtl.services.NotificationService;

import lombok.extern.slf4j.Slf4j;

/**
 * PATCH /api/admin/transports/{id}/status
 * Corps : { "status": "EN_TRANSIT" }
 *
 * ✅ Admin uniquement
 * ✅ Notif in-app  (NotificationService existant)
 * ✅ SMS           (TwilioSmsProvider existant)
 * ✅ Email         (BrevoApiEmailProvider existant)
 * ✅ WhatsApp      (TwilioWhatsAppProvider nouveau)
 *
 * Chaque canal est isolé dans un try/catch :
 * un canal qui échoue n'arrête pas les autres.
 */
@Slf4j
@RestController
@RequestMapping("/api/admin/transports")
@PreAuthorize("hasRole('ADMIN')")
public class TransportStatusController {

    private final TransportRepository transportRepository;
    private final NotificationService notificationService;
    private final EmailProvider       emailProvider;
    private final SmsProvider         smsProvider;
    private final WhatsAppProvider    whatsAppProvider;

    public TransportStatusController(
            TransportRepository transportRepository,
            NotificationService notificationService,
            EmailProvider       emailProvider,
            SmsProvider         smsProvider,
            WhatsAppProvider    whatsAppProvider) {
        this.transportRepository = transportRepository;
        this.notificationService = notificationService;
        this.emailProvider       = emailProvider;
        this.smsProvider         = smsProvider;
        this.whatsAppProvider    = whatsAppProvider;
    }

    @PatchMapping("/{id}/status")
    public ResponseEntity<?> updateStatus(
            @PathVariable Long id,
            @RequestBody  Map<String, String> body) {

        // 1 — Récupérer le transport
        Transport transport = transportRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Transport introuvable : " + id));

        // 2 — Parser le nouveau statut
        String rawStatus = body.get("status");
        StatutTransport newStatus;
        try {
            newStatus = StatutTransport.valueOf(rawStatus);
        } catch (IllegalArgumentException | NullPointerException e) {
            return ResponseEntity.badRequest().body(Map.of(
                    "error", "Statut invalide : " + rawStatus,
                    "valeurs_acceptees", StatutTransport.values()));
        }

        // 3 — Appliquer et sauvegarder
        transport.setStatutSuivi(newStatus);
        transportRepository.save(transport);

        // 4 — Préparer le contenu
        String emoji     = statusEmoji(newStatus);
        String label     = statusLabel(newStatus);
        String client    = transport.getClientFullName();
        String reference = transport.getReference();
        String userId    = transport.getUserId();
        String message   = buildMessage(client, reference, label, newStatus);
        String subject   = "SAMA — Mise à jour transport " + reference;

        // 5 — ✅ Notif in-app (NotificationService existant)
        try {
            notificationService.create(userId, "TRANSPORT_STATUS",
                    emoji + " " + label, message);
            log.info("[STATUS] in-app OK userId={} transport={} status={}", userId, id, newStatus);
        } catch (Exception e) {
            log.warn("[STATUS] in-app FAILED transport={}: {}", id, e.getMessage());
        }

        // 6 — ✅ SMS (TwilioSmsProvider existant)
        String phone = transport.getNumeroTelephone();
        if (phone != null && !phone.isBlank()) {
            try {
                smsProvider.sendSms(phone, message);
                log.info("[STATUS] SMS OK transport={} phone={}", id, phone);
            } catch (Exception e) {
                log.warn("[STATUS] SMS FAILED transport={} phone={}: {}", id, phone, e.getMessage());
            }
        }

        // 7 — ✅ Email (BrevoApiEmailProvider existant)
        String email = transport.getEmail();
        if (email != null && !email.isBlank()) {
            try {
                emailProvider.sendEmail(email, subject, message);
                log.info("[STATUS] email OK transport={} email={}", id, email);
            } catch (Exception e) {
                log.warn("[STATUS] email FAILED transport={} email={}: {}", id, email, e.getMessage());
            }
        }

        // 8 — ✅ WhatsApp (TwilioWhatsAppProvider nouveau)
        if (phone != null && !phone.isBlank()) {
            try {
                whatsAppProvider.sendWhatsApp(phone, message);
                log.info("[STATUS] WhatsApp OK transport={} phone={}", id, phone);
            } catch (Exception e) {
                log.warn("[STATUS] WhatsApp FAILED transport={} phone={}: {}", id, phone, e.getMessage());
            }
        }

        log.info("[STATUS] transport={} → {} channels: in-app+sms+email+whatsapp client={}",
                id, newStatus, client);

        return ResponseEntity.ok(Map.of(
                "success", true,
                "id",      id,
                "status",  newStatus.name(),
                "label",   label
        ));
    }

    // ── Messages personnalisés par étape ──────────────────────────────────

    private String buildMessage(String client, String reference,
                                 String label, StatutTransport status) {
        String greeting = (client != null && !client.isBlank())
                ? "Bonjour " + client + ","
                : "Bonjour,";

        String detail = switch (status) {
            case DEPART_CONFIRME   -> "Votre transport a été confirmé et sera pris en charge lors du prochain départ SAMA.";
            case EN_TRANSIT        -> "Votre colis est actuellement en transit vers sa destination.";
            case EN_DOUANE         -> "Votre colis est en cours de traitement douanier. Des délais supplémentaires peuvent survenir.";
            case ARRIVE            -> "Votre colis est arrivé à destination. Vous serez contacté pour les modalités de récupération.";
            case PRET_RECUPERATION -> "Votre colis est disponible et prêt à être récupéré. Présentez-vous muni de votre pièce d'identité.";
            case LIVRE             -> "Votre colis a bien été remis. Merci de votre confiance !";
            default                -> "Votre transport a été mis à jour.";
        };

        return greeting + "\n\n"
                + "Transport " + reference + "\n"
                + "Statut : " + label + "\n\n"
                + detail + "\n\n"
                + "Questions ?\n"
                + "• WhatsApp France : +33 76 891 30 74\n"
                + "• WhatsApp Dakar  : +221 78 304 28 38\n\n"
                + "— L'équipe SAMA Services International\n"
                + "sama-services-intl.com";
    }

    private String statusLabel(StatutTransport status) {
        return switch (status) {
            case EN_ATTENTE        -> "En attente";
            case DEPART_CONFIRME   -> "Départ confirmé";
            case EN_TRANSIT        -> "En transit";
            case EN_DOUANE         -> "En douane";
            case ARRIVE            -> "Arrivé à destination";
            case PRET_RECUPERATION -> "Prêt à être récupéré";
            case LIVRE             -> "Livré";
        };
    }

    private String statusEmoji(StatutTransport status) {
        return switch (status) {
            case EN_ATTENTE        -> "⏳";
            case DEPART_CONFIRME   -> "✅";
            case EN_TRANSIT        -> "🚚";
            case EN_DOUANE         -> "🛃";
            case ARRIVE            -> "📍";
            case PRET_RECUPERATION -> "📦";
            case LIVRE             -> "🎉";
        };
    }
}