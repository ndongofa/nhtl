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

import com.nhtl.dto.CommandeDTO;
import com.nhtl.services.CommandeService;

@RestController
@RequestMapping("/api/commandes")
public class CommandeController {

	@Autowired
	private CommandeService commandeService;

	private String getUserId(Principal principal) {
		return principal.getName();
	}

	@PreAuthorize("isAuthenticated()")
	@PostMapping
	public ResponseEntity<?> createCommande(@RequestBody CommandeDTO dto, Principal principal) {
		String userId = getUserId(principal);
		CommandeDTO saved = commandeService.createCommande(dto, userId);
		return ResponseEntity.ok(saved);
	}

	@PreAuthorize("isAuthenticated()")
	@GetMapping
	public ResponseEntity<?> getMesCommandes(Principal principal) {
		String userId = getUserId(principal);
		List<CommandeDTO> commandes = commandeService.getAllCommandesForUser(userId);
		return ResponseEntity.ok(commandes);
	}

	@PreAuthorize("isAuthenticated()")
	@GetMapping("/archives")
	public ResponseEntity<?> getMesCommandesArchives(Principal principal) {
		String userId = getUserId(principal);
		List<CommandeDTO> archives = commandeService.getCommandesArchivesForUser(userId);
		return ResponseEntity.ok(archives);
	}

	// ✅ FIX: suppression d'une commande archivée uniquement
	@PreAuthorize("isAuthenticated()")
	@DeleteMapping("/archives/{id}")
	public ResponseEntity<?> deleteArchiveCommande(@PathVariable Long id, Principal principal) {
		String userId = getUserId(principal);
		boolean ok = commandeService.deleteCommandeArchive(id, userId);
		if (ok) {
			return ResponseEntity.ok(Map.of("success", true));
		} else {
			return ResponseEntity.status(403).body(Map.of("error", "Accès refusé ou non archivée"));
		}
	}

	@PreAuthorize("isAuthenticated()")
	@GetMapping("/{id}")
	public ResponseEntity<?> getCommande(@PathVariable Long id, Principal principal) {
		String userId = getUserId(principal);
		return commandeService.getCommandeByIdAndUser(id, userId).<ResponseEntity<?>>map(ResponseEntity::ok)
				.orElseGet(() -> ResponseEntity.status(403).body(Map.of("error", "Accès refusé")));
	}

	@PreAuthorize("isAuthenticated()")
	@DeleteMapping("/{id}")
	public ResponseEntity<?> deleteCommande(@PathVariable Long id, Principal principal) {
		String userId = getUserId(principal);
		boolean ok = commandeService.deleteCommande(id, userId);
		if (ok) {
			return ResponseEntity.ok(Map.of("success", true));
		} else {
			return ResponseEntity.status(403).body(Map.of("error", "Accès refusé"));
		}
	}

	@PreAuthorize("isAuthenticated()")
	@PutMapping("/{id}")
	public ResponseEntity<?> updateCommande(@PathVariable Long id, @RequestBody CommandeDTO dto, Principal principal) {
		String userId = getUserId(principal);
		CommandeDTO updated = commandeService.updateCommande(id, dto, userId);
		if (updated != null) {
			return ResponseEntity.ok(updated);
		} else {
			return ResponseEntity.status(403).body(Map.of("error", "Accès refusé"));
		}
	}
}