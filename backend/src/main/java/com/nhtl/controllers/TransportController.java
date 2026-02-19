package com.nhtl.controllers;

import com.nhtl.services.TransportService;
import com.nhtl.dto.TransportDTO;
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
@RequestMapping("/api/transports")
@Validated
public class TransportController {
    
    @Autowired
    private TransportService transportService;
    
    /**
     * Créer une nouvelle demande de transport
     * POST /api/transports
     */
    @PostMapping
    public ResponseEntity<Map<String, Object>> createTransport(@Valid @RequestBody TransportDTO transportDTO) {
        try {
            TransportDTO savedTransport = transportService.createTransport(transportDTO);
            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("message", "Transport créé avec succès");
            response.put("data", savedTransport);
            return ResponseEntity.status(HttpStatus.CREATED).body(response);
        } catch (Exception e) {
            Map<String, Object> response = new HashMap<>();
            response.put("success", false);
            response.put("message", "Erreur lors de la création du transport: " + e.getMessage());
            e.printStackTrace(); // ✅ Ajoutez cette ligne pour voir l'erreur dans les logs
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(response);
        }
    }
    
    /**
     * Récupérer un transport par ID
     * GET /api/transports/{id}
     */
    @GetMapping("/{id}")
    public ResponseEntity<Map<String, Object>> getTransportById(@PathVariable Long id) {
        TransportDTO transport = transportService.getTransportById(id);
        Map<String, Object> response = new HashMap<>();
        
        if (transport != null) {
            response.put("success", true);
            response.put("message", "Transport trouvé");
            response.put("data", transport);
            return ResponseEntity.ok(response);
        } else {
            response.put("success", false);
            response.put("message", "Transport non trouvé");
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(response);
        }
    }
    
    /**
     * Récupérer tous les transports
     * GET /api/transports
     */
    @GetMapping
    public ResponseEntity<Map<String, Object>> getAllTransports() {
        List<TransportDTO> transports = transportService.getAllTransports();
        Map<String, Object> response = new HashMap<>();
        response.put("success", true);
        response.put("message", "Liste de tous les transports");
        response.put("count", transports.size());
        response.put("data", transports);
        return ResponseEntity.ok(response);
    }
    
    /**
     * Récupérer les transports par statut
     * GET /api/transports/search/statut?statut=EN_ATTENTE
     */
    @GetMapping("/search/statut")
    public ResponseEntity<Map<String, Object>> getTransportsByStatut(@RequestParam String statut) {
        try {
            List<TransportDTO> transports = transportService.getTransportsByStatut(statut);
            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("message", "Transports avec le statut: " + statut);
            response.put("count", transports.size());
            response.put("data", transports);
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            Map<String, Object> response = new HashMap<>();
            response.put("success", false);
            response.put("message", "Statut invalide: " + e.getMessage());
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(response);
        }
    }
    
    /**
     * Récupérer les transports par numéro de téléphone
     * GET /api/transports/search/phone?phone=+237123456789
     */
    @GetMapping("/search/phone")
    public ResponseEntity<Map<String, Object>> getTransportsByPhone(@RequestParam String phone) {
        List<TransportDTO> transports = transportService.getTransportsByPhoneNumber(phone);
        Map<String, Object> response = new HashMap<>();
        response.put("success", true);
        response.put("message", "Transports pour le numéro: " + phone);
        response.put("count", transports.size());
        response.put("data", transports);
        return ResponseEntity.ok(response);
    }
    
    /**
     * Récupérer les transports par pays de destination
     * GET /api/transports/search/country?country=France
     */
    @GetMapping("/search/country")
    public ResponseEntity<Map<String, Object>> getTransportsByCountry(@RequestParam String country) {
        List<TransportDTO> transports = transportService.getTransportsByDestinationCountry(country);
        Map<String, Object> response = new HashMap<>();
        response.put("success", true);
        response.put("message", "Transports vers: " + country);
        response.put("count", transports.size());
        response.put("data", transports);
        return ResponseEntity.ok(response);
    }
    
    /**
     * Chercher les transports par nom ou prénom
     * GET /api/transports/search?nom=Dupont&prenom=Jean
     */
    @GetMapping("/search")
    public ResponseEntity<Map<String, Object>> searchTransports(
            @RequestParam(required = false) String nom,
            @RequestParam(required = false) String prenom) {
        List<TransportDTO> transports = transportService.searchByNomOrPrenom(nom != null ? nom : "", prenom != null ? prenom : "");
        Map<String, Object> response = new HashMap<>();
        response.put("success", true);
        response.put("message", "Résultats de recherche");
        response.put("count", transports.size());
        response.put("data", transports);
        return ResponseEntity.ok(response);
    }
    
    /**
     * Mettre à jour un transport
     * PUT /api/transports/{id}
     */
    @PutMapping("/{id}")
    public ResponseEntity<Map<String, Object>> updateTransport(
            @PathVariable Long id,
            @Valid @RequestBody TransportDTO transportDTO) {
        try {
            TransportDTO updatedTransport = transportService.updateTransport(id, transportDTO);
            Map<String, Object> response = new HashMap<>();
            
            if (updatedTransport != null) {
                response.put("success", true);
                response.put("message", "Transport mis à jour avec succès");
                response.put("data", updatedTransport);
                return ResponseEntity.ok(response);
            } else {
                response.put("success", false);
                response.put("message", "Transport non trouvé");
                return ResponseEntity.status(HttpStatus.NOT_FOUND).body(response);
            }
        } catch (Exception e) {
            Map<String, Object> response = new HashMap<>();
            response.put("success", false);
            response.put("message", "Erreur lors de la mise à jour: " + e.getMessage());
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(response);
        }
    }
    
    /**
     * Supprimer un transport
     * DELETE /api/transports/{id}
     */
    @DeleteMapping("/{id}")
    public ResponseEntity<Map<String, Object>> deleteTransport(@PathVariable Long id) {
        boolean deleted = transportService.deleteTransport(id);
        Map<String, Object> response = new HashMap<>();
        
        if (deleted) {
            response.put("success", true);
            response.put("message", "Transport supprimé avec succès");
            return ResponseEntity.ok(response);
        } else {
            response.put("success", false);
            response.put("message", "Transport non trouvé");
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(response);
        }
    }
}