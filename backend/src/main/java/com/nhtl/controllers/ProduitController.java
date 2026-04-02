package com.nhtl.controllers;

import com.nhtl.dto.ProduitDTO;
import com.nhtl.services.ProduitService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

/**
 * Endpoint public pour lire les produits par service.
 * GET /api/{service}/produits        → liste des produits actifs
 * GET /api/{service}/produits/{id}   → détail d'un produit
 * service = maad | teranga | bestseller
 */
@RestController
public class ProduitController {

    @Autowired
    private ProduitService produitService;

    @GetMapping("/api/{service}/produits")
    public ResponseEntity<List<ProduitDTO>> getProduits(@PathVariable String service) {
        try {
            List<ProduitDTO> produits = produitService.getAllByService(service.toUpperCase());
            return ResponseEntity.ok(produits);
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().build();
        }
    }

    @GetMapping("/api/{service}/produits/{id}")
    public ResponseEntity<?> getProduit(@PathVariable String service, @PathVariable Long id) {
        return produitService.getById(id)
                .<ResponseEntity<?>>map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }
}
