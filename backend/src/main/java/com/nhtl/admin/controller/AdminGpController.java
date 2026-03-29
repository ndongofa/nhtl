package com.nhtl.admin.controller;

import java.util.List;
import java.util.Map;

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

import com.nhtl.dto.GpAgentDTO;
import com.nhtl.services.GpAgentService;

@RestController
@RequestMapping("/admin/gp")
@PreAuthorize("hasRole('ADMIN')")
public class AdminGpController {

	private final GpAgentService service;

	public AdminGpController(GpAgentService service) {
		this.service = service;
	}

	@GetMapping
	public ResponseEntity<List<GpAgentDTO>> getAll() {
		return ResponseEntity.ok(service.getAll());
	}

	@GetMapping("/active")
	public ResponseEntity<List<GpAgentDTO>> getActive() {
		return ResponseEntity.ok(service.getActive());
	}

	@PostMapping
	public ResponseEntity<?> create(@RequestBody GpAgentDTO dto) {
		if (dto.getPrenom() == null || dto.getPrenom().trim().isEmpty()) {
			return ResponseEntity.badRequest().body(Map.of("error", "prenom requis"));
		}
		if (dto.getNom() == null || dto.getNom().trim().isEmpty()) {
			return ResponseEntity.badRequest().body(Map.of("error", "nom requis"));
		}
		return ResponseEntity.ok(service.create(dto));
	}

	@PutMapping("/{id}")
	public ResponseEntity<?> update(@PathVariable Long id, @RequestBody GpAgentDTO dto) {
		GpAgentDTO updated = service.update(id, dto);
		if (updated == null) {
			return ResponseEntity.status(404).body(Map.of("error", "GP introuvable"));
		}
		return ResponseEntity.ok(updated);
	}

	@DeleteMapping("/{id}")
	public ResponseEntity<?> delete(@PathVariable Long id) {
		boolean ok = service.delete(id);
		if (!ok) {
			return ResponseEntity.status(404).body(Map.of("error", "GP introuvable"));
		}
		return ResponseEntity.ok(Map.of("success", true));
	}
}