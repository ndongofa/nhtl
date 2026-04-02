package com.nhtl.controllers;

import com.nhtl.dto.PanierItemDTO;
import com.nhtl.services.PanierService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.security.Principal;
import java.util.List;
import java.util.Map;

/**
 * Endpoints panier par service.
 * GET    /api/{service}/panier            → panier de l'utilisateur
 * POST   /api/{service}/panier            → ajouter / modifier un article
 * DELETE /api/{service}/panier/{produitId}→ retirer un article
 * DELETE /api/{service}/panier            → vider le panier
 */
@RestController
@PreAuthorize("isAuthenticated()")
public class PanierController {

    @Autowired
    private PanierService panierService;

    @GetMapping("/api/{service}/panier")
    public ResponseEntity<List<PanierItemDTO>> getPanier(
            @PathVariable String service, Principal principal) {
        List<PanierItemDTO> items = panierService.getPanierForUser(principal.getName(), service);
        return ResponseEntity.ok(items);
    }

    @PostMapping("/api/{service}/panier")
    public ResponseEntity<?> ajouterArticle(
            @PathVariable String service,
            @RequestBody Map<String, Object> body,
            Principal principal) {
        try {
            Long produitId = Long.valueOf(body.get("produitId").toString());
            int quantite = Integer.parseInt(body.getOrDefault("quantite", 1).toString());
            if (quantite <= 0) return ResponseEntity.badRequest().body(Map.of("error", "Quantité invalide"));
            PanierItemDTO item = panierService.ajouterOuModifier(principal.getName(), produitId, quantite);
            if (item == null) return ResponseEntity.notFound().build();
            return ResponseEntity.ok(item);
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        }
    }

    @DeleteMapping("/api/{service}/panier/{produitId}")
    public ResponseEntity<?> supprimerArticle(
            @PathVariable String service,
            @PathVariable Long produitId,
            Principal principal) {
        boolean ok = panierService.supprimerItem(principal.getName(), produitId);
        return ok ? ResponseEntity.ok(Map.of("success", true))
                  : ResponseEntity.notFound().build();
    }

    @DeleteMapping("/api/{service}/panier")
    public ResponseEntity<?> viderPanier(
            @PathVariable String service, Principal principal) {
        panierService.viderPanier(principal.getName(), service);
        return ResponseEntity.ok(Map.of("success", true));
    }
}
