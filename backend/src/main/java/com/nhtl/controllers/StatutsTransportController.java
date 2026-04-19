package com.nhtl.controllers;

import com.nhtl.models.TransportStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.Arrays;
import java.util.List;
import java.util.stream.Collectors;

/**
 * GET /api/statuts-transports
 *
 * Retourne la liste des valeurs possibles de TransportStatus
 * pour affichage dans le filtre de la liste des transports.
 */
@RestController
@RequestMapping("/api/statuts-transports")
public class StatutsTransportController {

    @PreAuthorize("isAuthenticated()")
    @GetMapping
    public ResponseEntity<List<String>> getStatutsTransports() {
        List<String> statuts = Arrays.stream(TransportStatus.values())
                .map(Enum::name)
                .collect(Collectors.toList());
        return ResponseEntity.ok(statuts);
    }
}
