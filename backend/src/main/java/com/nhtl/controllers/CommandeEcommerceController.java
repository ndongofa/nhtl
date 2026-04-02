package com.nhtl.controllers;

import com.nhtl.dto.CommandeEcommerceDTO;
import com.nhtl.services.CommandeEcommerceService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.security.Principal;
import java.util.List;
import java.util.Map;

/**
 * Endpoints commandes e-commerce par service.
 * POST /api/{service}/commandes          → valider le panier
 * GET  /api/{service}/commandes          → mes commandes
 * GET  /api/{service}/commandes/archives → mes archives
 * GET  /api/{service}/commandes/{id}     → détail
 * DELETE /api/{service}/commandes/archives/{id} → supprimer archive
 */
@RestController
@PreAuthorize("isAuthenticated()")
public class CommandeEcommerceController {

    @Autowired
    private CommandeEcommerceService commandeService;

    @PostMapping("/api/{service}/commandes")
    public ResponseEntity<?> validerPanier(
            @PathVariable String service,
            @RequestBody CommandeEcommerceDTO dto,
            Principal principal) {
        dto.setServiceType(service.toUpperCase());
        CommandeEcommerceDTO saved = commandeService.validerPanier(dto, principal.getName());
        if (saved == null) return ResponseEntity.badRequest().body(Map.of("error", "Panier vide ou produits invalides"));
        return ResponseEntity.ok(saved);
    }

    @GetMapping("/api/{service}/commandes")
    public ResponseEntity<List<CommandeEcommerceDTO>> getMesCommandes(
            @PathVariable String service, Principal principal) {
        return ResponseEntity.ok(commandeService.getCommandesForUser(principal.getName(), service));
    }

    @GetMapping("/api/{service}/commandes/archives")
    public ResponseEntity<List<CommandeEcommerceDTO>> getMesArchives(
            @PathVariable String service, Principal principal) {
        return ResponseEntity.ok(commandeService.getArchivesForUser(principal.getName(), service));
    }

    @GetMapping("/api/{service}/commandes/{id}")
    public ResponseEntity<?> getCommande(
            @PathVariable String service, @PathVariable Long id) {
        return commandeService.getById(id)
                .<ResponseEntity<?>>map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    @DeleteMapping("/api/{service}/commandes/archives/{id}")
    public ResponseEntity<?> deleteArchive(
            @PathVariable String service, @PathVariable Long id) {
        boolean ok = commandeService.supprimer(id);
        return ok ? ResponseEntity.ok(Map.of("success", true))
                  : ResponseEntity.notFound().build();
    }
}
