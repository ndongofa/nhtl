package com.nhtl.admin.controller;

import com.nhtl.models.Transport;
import com.nhtl.repositories.TransportRepository;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

/**
 * Gestion ADMIN des transports — statut ADMINISTRATIF uniquement.
 *
 * PATCH /api/admin/transports/{id}/statut
 *   → Change le statut administratif (EN_ATTENTE, EN_COURS, LIVRE, ANNULE)
 *   → PAS de notifications (c'est un statut interne de gestion de dossier)
 *
 * PATCH /api/admin/transports/{id}/status
 *   → Géré par TransportStatusController (statut LOGISTIQUE + notifications)
 */
@Slf4j
@RestController
@RequestMapping("/api/admin/transports")
@PreAuthorize("hasRole('ADMIN')")
public class TransportAdminController {

    private final TransportRepository repo;

    public TransportAdminController(TransportRepository repo) {
        this.repo = repo;
    }

    // ── GET tous les transports (admin) ───────────────────────────────────
    @GetMapping("/all")
    public ResponseEntity<List<Map<String, Object>>> getAll() {
        List<Map<String, Object>> result = repo.findAll()
                .stream()
                .map(this::toMap)
                .collect(Collectors.toList());
        return ResponseEntity.ok(result);
    }

    // ── PATCH statut ADMINISTRATIF — sans notifications ───────────────────
    @PatchMapping("/{id}/statut")
    public ResponseEntity<?> changeStatutAdmin(
            @PathVariable Long id,
            @RequestBody Map<String, String> body) {

        String newStatut = body.get("statut");
        if (newStatut == null || newStatut.isBlank()) {
            return ResponseEntity.badRequest()
                    .body(Map.of("error", "Champ 'statut' requis"));
        }

        return repo.findById(id).map(t -> {
            String old = t.getStatut();
            t.setStatut(newStatut.toUpperCase().trim());
            repo.save(t);
            log.info("[ADMIN] Statut administratif transport={} : {} → {}",
                    id, old, t.getStatut());
            return ResponseEntity.ok(Map.of(
                    "success", true,
                    "id",      id,
                    "statut",  t.getStatut()));
        }).orElse(ResponseEntity.notFound().build());
    }

    // ── PATCH archiver ────────────────────────────────────────────────────
    @PatchMapping("/{id}/archive")
    public ResponseEntity<?> archive(@PathVariable Long id) {
        return repo.findById(id).map(t -> {
            t.setArchived(true);
            repo.save(t);
            log.info("[ADMIN] Transport {} archivé", id);
            return ResponseEntity.ok(Map.of("success", true));
        }).orElse(ResponseEntity.notFound().build());
    }

    // ── PATCH désarchiver ─────────────────────────────────────────────────
    @PatchMapping("/{id}/unarchive")
    public ResponseEntity<?> unarchive(@PathVariable Long id) {
        return repo.findById(id).map(t -> {
            t.setArchived(false);
            repo.save(t);
            log.info("[ADMIN] Transport {} désarchivé", id);
            return ResponseEntity.ok(Map.of("success", true));
        }).orElse(ResponseEntity.notFound().build());
    }

    // ── GET archives ──────────────────────────────────────────────────────
    @GetMapping("/archives")
    public ResponseEntity<List<Map<String, Object>>> getArchives() {
        List<Map<String, Object>> result = repo.findByArchivedTrue()
                .stream().map(this::toMap).collect(Collectors.toList());
        return ResponseEntity.ok(result);
    }

    // ── Helper toMap (projection légère) ─────────────────────────────────
    private Map<String, Object> toMap(Transport t) {
        return Map.ofEntries(
                Map.entry("id",           t.getId()),
                Map.entry("userId",       t.getUserId()),
                Map.entry("nom",          nvl(t.getNom())),
                Map.entry("prenom",       nvl(t.getPrenom())),
                Map.entry("numeroTelephone", nvl(t.getNumeroTelephone())),
                Map.entry("email",        nvl(t.getEmail())),
                Map.entry("paysExpediteur",  nvl(t.getPaysExpediteur())),
                Map.entry("villeExpediteur", nvl(t.getVilleExpediteur())),
                Map.entry("paysDestinataire",  nvl(t.getPaysDestinataire())),
                Map.entry("villeDestinataire", nvl(t.getVilleDestinataire())),
                Map.entry("typesMarchandise",  nvl(t.getTypesMarchandise())),
                Map.entry("poids",        t.getPoids() != null ? t.getPoids() : 0),
                Map.entry("statut",       nvl(t.getStatut())),
                Map.entry("statutSuivi",  t.getStatutSuivi() != null
                        ? t.getStatutSuivi().name() : "EN_ATTENTE"),
                Map.entry("archived",     t.getArchived() != null && t.getArchived()),
                Map.entry("gpId",         t.getGpId() != null ? t.getGpId() : 0),
                Map.entry("gpPrenom",     nvl(t.getGpPrenom())),
                Map.entry("gpNom",        nvl(t.getGpNom())),
                Map.entry("gpPhoneNumber",nvl(t.getGpPhoneNumber()))
        );
    }

    private String nvl(String s) { return s != null ? s : ""; }
}