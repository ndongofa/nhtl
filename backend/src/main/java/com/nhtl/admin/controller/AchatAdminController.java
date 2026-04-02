package com.nhtl.admin.controller;

import com.nhtl.dto.AchatDTO;
import com.nhtl.services.AchatService;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

/**
 * Endpoints admin pour les achats.
 * GET /api/admin/achats        → tous les achats
 * GET /api/admin/achats/{id}   → un achat par ID (avec champs postaux)
 * PATCH /api/admin/achats/{id}/statut → statut administratif
 */
@Slf4j
@RestController
@RequestMapping("/api/admin/achats")
@PreAuthorize("hasRole('ADMIN')")
public class AchatAdminController {

    private final AchatService achatService;

    public AchatAdminController(AchatService achatService) {
        this.achatService = achatService;
    }

    // ── GET tous ──────────────────────────────────────────────────────────────

    @GetMapping
    public ResponseEntity<List<AchatDTO>> getAll() {
        return ResponseEntity.ok(achatService.getAllAchats());
    }

    @GetMapping("/all")
    public ResponseEntity<List<AchatDTO>> getAllAlt() {
        return ResponseEntity.ok(achatService.getAllAchats());
    }

    // ── GET par ID ────────────────────────────────────────────────────────────

    @GetMapping("/{id}")
    public ResponseEntity<?> getById(@PathVariable Long id) {
        return achatService.getAchatByIdAndAdmin(id)
                .<ResponseEntity<?>>map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    // ── Archives ──────────────────────────────────────────────────────────────

    @GetMapping("/archives")
    public ResponseEntity<List<AchatDTO>> getArchives() {
        return ResponseEntity.ok(achatService.getAchatsArchives());
    }

    // ── PATCH statut administratif ────────────────────────────────────────────

    @PatchMapping("/{id}/statut")
    public ResponseEntity<?> updateStatut(
            @PathVariable Long id,
            @RequestBody Map<String, String> body) {
        String statut = body.get("statut");
        AchatDTO updated = achatService.updateStatut(id, statut);
        if (updated == null) return ResponseEntity.notFound().build();
        return ResponseEntity.ok(updated);
    }

    // ── Archive / Désarchive ──────────────────────────────────────────────────

    @PatchMapping("/{id}/archive")
    public ResponseEntity<?> archive(@PathVariable Long id) {
        AchatDTO dto = achatService.archiverAchat(id);
        return dto != null ? ResponseEntity.ok(dto)
                : ResponseEntity.badRequest().body(Map.of("error", "Introuvable"));
    }

    @PatchMapping("/{id}/unarchive")
    public ResponseEntity<?> unarchive(@PathVariable Long id) {
        AchatDTO dto = achatService.desarchiverAchat(id);
        return dto != null ? ResponseEntity.ok(dto)
                : ResponseEntity.badRequest().body(Map.of("error", "Non archivé ou introuvable"));
    }

    // ── Suppression ───────────────────────────────────────────────────────────

    @DeleteMapping("/{id}")
    public ResponseEntity<?> delete(@PathVariable Long id) {
        boolean ok = achatService.deleteAchatAdmin(id);
        return ok ? ResponseEntity.ok(Map.of("success", true))
                  : ResponseEntity.notFound().build();
    }
}
