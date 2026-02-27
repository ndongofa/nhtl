package com.nhtl.controllers;

import com.nhtl.services.CommandeService;
import com.nhtl.dto.CommandeDTO;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.*;

import jakarta.validation.Valid;
import java.util.List;
import java.util.HashMap;
import java.util.Map;

@RestController
@RequestMapping("/api/commandes")
@Validated
public class CommandeController {

    @Autowired
    private CommandeService commandeService;

    @PostMapping
    public ResponseEntity<Map<String, Object>> createCommande(@Valid @RequestBody CommandeDTO commandeDTO) {
        try {
            CommandeDTO savedCommande = commandeService.createCommande(commandeDTO);
            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("message", "Commande créée avec succès");
            response.put("data", savedCommande);
            return ResponseEntity.status(HttpStatus.CREATED).body(response);
        } catch (Exception e) {
            Map<String, Object> response = new HashMap<>();
            response.put("success", false);
            response.put("message", "Erreur lors de la création de la commande: " + e.getMessage());
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(response);
        }
    }

    @GetMapping("/{id}")
    public ResponseEntity<Map<String, Object>> getCommandeById(@PathVariable Long id) {
        CommandeDTO commande = commandeService.getCommandeById(id);
        Map<String, Object> response = new HashMap<>();

        if (commande != null) {
            response.put("success", true);
            response.put("message", "Commande trouvée");
            response.put("data", commande);
            return ResponseEntity.ok(response);
        } else {
            response.put("success", false);
            response.put("message", "Commande non trouvée");
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(response);
        }
    }

    @GetMapping
    public ResponseEntity<Map<String, Object>> getAllCommandes() {
        List<CommandeDTO> commandes = commandeService.getAllCommandes();
        Map<String, Object> response = new HashMap<>();
        response.put("success", true);
        response.put("message", "Liste de toutes les commandes");
        response.put("count", commandes.size());
        response.put("data", commandes);
        return ResponseEntity.ok(response);
    }

    @GetMapping("/search/statut")
    public ResponseEntity<Map<String, Object>> getCommandesByStatut(@RequestParam String statut) {
        try {
            List<CommandeDTO> commandes = commandeService.getCommandesByStatut(statut);
            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("message", "Commandes avec le statut: " + statut);
            response.put("count", commandes.size());
            response.put("data", commandes);
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            Map<String, Object> response = new HashMap<>();
            response.put("success", false);
            response.put("message", "Statut invalide: " + e.getMessage());
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(response);
        }
    }

    @GetMapping("/search/plateforme")
    public ResponseEntity<Map<String, Object>> getCommandesByPlateforme(@RequestParam String plateforme) {
        try {
            List<CommandeDTO> commandes = commandeService.getCommandesByPlateforme(plateforme);
            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("message", "Commandes de la plateforme: " + plateforme);
            response.put("count", commandes.size());
            response.put("data", commandes);
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            Map<String, Object> response = new HashMap<>();
            response.put("success", false);
            response.put("message", "Plateforme invalide: " + e.getMessage());
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(response);
        }
    }

    @GetMapping("/search/phone")
    public ResponseEntity<Map<String, Object>> getCommandesByPhone(@RequestParam String phone) {
        List<CommandeDTO> commandes = commandeService.getCommandesByPhoneNumber(phone);
        Map<String, Object> response = new HashMap<>();
        response.put("success", true);
        response.put("message", "Commandes pour le numéro: " + phone);
        response.put("count", commandes.size());
        response.put("data", commandes);
        return ResponseEntity.ok(response);
    }

    @GetMapping("/search/country")
    public ResponseEntity<Map<String, Object>> getCommandesByCountry(@RequestParam String country) {
        List<CommandeDTO> commandes = commandeService.getCommandesByCountry(country);
        Map<String, Object> response = new HashMap<>();
        response.put("success", true);
        response.put("message", "Commandes vers: " + country);
        response.put("count", commandes.size());
        response.put("data", commandes);
        return ResponseEntity.ok(response);
    }

    @GetMapping("/search")
    public ResponseEntity<Map<String, Object>> searchCommandes(
            @RequestParam(required = false) String nom,
            @RequestParam(required = false) String prenom) {
        List<CommandeDTO> commandes = commandeService.searchByNomOrPrenom(
            nom != null ? nom : "", prenom != null ? prenom : "");
        Map<String, Object> response = new HashMap<>();
        response.put("success", true);
        response.put("message", "Résultats de recherche");
        response.put("count", commandes.size());
        response.put("data", commandes);
        return ResponseEntity.ok(response);
    }

    @PutMapping("/{id}")
    public ResponseEntity<Map<String, Object>> updateCommande(
            @PathVariable Long id,
            @Valid @RequestBody CommandeDTO commandeDTO) {
        try {
            CommandeDTO updatedCommande = commandeService.updateCommande(id, commandeDTO);
            Map<String, Object> response = new HashMap<>();

            if (updatedCommande != null) {
                response.put("success", true);
                response.put("message", "Commande mise à jour avec succès");
                response.put("data", updatedCommande);
                return ResponseEntity.ok(response);
            } else {
                response.put("success", false);
                response.put("message", "Commande non trouvée");
                return ResponseEntity.status(HttpStatus.NOT_FOUND).body(response);
            }
        } catch (Exception e) {
            Map<String, Object> response = new HashMap<>();
            response.put("success", false);
            response.put("message", "Erreur lors de la mise à jour: " + e.getMessage());
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(response);
        }
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Map<String, Object>> deleteCommande(@PathVariable Long id) {
        boolean deleted = commandeService.deleteCommande(id);
        Map<String, Object> response = new HashMap<>();

        if (deleted) {
            response.put("success", true);
            response.put("message", "Commande supprimée avec succès");
            return ResponseEntity.ok(response);
        } else {
            response.put("success", false);
            response.put("message", "Commande non trouvée");
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(response);
        }
    }
}