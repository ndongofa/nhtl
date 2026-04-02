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

import com.nhtl.dto.AchatDTO;
import com.nhtl.services.AchatService;

@RestController
@RequestMapping("/api/achats")
public class AchatController {

	@Autowired
	private AchatService achatService;

	private String getUserId(Principal principal) {
		return principal.getName();
	}

	@PreAuthorize("isAuthenticated()")
	@PostMapping
	public ResponseEntity<?> createAchat(@RequestBody AchatDTO dto, Principal principal) {
		String userId = getUserId(principal);
		AchatDTO saved = achatService.createAchat(dto, userId);
		return ResponseEntity.ok(saved);
	}

	@PreAuthorize("isAuthenticated()")
	@GetMapping
	public ResponseEntity<?> getMesAchats(Principal principal) {
		String userId = getUserId(principal);
		List<AchatDTO> achats = achatService.getAllAchatsForUser(userId);
		return ResponseEntity.ok(achats);
	}

	@PreAuthorize("isAuthenticated()")
	@GetMapping("/archives")
	public ResponseEntity<?> getMesAchatsArchives(Principal principal) {
		String userId = getUserId(principal);
		List<AchatDTO> archives = achatService.getAchatsArchivesForUser(userId);
		return ResponseEntity.ok(archives);
	}

	@PreAuthorize("isAuthenticated()")
	@DeleteMapping("/archives/{id}")
	public ResponseEntity<?> deleteArchiveAchat(@PathVariable Long id, Principal principal) {
		String userId = getUserId(principal);
		boolean ok = achatService.deleteAchatArchive(id, userId);
		if (ok) {
			return ResponseEntity.ok(Map.of("success", true));
		} else {
			return ResponseEntity.status(403).body(Map.of("error", "Accès refusé ou non archivé"));
		}
	}

	@PreAuthorize("isAuthenticated()")
	@GetMapping("/{id}")
	public ResponseEntity<?> getAchat(@PathVariable Long id, Principal principal) {
		String userId = getUserId(principal);
		return achatService.getAchatByIdAndUser(id, userId).<ResponseEntity<?>>map(ResponseEntity::ok)
				.orElseGet(() -> ResponseEntity.status(403).body(Map.of("error", "Accès refusé")));
	}

	@PreAuthorize("isAuthenticated()")
	@DeleteMapping("/{id}")
	public ResponseEntity<?> deleteAchat(@PathVariable Long id, Principal principal) {
		String userId = getUserId(principal);
		boolean ok = achatService.deleteAchat(id, userId);
		if (ok) {
			return ResponseEntity.ok(Map.of("success", true));
		} else {
			return ResponseEntity.status(403).body(Map.of("error", "Accès refusé"));
		}
	}

	@PreAuthorize("isAuthenticated()")
	@PutMapping("/{id}")
	public ResponseEntity<?> updateAchat(@PathVariable Long id, @RequestBody AchatDTO dto, Principal principal) {
		String userId = getUserId(principal);
		AchatDTO updated = achatService.updateAchat(id, dto, userId);
		if (updated != null) {
			return ResponseEntity.ok(updated);
		} else {
			return ResponseEntity.status(403).body(Map.of("error", "Accès refusé"));
		}
	}
}
