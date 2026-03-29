package com.nhtl.controllers;

import com.nhtl.models.Commande;
import com.nhtl.models.CommandeStatus;
import com.nhtl.notifications.providers.EmailProvider;
import com.nhtl.notifications.providers.SmsProvider;
import com.nhtl.notifications.providers.WhatsAppProvider;
import com.nhtl.repositories.CommandeRepository;
import com.nhtl.services.NotificationService;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

/**
 * PATCH /api/admin/commandes/{id}/status
 *
 * Change le statut LOGISTIQUE (statutSuivi) d'une commande.
 * Déclenche les notifications : in-app + SMS + email + WhatsApp.
 */
@Slf4j
@RestController
@RequestMapping("/api/admin/commandes")
@PreAuthorize("hasRole('ADMIN')")
public class CommandeStatusController {

    private final CommandeRepository  repo;
    private final NotificationService notificationService;
    private final EmailProvider       emailProvider;
    private final SmsProvider         smsProvider;
    private final WhatsAppProvider    whatsAppProvider;

    public CommandeStatusController(
            CommandeRepository  repo,
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

        Commande commande = repo.findById(id)
                .orElseThrow(() -> new RuntimeException("Commande introuvable : " + id));

        String rawStatus = body.get("status");
        CommandeStatus newStatus;
        try {
            newStatus = CommandeStatus.valueOf(rawStatus);
        } catch (IllegalArgumentException | NullPointerException e) {
            return ResponseEntity.badRequest().body(Map.of(
                    "error", "Statut logistique invalide : " + rawStatus,
                    "valeurs_acceptees", CommandeStatus.values()));
        }

        commande.setStatutSuivi(newStatus);
        repo.save(commande);

        String emoji     = emoji(newStatus);
        String label     = label(newStatus);
        String client    = commande.getClientFullName();
        String reference = commande.getReference();
        String userId    = commande.getUserId();
        String message   = buildMessage(client, reference, label, newStatus);
        String subject   = "SAMA — Suivi commande " + reference;

        // In-app
        try {
            notificationService.create(userId, "COMMANDE_STATUS",
                    emoji + " " + label, message);
            log.info("[SUIVI-CMD] in-app OK commande={} status={}", id, newStatus);
        } catch (Exception e) {
            log.warn("[SUIVI-CMD] in-app FAILED commande={}: {}", id, e.getMessage());
        }

        // SMS
        String phone = commande.getNumeroTelephone();
        if (phone != null && !phone.isBlank()) {
            try {
                smsProvider.sendSms(phone, message);
                log.info("[SUIVI-CMD] SMS OK commande={}", id);
            } catch (Exception e) {
                log.warn("[SUIVI-CMD] SMS FAILED commande={}: {}", id, e.getMessage());
            }
        }

        // Email
        String email = commande.getEmail();
        if (email != null && !email.isBlank()) {
            try {
                emailProvider.sendEmail(email, subject, message);
                log.info("[SUIVI-CMD] email OK commande={}", id);
            } catch (Exception e) {
                log.warn("[SUIVI-CMD] email FAILED commande={}: {}", id, e.getMessage());
            }
        }

        // WhatsApp
        if (phone != null && !phone.isBlank()) {
            try {
                whatsAppProvider.sendWhatsApp(phone, message);
                log.info("[SUIVI-CMD] WhatsApp OK commande={}", id);
            } catch (Exception e) {
                log.warn("[SUIVI-CMD] WhatsApp FAILED commande={}: {}", id, e.getMessage());
            }
        }

        log.info("[SUIVI-CMD] commande={} → {} (client={})", id, newStatus, client);

        return ResponseEntity.ok(Map.of(
                "success",     true,
                "id",          id,
                "statutSuivi", newStatus.name(),
                "label",       label));
    }

    private String buildMessage(String client, String reference,
                                String label, CommandeStatus status) {
        String greeting = (client != null && !client.isBlank())
                ? "Bonjour " + client + ","
                : "Bonjour,";

        String detail = switch (status) {
            case COMMANDE_CONFIRMEE -> "Votre commande a été passée sur la plateforme. Elle est en cours de préparation.";
            case EN_TRANSIT        -> "Votre colis est en transit vers sa destination.";
            case EN_DOUANE         -> "Votre colis est en traitement douanier.";
            case ARRIVE            -> "Votre colis est arrivé à notre entrepôt. La livraison finale est en cours d'organisation.";
            case PRET_LIVRAISON    -> "Votre colis est prêt à être livré. Vous serez contacté très prochainement.";
            case LIVREE             -> "Votre commande a été livrée. Merci pour votre confiance !";
            default                -> "Votre commande a été mise à jour.";
        };

        return greeting + "\n\n"
                + "Commande " + reference + "\n"
                + "Nouveau statut : " + label + "\n\n"
                + detail + "\n\n"
                + "Questions ?\n"
                + "• WhatsApp France : +33 76 891 30 74\n"
                + "• WhatsApp Dakar  : +221 78 304 28 38\n\n"
                + "— L'équipe SAMA Services International\n"
                + "sama-services-intl.com";
    }

    private String label(CommandeStatus s) {
        return switch (s) {
            case EN_ATTENTE        -> "En attente";
            case COMMANDE_CONFIRMEE -> "Commande confirmée";
            case EN_TRANSIT        -> "En transit";
            case EN_DOUANE         -> "En douane";
            case ARRIVE            -> "Arrivé à l'entrepôt";
            case PRET_LIVRAISON    -> "Prêt à être livré";
            case LIVREE             -> "Livré";
        };
    }

    private String emoji(CommandeStatus s) {
        return switch (s) {
            case EN_ATTENTE        -> "⏳";
            case COMMANDE_CONFIRMEE -> "🛒";
            case EN_TRANSIT        -> "🚚";
            case EN_DOUANE         -> "🛃";
            case ARRIVE            -> "📍";
            case PRET_LIVRAISON    -> "📦";
            case LIVREE             -> "🎉";
        };
    }
}