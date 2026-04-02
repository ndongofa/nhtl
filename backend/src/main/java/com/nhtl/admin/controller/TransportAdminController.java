package com.nhtl.admin.controller;

import com.nhtl.dto.TransportDTO;
import com.nhtl.services.TransportService;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

/**
 * Endpoints admin pour les transports.
 * GET /api/admin/transports        → tous les transports
 * GET /api/admin/transports/{id}   → un transport par ID (avec champs postaux)
 * PATCH /api/admin/transports/{id}/statut → statut administratif
 */
@Slf4j
@RestController
@RequestMapping("/api/admin/transports")
@PreAuthorize("hasRole('ADMIN')")
public class TransportAdminController {

    private final TransportService transportService;

    public TransportAdminController(TransportService transportService) {
        this.transportService = transportService;
    }

    // ── GET tous ──────────────────────────────────────────────────────────────

    @GetMapping
    public ResponseEntity<List<TransportDTO>> getAll() {
        return ResponseEntity.ok(transportService.getAllTransports());
    }

    @GetMapping("/all")
    public ResponseEntity<List<TransportDTO>> getAllAlt() {
        return ResponseEntity.ok(transportService.getAllTransports());
    }

    // ── GET par ID ────────────────────────────────────────────────────────────
    // ✅ Retourne le DTO complet incluant photoColisUrl, deposePosteAt, statutSuivi

    @GetMapping("/{id}")
    public ResponseEntity<?> getById(@PathVariable Long id) {
        return transportService.getTransportByIdAndAdmin(id)
                .<ResponseEntity<?>>map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    // ── Archives ──────────────────────────────────────────────────────────────

    @GetMapping("/archives")
    public ResponseEntity<List<TransportDTO>> getArchives() {
        return ResponseEntity.ok(transportService.getTransportsArchives());
    }

    // ── PATCH statut administratif ────────────────────────────────────────────

    @PatchMapping("/{id}/statut")
    public ResponseEntity<?> updateStatut(
            @PathVariable Long id,
            @RequestBody Map<String, String> body) {
        String statut = body.get("statut");
        TransportDTO updated = transportService.updateStatut(id, statut);
        if (updated == null) return ResponseEntity.notFound().build();
        return ResponseEntity.ok(updated);
    }

    // ── Archive / Désarchive ──────────────────────────────────────────────────

    @PatchMapping("/{id}/archive")
    public ResponseEntity<?> archive(@PathVariable Long id) {
        boolean ok = transportService.archiveTransport(id);
        return ok ? ResponseEntity.ok(Map.of("success", true))
                  : ResponseEntity.badRequest().body(Map.of("error", "Déjà archivé ou introuvable"));
    }

    @PatchMapping("/{id}/unarchive")
    public ResponseEntity<?> unarchive(@PathVariable Long id) {
        boolean ok = transportService.unarchiveTransport(id);
        return ok ? ResponseEntity.ok(Map.of("success", true))
                  : ResponseEntity.badRequest().body(Map.of("error", "Non archivé ou introuvable"));
    }

    // ── Suppression ───────────────────────────────────────────────────────────

    @DeleteMapping("/{id}")
    public ResponseEntity<?> delete(@PathVariable Long id) {
        boolean ok = transportService.deleteTransportAdmin(id);
        return ok ? ResponseEntity.ok(Map.of("success", true))
                  : ResponseEntity.notFound().build();
    }

    // ── Recherche par statut ──────────────────────────────────────────────────

    @GetMapping("/search/statut")
    public ResponseEntity<List<TransportDTO>> searchByStatut(
            @RequestParam String statut) {
        return ResponseEntity.ok(transportService.searchByStatut(statut));
    }
}