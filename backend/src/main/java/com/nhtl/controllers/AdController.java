package com.nhtl.controllers;

import com.nhtl.dto.AdDTO;
import com.nhtl.models.Ad;
import com.nhtl.repositories.AdRepository;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@Slf4j
@RestController
public class AdController {

    private final AdRepository repo;

    public AdController(AdRepository repo) {
        this.repo = repo;
    }

    // ── PUBLIC — carousel publicitaire ─────────────────────────────────────
    @GetMapping("/api/ads/public")
    public ResponseEntity<List<AdDTO>> getPublicAds() {
        List<AdDTO> result = repo.findByIsActiveTrueOrderByPositionAscCreatedAtAsc()
                .stream().map(this::toDTO).collect(Collectors.toList());
        return ResponseEntity.ok(result);
    }

    // ── ADMIN — CRUD ────────────────────────────────────────────────────────

    @GetMapping("/api/admin/ads")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<List<AdDTO>> adminGetAll() {
        List<AdDTO> result = repo.findAllByOrderByPositionAscCreatedAtAsc()
                .stream().map(this::toDTO).collect(Collectors.toList());
        return ResponseEntity.ok(result);
    }

    @PostMapping("/api/admin/ads")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<AdDTO> create(@RequestBody AdDTO dto) {
        Ad ad = fromDTO(dto);
        Ad saved = repo.save(ad);
        log.info("[AD] Created id={} title={}", saved.getId(), saved.getTitle());
        return ResponseEntity.ok(toDTO(saved));
    }

    @PutMapping("/api/admin/ads/{id}")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<?> update(@PathVariable Long id, @RequestBody AdDTO dto) {
        return repo.findById(id).map(ad -> {
            ad.setEmoji(dto.getEmoji());
            ad.setTitle(dto.getTitle());
            ad.setSubtitle(dto.getSubtitle());
            ad.setColorHex(dto.getColorHex());
            ad.setColorEndHex(dto.getColorEndHex());
            ad.setPosition(dto.getPosition());
            ad.setActive(dto.isActive());
            Ad saved = repo.save(ad);
            log.info("[AD] Updated id={}", id);
            return ResponseEntity.ok(toDTO(saved));
        }).orElse(ResponseEntity.notFound().build());
    }

    @DeleteMapping("/api/admin/ads/{id}")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<?> delete(@PathVariable Long id) {
        if (!repo.existsById(id)) return ResponseEntity.notFound().build();
        repo.deleteById(id);
        log.info("[AD] Deleted id={}", id);
        return ResponseEntity.ok(Map.of("success", true));
    }

    @PatchMapping("/api/admin/ads/{id}/toggle")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<?> toggle(@PathVariable Long id) {
        return repo.findById(id).map(ad -> {
            ad.setActive(!ad.isActive());
            repo.save(ad);
            log.info("[AD] Toggled id={} active={}", id, ad.isActive());
            return ResponseEntity.ok(Map.of("success", true, "isActive", ad.isActive()));
        }).orElse(ResponseEntity.notFound().build());
    }

    // ── Helpers ─────────────────────────────────────────────────────────────

    private AdDTO toDTO(Ad ad) {
        AdDTO dto = new AdDTO();
        dto.setId(ad.getId());
        dto.setEmoji(ad.getEmoji());
        dto.setTitle(ad.getTitle());
        dto.setSubtitle(ad.getSubtitle());
        dto.setColorHex(ad.getColorHex());
        dto.setColorEndHex(ad.getColorEndHex());
        dto.setPosition(ad.getPosition());
        dto.setActive(ad.isActive());
        dto.setCreatedAt(ad.getCreatedAt());
        dto.setUpdatedAt(ad.getUpdatedAt());
        return dto;
    }

    private Ad fromDTO(AdDTO dto) {
        Ad ad = new Ad();
        ad.setEmoji(dto.getEmoji() != null ? dto.getEmoji() : "📢");
        ad.setTitle(dto.getTitle());
        ad.setSubtitle(dto.getSubtitle() != null ? dto.getSubtitle() : "");
        ad.setColorHex(dto.getColorHex() != null ? dto.getColorHex() : "#004EDA");
        ad.setColorEndHex(dto.getColorEndHex() != null ? dto.getColorEndHex() : "#0D5BBF");
        ad.setPosition(dto.getPosition());
        ad.setActive(dto.isActive());
        return ad;
    }
}
