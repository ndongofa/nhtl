package com.nhtl.controllers;

import com.nhtl.models.CommandeStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.Arrays;
import java.util.List;
import java.util.stream.Collectors;

/**
 * GET /api/statuts-commandes
 *
 * Retourne la liste des valeurs possibles de CommandeStatus
 * pour affichage dans le filtre de la liste des commandes.
 */
@RestController
@RequestMapping("/api/statuts-commandes")
public class StatutsCommandeController {

    @PreAuthorize("isAuthenticated()")
    @GetMapping
    public ResponseEntity<List<String>> getStatutsCommandes() {
        List<String> statuts = Arrays.stream(CommandeStatus.values())
                .map(Enum::name)
                .collect(Collectors.toList());
        return ResponseEntity.ok(statuts);
    }
}
