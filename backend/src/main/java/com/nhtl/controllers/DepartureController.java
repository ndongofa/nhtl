package com.nhtl.controllers;

import com.nhtl.dto.DepartureDTO;
import com.nhtl.models.Departure;
import com.nhtl.models.DepartureStatus;
import com.nhtl.repositories.DepartureRepository;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@Slf4j
@RestController
public class DepartureController {

    private final DepartureRepository repo;

    public DepartureController(DepartureRepository repo) {
        this.repo = repo;
    }

    // ── ENDPOINT PUBLIC — landing + home Flutter ───────────────────────────
    // Retourne les 4 derniers départs PUBLISHED à venir (triés par date ASC)
    // Les 3-4 prochains publiés s'afficheront dans le compte à rebours
    @GetMapping("/api/departures/public")
    public ResponseEntity<List<DepartureDTO>> getPublicDepartures() {
        List<Departure> all = repo.findByStatusAndDepartureDateTimeAfterOrderByDepartureDateTimeAsc(
                DepartureStatus.PUBLISHED, LocalDateTime.now());

        // Limité aux 4 prochains pour le compte à rebours
        List<DepartureDTO> result = all.stream()
                .limit(4)
                .map(this::toDTO)
                .collect(Collectors.toList());

        return ResponseEntity.ok(result);
    }

    // Tous les départs publiés (sans limite) — pour la section "Tous les départs"
    @GetMapping("/api/departures/public/all")
    public ResponseEntity<List<DepartureDTO>> getAllPublicDepartures() {
        List<DepartureDTO> result = repo
                .findByStatusAndDepartureDateTimeAfterOrderByDepartureDateTimeAsc(
                        DepartureStatus.PUBLISHED, LocalDateTime.now().minusDays(1))
                .stream()
                .map(this::toDTO)
                .collect(Collectors.toList());
        return ResponseEntity.ok(result);
    }

    // ── CRUD ADMIN ────────────────────────────────────────────────────────

    // Tous les départs (toutes statuts) — admin uniquement
    @GetMapping("/api/admin/departures")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<List<DepartureDTO>> getAll() {
        List<DepartureDTO> result = repo.findAllByOrderByDepartureDateTimeAsc()
                .stream().map(this::toDTO).collect(Collectors.toList());
        return ResponseEntity.ok(result);
    }

    // Créer un départ (DRAFT par défaut)
    @PostMapping("/api/admin/departures")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<DepartureDTO> create(@RequestBody DepartureDTO dto) {
        Departure d = fromDTO(dto);
        d.setStatus(DepartureStatus.DRAFT);
        Departure saved = repo.save(d);
        log.info("[DEPARTURE] Created id={} route={}", saved.getId(), saved.getRoute());
        return ResponseEntity.ok(toDTO(saved));
    }

    // Modifier un départ
    @PutMapping("/api/admin/departures/{id}")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<?> update(@PathVariable Long id, @RequestBody DepartureDTO dto) {
        return repo.findById(id).map(d -> {
            d.setRoute(dto.getRoute());
            d.setPointDepart(dto.getPointDepart());
            d.setPointArrivee(dto.getPointArrivee());
            d.setFlagEmoji(dto.getFlagEmoji());
            d.setDepartureDateTime(dto.getDepartureDateTime());
            Departure saved = repo.save(d);
            log.info("[DEPARTURE] Updated id={}", id);
            return ResponseEntity.ok(toDTO(saved));
        }).orElse(ResponseEntity.notFound().build());
    }

    // Supprimer un départ
    @DeleteMapping("/api/admin/departures/{id}")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<?> delete(@PathVariable Long id) {
        if (!repo.existsById(id)) return ResponseEntity.notFound().build();
        repo.deleteById(id);
        log.info("[DEPARTURE] Deleted id={}", id);
        return ResponseEntity.ok(Map.of("success", true));
    }

    // Changer le statut (DRAFT → PUBLISHED → ARCHIVED)
    @PatchMapping("/api/admin/departures/{id}/status")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<?> changeStatus(
            @PathVariable Long id,
            @RequestBody Map<String, String> body) {

        String rawStatus = body.get("status");
        DepartureStatus newStatus;
        try {
            newStatus = DepartureStatus.valueOf(rawStatus);
        } catch (IllegalArgumentException | NullPointerException e) {
            return ResponseEntity.badRequest().body(
                    Map.of("error", "Statut invalide : " + rawStatus,
                           "valeurs_acceptees", DepartureStatus.values()));
        }

        return repo.findById(id).map(d -> {
            d.setStatus(newStatus);
            repo.save(d);
            log.info("[DEPARTURE] Status changed id={} -> {}", id, newStatus);
            return ResponseEntity.ok(Map.of("success", true, "status", newStatus.name()));
        }).orElse(ResponseEntity.notFound().build());
    }

    // ── Helpers ────────────────────────────────────────────────────────────

    private DepartureDTO toDTO(Departure d) {
        DepartureDTO dto = new DepartureDTO();
        dto.setId(d.getId());
        dto.setRoute(d.getRoute());
        dto.setPointDepart(d.getPointDepart());
        dto.setPointArrivee(d.getPointArrivee());
        dto.setFlagEmoji(d.getFlagEmoji());
        dto.setDepartureDateTime(d.getDepartureDateTime());
        dto.setStatus(d.getStatus());
        dto.setCreatedAt(d.getCreatedAt());
        dto.setUpdatedAt(d.getUpdatedAt());
        return dto;
    }

    private Departure fromDTO(DepartureDTO dto) {
        Departure d = new Departure();
        d.setRoute(dto.getRoute());
        d.setPointDepart(dto.getPointDepart());
        d.setPointArrivee(dto.getPointArrivee());
        d.setFlagEmoji(dto.getFlagEmoji());
        d.setDepartureDateTime(dto.getDepartureDateTime());
        if (dto.getStatus() != null) d.setStatus(dto.getStatus());
        return d;
    }
}