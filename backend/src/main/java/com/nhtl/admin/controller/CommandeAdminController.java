package com.nhtl.admin.controller;

import com.nhtl.dto.CommandeDTO;
import com.nhtl.services.CommandeService;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

/**
 * Endpoints admin pour les commandes.
 * GET /api/admin/commandes        → toutes les commandes
 * GET /api/admin/commandes/{id}   → une commande par ID (avec champs postaux)
 * PATCH /api/admin/commandes/{id}/statut → statut administratif
 */
@Slf4j
@RestController
@RequestMapping("/api/admin/commandes")
@PreAuthorize("hasRole('ADMIN')")
public class CommandeAdminController {

    private final CommandeService commandeService;

    public CommandeAdminController(CommandeService commandeService) {
        this.commandeService = commandeService;
    }

    // ── GET tous ──────────────────────────────────────────────────────────────

    @GetMapping
    public ResponseEntity<List<CommandeDTO>> getAll() {
        return ResponseEntity.ok(commandeService.getAllCommandes());
    }

    @GetMapping("/all")
    public ResponseEntity<List<CommandeDTO>> getAllAlt() {
        return ResponseEntity.ok(commandeService.getAllCommandes());
    }

    // ── GET par ID ────────────────────────────────────────────────────────────
    // ✅ Retourne le DTO complet incluant photoColisUrl, deposePosteAt, statutSuivi

    @GetMapping("/{id}")
    public ResponseEntity<?> getById(@PathVariable Long id) {
        return commandeService.getCommandeByIdAndAdmin(id)
                .<ResponseEntity<?>>map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    // ── Archives ──────────────────────────────────────────────────────────────

    @GetMapping("/archives")
    public ResponseEntity<List<CommandeDTO>> getArchives() {
        return ResponseEntity.ok(commandeService.getCommandesArchives());
    }

    // ── PATCH statut administratif ────────────────────────────────────────────

    @PatchMapping("/{id}/statut")
    public ResponseEntity<?> updateStatut(
            @PathVariable Long id,
            @RequestBody Map<String, String> body) {
        String statut = body.get("statut");
        CommandeDTO updated = commandeService.updateStatut(id, statut);
        if (updated == null) return ResponseEntity.notFound().build();
        return ResponseEntity.ok(updated);
    }

    // ── Archive / Désarchive ──────────────────────────────────────────────────

    @PatchMapping("/{id}/archive")
    public ResponseEntity<?> archive(@PathVariable Long id) {
        CommandeDTO dto = commandeService.archiverCommande(id);
        return dto != null ? ResponseEntity.ok(dto)
                : ResponseEntity.badRequest().body(Map.of("error", "Introuvable"));
    }

    @PatchMapping("/{id}/unarchive")
    public ResponseEntity<?> unarchive(@PathVariable Long id) {
        CommandeDTO dto = commandeService.desarchiverCommande(id);
        return dto != null ? ResponseEntity.ok(dto)
                : ResponseEntity.badRequest().body(Map.of("error", "Non archivée ou introuvable"));
    }

    // ── Suppression ───────────────────────────────────────────────────────────

    @DeleteMapping("/{id}")
    public ResponseEntity<?> delete(@PathVariable Long id) {
        boolean ok = commandeService.deleteCommandeAdmin(id);
        return ok ? ResponseEntity.ok(Map.of("success", true))
                  : ResponseEntity.notFound().build();
    }
}