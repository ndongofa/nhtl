package com.nhtl.controllers;

import com.nhtl.models.Transport;
import com.nhtl.models.TransportStatus;
import com.nhtl.notifications.providers.EmailProvider;
import com.nhtl.notifications.providers.SmsProvider;
import com.nhtl.notifications.providers.WhatsAppProvider;
import com.nhtl.repositories.TransportRepository;
import com.nhtl.services.NotificationService;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

/**
 * PATCH /api/admin/transports/{id}/status
 *
 * Change le statut LOGISTIQUE (statutSuivi) et déclenche les notifications
 * multi-canaux : in-app + SMS + email + WhatsApp.
 *
 * NB : le statut ADMINISTRATIF (statut String) est géré séparément par
 * TransportAdminController sans notifications.
 */
@Slf4j
@RestController
@RequestMapping("/api/admin/transports")
@PreAuthorize("hasRole('ADMIN')")
public class TransportStatusController {

    private final TransportRepository repo;
    private final NotificationService notificationService;
    private final EmailProvider       emailProvider;
    private final SmsProvider         smsProvider;
    private final WhatsAppProvider    whatsAppProvider;

    public TransportStatusController(
            TransportRepository repo,
            NotificationService notificationService,
            EmailProvider       emailProvider,
            SmsProvider         smsProvider,
            WhatsAppProvider    whatsAppProvider) {
        this.repo                = repo;
        this.notificationService = notificationService;
        this.emailProvider       = emailProvider;
        this.smsProvider         = smsProvider;
        this.whatsAppProvider    = whatsAppProvider;
    }

    @PatchMapping("/{id}/status")
    public ResponseEntity<?> updateStatutSuivi(
            @PathVariable Long id,
            @RequestBody  Map<String, String> body) {

        // 1 — Récupérer le transport
        Transport transport = repo.findById(id)
                .orElseThrow(() -> new RuntimeException("Transport introuvable : " + id));

        // 2 — Parser le nouveau statut logistique
        String rawStatus = body.get("status");
        TransportStatus newStatus;
        try {
            newStatus = TransportStatus.valueOf(rawStatus);
        } catch (IllegalArgumentException | NullPointerException e) {
            return ResponseEntity.badRequest().body(Map.of(
                    "error", "Statut logistique invalide : " + rawStatus,
                    "valeurs_acceptees", TransportStatus.values()));
        }

        // 3 — Appliquer
        transport.setStatutSuivi(newStatus);
        repo.save(transport);

        // 4 — Préparer les messages
        String emoji     = emoji(newStatus);
        String label     = label(newStatus);
        String client    = transport.getClientFullName();
        String reference = transport.getReference();
        String userId    = transport.getUserId();
        String message   = buildMessage(client, reference, label, newStatus);
        String subject   = "SAMA — Suivi transport " + reference;

        // 5 — Notif in-app
        try {
            notificationService.create(userId, "TRANSPORT_STATUS",
                    emoji + " " + label, message);
            log.info("[SUIVI] in-app OK transport={} status={}", id, newStatus);
        } catch (Exception e) {
            log.warn("[SUIVI] in-app FAILED transport={}: {}", id, e.getMessage());
        }

        // 6 — SMS
        String phone = transport.getNumeroTelephone();
        if (phone != null && !phone.isBlank()) {
            try {
                smsProvider.sendSms(phone, message);
                log.info("[SUIVI] SMS OK transport={}", id);
            } catch (Exception e) {
                log.warn("[SUIVI] SMS FAILED transport={}: {}", id, e.getMessage());
            }
        }

        // 7 — Email
        String email = transport.getEmail();
        if (email != null && !email.isBlank()) {
            try {
                emailProvider.sendEmail(email, subject, message);
                log.info("[SUIVI] email OK transport={}", id);
            } catch (Exception e) {
                log.warn("[SUIVI] email FAILED transport={}: {}", id, e.getMessage());
            }
        }

        // 8 — WhatsApp
        if (phone != null && !phone.isBlank()) {
            try {
                whatsAppProvider.sendWhatsApp(phone, message);
                log.info("[SUIVI] WhatsApp OK transport={}", id);
            } catch (Exception e) {
                log.warn("[SUIVI] WhatsApp FAILED transport={}: {}", id, e.getMessage());
            }
        }

        log.info("[SUIVI] transport={} → {} (client={})", id, newStatus, client);

        return ResponseEntity.ok(Map.of(
                "success",     true,
                "id",          id,
                "statutSuivi", newStatus.name(),
                "label",       label));
    }

    private String buildMessage(String client, String reference,
                                String label, TransportStatus status) {
        String greeting = (client != null && !client.isBlank())
                ? "Bonjour " + client + ","
                : "Bonjour,";

        String detail = switch (status) {
            case DEPART_CONFIRME   -> "Votre transport a été confirmé pour le prochain départ SAMA.";
            case EN_TRANSIT        -> "Votre colis est en transit vers sa destination.";
            case EN_DOUANE         -> "Votre colis est en traitement douanier. Des délais peuvent survenir.";
            case ARRIVE            -> "Votre colis est arrivé à destination.";
            case PRET_RECUPERATION -> "Votre colis est prêt à être récupéré. Présentez-vous avec une pièce d'identité.";
            case LIVRE             -> "Votre colis a été remis. Merci pour votre confiance !";
            default                -> "Votre transport a été mis à jour.";
        };

        return greeting + "\n\n"
                + "Transport " + reference + "\n"
                + "Nouveau statut : " + label + "\n\n"
                + detail + "\n\n"
                + "Questions ?\n"
                + "• WhatsApp France : +33 76 891 30 74\n"
                + "• WhatsApp Dakar  : +221 78 304 28 38\n\n"
                + "— L'équipe SAMA Services International\n"
                + "sama-services-intl.com";
    }

    private String label(TransportStatus s) {
        return switch (s) {
            case EN_ATTENTE        -> "En attente";
            case DEPART_CONFIRME   -> "Départ confirmé";
            case EN_TRANSIT        -> "En transit";
            case EN_DOUANE         -> "En douane";
            case ARRIVE            -> "Arrivé à destination";
            case PRET_RECUPERATION -> "Prêt à être récupéré";
            case LIVRE             -> "Livré";
        };
    }

    private String emoji(TransportStatus s) {
        return switch (s) {
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