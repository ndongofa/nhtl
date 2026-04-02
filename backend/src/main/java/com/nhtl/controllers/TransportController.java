package com.nhtl.controllers;

import java.security.Principal;
import java.util.List;
import java.util.Map;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.nhtl.dto.TransportDTO;
import com.nhtl.services.TransportService;

@RestController
@RequestMapping("/api/transports")
public class TransportController {

	@Autowired
	private TransportService transportService;

	// Récupération de l'identifiant utilisateur
	private String getUserId(Principal principal) {
		return principal.getName();
	}

	// Création transport pour l'utilisateur connecté
	@PreAuthorize("isAuthenticated()")
	@PostMapping
	public ResponseEntity<?> createTransport(@RequestBody TransportDTO dto, Principal principal) {
		String userId = getUserId(principal);
		TransportDTO saved = transportService.createTransport(dto, userId);
		return ResponseEntity.ok(saved);
	}

	// Liste de ses propres transports
	@PreAuthorize("isAuthenticated()")
	@GetMapping
	public ResponseEntity<?> getMesTransports(Principal principal) {
		String userId = getUserId(principal);
		List<TransportDTO> transports = transportService.getAllTransportsForUser(userId);
		return ResponseEntity.ok(transports);
	}

	// Liste de ses propres transports archivés
	@PreAuthorize("isAuthenticated()")
	@GetMapping("/archives")
	public ResponseEntity<?> getMesTransportsArchives(Principal principal) {
		String userId = getUserId(principal);
		List<TransportDTO> archives = transportService.getTransportsArchivesForUser(userId);
		return ResponseEntity.ok(archives);
	}

	// Suppression d'un transport archivé (user)
	@PreAuthorize("isAuthenticated()")
	@DeleteMapping("/archives/{id}")
	public ResponseEntity<?> deleteArchiveTransport(@PathVariable Long id, Principal principal) {
		String userId = getUserId(principal);
		boolean ok = transportService.deleteTransportArchive(id, userId);
		if (ok) {
			return ResponseEntity.ok(Map.of("success", true));
		} else {
			return ResponseEntity.status(403).body(Map.of("error", "Accès refusé ou non archivé"));
		}
	}

	// Consultation d'un transport (accès refusé si ce n'est pas le sien)
	@PreAuthorize("isAuthenticated()")
	@GetMapping("/{id}")
	public ResponseEntity<?> getTransport(@PathVariable Long id, Principal principal) {
		String userId = getUserId(principal);
		return transportService.getTransportByIdAndUser(id, userId).<ResponseEntity<?>>map(ResponseEntity::ok)
				.orElseGet(() -> ResponseEntity.status(403).body(Map.of("error", "Accès refusé")));
	}

	// Suppression de son propre transport
	@PreAuthorize("isAuthenticated()")
	@DeleteMapping("/{id}")
	public ResponseEntity<?> deleteTransport(@PathVariable Long id, Principal principal) {
		String userId = getUserId(principal);
		boolean ok = transportService.deleteTransport(id, userId);
		if (ok) {
			return ResponseEntity.ok(Map.of("success", true));
		} else {
			return ResponseEntity.status(403).body(Map.of("error", "Accès refusé"));
		}
	}

	// Modification de son propre transport
	@PreAuthorize("isAuthenticated()")
	@PutMapping("/{id}")
	public ResponseEntity<?> updateTransport(@PathVariable Long id, @RequestBody TransportDTO dto,
			Principal principal) {
		String userId = getUserId(principal);
		TransportDTO updated = transportService.updateTransport(id, dto, userId);
		if (updated != null) {
			return ResponseEntity.ok(updated);
		} else {
			return ResponseEntity.status(403).body(Map.of("error", "Accès refusé"));
		}
	}
}