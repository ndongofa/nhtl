package com.nhtl.admin.controller;

import com.nhtl.dto.CommandeEcommerceDTO;
import com.nhtl.dto.ProduitDTO;
import com.nhtl.services.CommandeEcommerceService;
import com.nhtl.services.ProduitService;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

/**
 * Endpoints admin pour la gestion des produits e-commerce.
 * /api/admin/{service}/produits  → CRUD produits
 * /api/admin/{service}/commandes → gestion commandes e-commerce
 * service = maad | teranga | bestseller
 */
@Slf4j
@RestController
@RequestMapping("/api/admin")
@PreAuthorize("hasRole('ADMIN')")
public class AdminProduitController {

    private final ProduitService produitService;
    private final CommandeEcommerceService commandeEcommerceService;

    public AdminProduitController(ProduitService produitService,
                                  CommandeEcommerceService commandeEcommerceService) {
        this.produitService = produitService;
        this.commandeEcommerceService = commandeEcommerceService;
    }

    // ── Produits ─────────────────────────────────────────────────────────────

    @GetMapping("/{service}/produits")
    public ResponseEntity<List<ProduitDTO>> getProduits(@PathVariable String service) {
        return ResponseEntity.ok(produitService.getAllByServiceAdmin(service.toUpperCase()));
    }

    @PostMapping("/{service}/produits")
    public ResponseEntity<?> createProduit(
            @PathVariable String service, @RequestBody ProduitDTO dto) {
        dto.setServiceType(service.toUpperCase());
        return ResponseEntity.ok(produitService.createProduit(dto));
    }

    @PutMapping("/{service}/produits/{id}")
    public ResponseEntity<?> updateProduit(
            @PathVariable String service,
            @PathVariable Long id,
            @RequestBody ProduitDTO dto) {
        dto.setServiceType(service.toUpperCase());
        ProduitDTO updated = produitService.updateProduit(id, dto);
        return updated != null ? ResponseEntity.ok(updated) : ResponseEntity.notFound().build();
    }

    @DeleteMapping("/{service}/produits/{id}")
    public ResponseEntity<?> deleteProduit(
            @PathVariable String service, @PathVariable Long id) {
        boolean ok = produitService.deleteProduit(id);
        return ok ? ResponseEntity.ok(Map.of("success", true)) : ResponseEntity.notFound().build();
    }

    @PatchMapping("/{service}/produits/{id}/stock")
    public ResponseEntity<?> updateStock(
            @PathVariable String service,
            @PathVariable Long id,
            @RequestBody Map<String, Integer> body) {
        Integer stock = body.get("stock");
        if (stock == null || stock < 0)
            return ResponseEntity.badRequest().body(Map.of("error", "Stock invalide"));
        ProduitDTO updated = produitService.updateStock(id, stock);
        return updated != null ? ResponseEntity.ok(updated) : ResponseEntity.notFound().build();
    }

    // ── Commandes e-commerce ─────────────────────────────────────────────────

    @GetMapping("/{service}/commandes")
    public ResponseEntity<List<CommandeEcommerceDTO>> getCommandes(@PathVariable String service) {
        return ResponseEntity.ok(commandeEcommerceService.getAllByServiceAdmin(service.toUpperCase()));
    }

    @GetMapping("/{service}/commandes/{id}")
    public ResponseEntity<?> getCommande(
            @PathVariable String service, @PathVariable Long id) {
        return commandeEcommerceService.getById(id)
                .<ResponseEntity<?>>map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    @PatchMapping("/{service}/commandes/{id}/statut")
    public ResponseEntity<?> updateStatut(
            @PathVariable String service,
            @PathVariable Long id,
            @RequestBody Map<String, String> body) {
        String statut = body.get("statut");
        CommandeEcommerceDTO updated = commandeEcommerceService.updateStatut(id, statut);
        return updated != null ? ResponseEntity.ok(updated) : ResponseEntity.notFound().build();
    }

    @PatchMapping("/{service}/commandes/{id}/archive")
    public ResponseEntity<?> archive(
            @PathVariable String service, @PathVariable Long id) {
        CommandeEcommerceDTO dto = commandeEcommerceService.archiver(id);
        return dto != null ? ResponseEntity.ok(dto)
                : ResponseEntity.badRequest().body(Map.of("error", "Introuvable"));
    }

    @PatchMapping("/{service}/commandes/{id}/unarchive")
    public ResponseEntity<?> unarchive(
            @PathVariable String service, @PathVariable Long id) {
        CommandeEcommerceDTO dto = commandeEcommerceService.desarchiver(id);
        return dto != null ? ResponseEntity.ok(dto)
                : ResponseEntity.badRequest().body(Map.of("error", "Non archivée ou introuvable"));
    }

    @DeleteMapping("/{service}/commandes/{id}")
    public ResponseEntity<?> deleteCommande(
            @PathVariable String service, @PathVariable Long id) {
        boolean ok = commandeEcommerceService.supprimer(id);
        return ok ? ResponseEntity.ok(Map.of("success", true)) : ResponseEntity.notFound().build();
    }
}
