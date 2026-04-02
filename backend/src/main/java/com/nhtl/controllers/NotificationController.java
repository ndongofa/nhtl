package com.nhtl.controllers;

import java.security.Principal;
import java.util.List;
import java.util.Map;

import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.nhtl.dto.NotificationDTO;
import com.nhtl.services.NotificationService;

@RestController
@RequestMapping("/api/notifications")
public class NotificationController {

    private final NotificationService service;

    public NotificationController(NotificationService service) {
        this.service = service;
    }

    private String getUserId(Principal principal) {
        return principal.getName();
    }

    @PreAuthorize("isAuthenticated()")
    @GetMapping
    public ResponseEntity<List<NotificationDTO>> getMyNotifications(Principal principal) {
        return ResponseEntity.ok(service.getForUser(getUserId(principal)));
    }

    @PreAuthorize("isAuthenticated()")
    @PatchMapping("/{id}/read")
    public ResponseEntity<?> markRead(
            @PathVariable Long id, Principal principal) {
        boolean ok = service.markRead(id, getUserId(principal));
        if (!ok) {
            return ResponseEntity.status(403).body(Map.of("error", "Accès refusé"));
        }
        return ResponseEntity.ok(Map.of("success", true));
    }

    /**
     * ✅ DELETE /api/notifications/{id}
     * Supprime une notification par son ID.
     * Vérifie que la notification appartient bien à l'utilisateur connecté.
     */
    @PreAuthorize("isAuthenticated()")
    @DeleteMapping("/{id}")
    public ResponseEntity<?> deleteOne(
            @PathVariable Long id, Principal principal) {
        boolean ok = service.deleteOne(id, getUserId(principal));
        if (!ok) {
            return ResponseEntity.status(403).body(Map.of("error", "Accès refusé ou notification introuvable"));
        }
        return ResponseEntity.ok(Map.of("success", true));
    }

    /**
     * ✅ DELETE /api/notifications
     * Supprime toutes les notifications de l'utilisateur connecté.
     */
    @PreAuthorize("isAuthenticated()")
    @DeleteMapping
    public ResponseEntity<?> deleteAll(Principal principal) {
        service.deleteAll(getUserId(principal));
        return ResponseEntity.ok(Map.of("success", true));
    }
}