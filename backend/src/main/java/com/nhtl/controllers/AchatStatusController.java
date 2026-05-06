package com.nhtl.controllers;

import com.nhtl.models.Achat;
import com.nhtl.models.AchatStatus;
import com.nhtl.notifications.providers.EmailProvider;
import com.nhtl.notifications.providers.SmsProvider;
import com.nhtl.notifications.providers.WhatsAppProvider;
import com.nhtl.repositories.AchatRepository;
import com.nhtl.services.NotificationService;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

/**
 * PATCH /api/admin/achats/{id}/status
 *
 * Change le statut LOGISTIQUE (statutSuivi) d'un achat.
 * Déclenche les notifications : in-app + SMS + email + WhatsApp.
 */
@Slf4j
@RestController
@RequestMapping("/api/admin/achats")
@PreAuthorize("hasRole('ADMIN')")
public class AchatStatusController {

    private final AchatRepository    repo;
    private final NotificationService notificationService;
    private final EmailProvider       emailProvider;
    private final SmsProvider         smsProvider;
    private final WhatsAppProvider    whatsAppProvider;

    public AchatStatusController(
            AchatRepository    repo,
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

        Achat achat = repo.findById(id)
                .orElseThrow(() -> new RuntimeException("Achat introuvable : " + id));

        String rawStatus = body.get("status");
        AchatStatus newStatus;
        try {
            newStatus = AchatStatus.valueOf(rawStatus);
        } catch (IllegalArgumentException | NullPointerException e) {
            return ResponseEntity.badRequest().body(Map.of(
                    "error", "Statut logistique invalide : " + rawStatus,
                    "valeurs_acceptees", AchatStatus.values()));
        }

        achat.setStatutSuivi(newStatus);
        repo.save(achat);

        String emoji     = emoji(newStatus);
        String label     = label(newStatus);
        String client    = achat.getClientFullName();
        String reference = achat.getReference();
        String userId    = achat.getUserId();
        String message   = buildMessage(client, reference, label, newStatus);
        String subject   = "SAMA — Suivi achat " + reference;

        // In-app
        try {
            notificationService.create(userId, "ACHAT_STATUS",
                    emoji + " " + label, message);
            log.info("[SUIVI-ACHAT] in-app OK achat={} status={}", id, newStatus);
        } catch (Exception e) {
            log.warn("[SUIVI-ACHAT] in-app FAILED achat={}: {}", id, e.getMessage());
        }

        // SMS
        String phone = achat.getNumeroTelephone();
        if (phone != null && !phone.isBlank()) {
            try {
                smsProvider.sendSms(phone, message);
                log.info("[SUIVI-ACHAT] SMS OK achat={}", id);
            } catch (Exception e) {
                log.warn("[SUIVI-ACHAT] SMS FAILED achat={}: {}", id, e.getMessage());
            }
        }

        // Email
        String email = achat.getEmail();
        if (email != null && !email.isBlank()) {
            try {
                emailProvider.sendEmail(email, subject, message);
                log.info("[SUIVI-ACHAT] email OK achat={}", id);
            } catch (Exception e) {
                log.warn("[SUIVI-ACHAT] email FAILED achat={}: {}", id, e.getMessage());
            }
        }

        // WhatsApp
        if (phone != null && !phone.isBlank()) {
            try {
                whatsAppProvider.sendWhatsApp(phone, message);
                log.info("[SUIVI-ACHAT] WhatsApp OK achat={}", id);
            } catch (Exception e) {
                log.warn("[SUIVI-ACHAT] WhatsApp FAILED achat={}: {}", id, e.getMessage());
            }
        }

        log.info("[SUIVI-ACHAT] achat={} → {} (client={})", id, newStatus, client);

        return ResponseEntity.ok(Map.of(
                "success",     true,
                "id",          id,
                "statutSuivi", newStatus.name(),
                "label",       label));
    }

    private String buildMessage(String client, String reference,
                                String label, AchatStatus status) {
        String greeting = (client != null && !client.isBlank())
                ? "Bonjour " + client + ","
                : "Bonjour,";

        String detail = switch (status) {
            case ACHAT_CONFIRME  -> "Votre demande d'achat a été validée et est prise en charge par notre équipe.";
            case ACHAT_EFFECTUE  -> "Le produit a été trouvé et acheté par notre agent. Il sera bientôt expédié.";
            case EN_TRANSIT      -> "Votre colis est en transit vers sa destination.";
            case ARRIVE          -> "Votre colis est arrivé à notre entrepôt. La livraison finale est en cours d'organisation.";
            case PRET_LIVRAISON  -> "Votre colis est prêt à être livré. Vous serez contacté très prochainement.";
            case LIVRE           -> "Votre achat a été livré. Merci pour votre confiance !";
            default              -> "Votre demande d'achat a été mise à jour.";
        };

        return greeting + "\n\n"
                + "Achat " + reference + "\n"
                + "Nouveau statut : " + label + "\n\n"
                + detail + "\n\n"
                + "Questions ?\n"
                + "• WhatsApp France : +33 76 891 30 74\n"
                + "• WhatsApp Dakar  : +221 78 304 28 38\n\n"
                + "— L'équipe SAMA Services International\n"
                + "sama-services-intl.com";
    }

    private String label(AchatStatus s) {
        return switch (s) {
            case EN_ATTENTE     -> "En attente";
            case ACHAT_CONFIRME -> "Achat confirmé";
            case ACHAT_EFFECTUE -> "Achat effectué";
            case EN_TRANSIT     -> "En transit";
            case ARRIVE         -> "Arrivé à l'entrepôt";
            case PRET_LIVRAISON -> "Prêt à être livré";
            case LIVRE          -> "Livré";
        };
    }

    private String emoji(AchatStatus s) {
        return switch (s) {
            case EN_ATTENTE     -> "⏳";
            case ACHAT_CONFIRME -> "✅";
            case ACHAT_EFFECTUE -> "🛒";
            case EN_TRANSIT     -> "🚚";
            case ARRIVE         -> "📍";
            case PRET_LIVRAISON -> "📦";
            case LIVRE          -> "🎉";
        };
    }
}
