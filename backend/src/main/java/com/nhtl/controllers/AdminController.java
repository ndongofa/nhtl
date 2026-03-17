package com.nhtl.controllers;

import java.util.List;
import java.util.Map;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.client.RestTemplate;

import com.nhtl.dto.AssignGpRequest;
import com.nhtl.dto.CommandeDTO;
import com.nhtl.dto.TransportDTO;
import com.nhtl.services.CommandeService;
import com.nhtl.services.TransportService;

@RestController
@RequestMapping("/admin")
@PreAuthorize("hasRole('ADMIN')")
public class AdminController {

	@Value("${supabase.project.url}")
	private String supabaseProjectUrl;

	@Value("${supabase.service.role.key}")
	private String supabaseServiceRoleKey;

	private final RestTemplate restTemplate = new RestTemplate();

	@Autowired
	private CommandeService commandeService;

	@Autowired
	private TransportService transportService;

	// ----------- Commandes (ADMIN) -----------

	@GetMapping("/commandes/all")
	public ResponseEntity<List<CommandeDTO>> getToutesLesCommandes() {
		List<CommandeDTO> toutes = commandeService.getAllCommandes();
		return ResponseEntity.ok(toutes);
	}

	@GetMapping("/commandes/archives")
	public ResponseEntity<List<CommandeDTO>> getCommandesArchives() {
		List<CommandeDTO> archives = commandeService.getCommandesArchives();
		return ResponseEntity.ok(archives);
	}

	@DeleteMapping("/commandes/{id}")
	public ResponseEntity<?> deleteCommandeAdmin(@PathVariable Long id) {
		boolean ok = commandeService.deleteCommandeAdmin(id);
		if (ok) {
			return ResponseEntity.ok(Map.of("success", true));
		} else {
			return ResponseEntity.status(404).body(Map.of("error", "Commande inexistante"));
		}
	}

	@PutMapping("/commandes/{id}")
	public ResponseEntity<?> updateCommandeAdmin(@PathVariable Long id, @RequestBody CommandeDTO dto) {
		CommandeDTO updated = commandeService.updateCommandeAdmin(id, dto);
		if (updated != null) {
			return ResponseEntity.ok(updated);
		} else {
			return ResponseEntity.status(404).body(Map.of("error", "Commande inexistante"));
		}
	}

	@PatchMapping("/commandes/{id}/statut")
	public ResponseEntity<?> updateStatutCommande(@PathVariable Long id, @RequestBody Map<String, String> data) {
		String statut = data.get("statut");
		CommandeDTO updated = commandeService.updateStatut(id, statut);
		if (updated != null) {
			return ResponseEntity.ok(updated);
		} else {
			return ResponseEntity.status(404).body(Map.of("error", "Commande inexistante"));
		}
	}

	@PatchMapping("/commandes/{id}/archive")
	public ResponseEntity<?> archiveCommande(@PathVariable Long id) {
		CommandeDTO updated = commandeService.archiverCommande(id);
		if (updated != null) {
			return ResponseEntity.ok(updated);
		} else {
			return ResponseEntity.status(404).body(Map.of("error", "Commande inexistante"));
		}
	}

	@PatchMapping("/commandes/{id}/unarchive")
	public ResponseEntity<?> unarchiveCommande(@PathVariable Long id) {
		CommandeDTO updated = commandeService.desarchiverCommande(id);
		if (updated != null) {
			return ResponseEntity.ok(updated);
		} else {
			return ResponseEntity.status(404).body(Map.of("error", "Commande inexistante ou non archivée"));
		}
	}

	// ----------- Transports (ADMIN) -----------

	@PatchMapping("/transports/{id}/statut")
	public ResponseEntity<?> updateStatutTransport(@PathVariable Long id, @RequestBody Map<String, String> data) {
		String statut = data.get("statut");
		TransportDTO updated = transportService.updateStatut(id, statut);
		if (updated != null) {
			return ResponseEntity.ok(updated);
		} else {
			return ResponseEntity.status(404).body(Map.of("error", "Transport inexistant"));
		}
	}

	@GetMapping("/transports/all")
	public ResponseEntity<List<TransportDTO>> getTousLesTransports() {
		List<TransportDTO> tous = transportService.getAllTransports();
		return ResponseEntity.ok(tous);
	}

	@GetMapping("/transports/archives")
	public ResponseEntity<List<TransportDTO>> getTransportsArchives() {
		List<TransportDTO> archives = transportService.getTransportsArchives();
		return ResponseEntity.ok(archives);
	}

	@DeleteMapping("/transports/{id}")
	public ResponseEntity<?> deleteTransportAdmin(@PathVariable Long id) {
		boolean ok = transportService.deleteTransportAdmin(id);
		if (ok) {
			return ResponseEntity.ok(Map.of("success", true));
		} else {
			return ResponseEntity.status(404).body(Map.of("error", "Transport inexistant"));
		}
	}

	@PutMapping("/transports/{id}")
	public ResponseEntity<?> updateTransportAdmin(@PathVariable Long id, @RequestBody TransportDTO dto) {
		TransportDTO updated = transportService.updateTransportAdmin(id, dto);
		if (updated != null) {
			return ResponseEntity.ok(updated);
		} else {
			return ResponseEntity.status(404).body(Map.of("error", "Transport inexistant"));
		}
	}

	@PatchMapping("/transports/{id}/archive")
	public ResponseEntity<?> archiveTransport(@PathVariable Long id) {
		boolean archived = transportService.archiveTransport(id);
		if (archived) {
			return ResponseEntity.ok(Map.of("archived", true));
		} else {
			return ResponseEntity.status(404).body(Map.of("error", "Transport inexistant ou déjà archivé"));
		}
	}

	@PatchMapping("/transports/{id}/unarchive")
	public ResponseEntity<?> unarchiveTransport(@PathVariable Long id) {
		boolean unarchived = transportService.unarchiveTransport(id);
		if (unarchived) {
			return ResponseEntity.ok(Map.of("archived", false));
		} else {
			return ResponseEntity.status(404).body(Map.of("error", "Transport inexistant ou non archivé"));
		}
	}

	@GetMapping("/transports/search/statut")
	public ResponseEntity<?> searchTransportsByStatut(@RequestParam String statut) {
		List<TransportDTO> found = transportService.searchByStatut(statut);
		return ResponseEntity.ok(found);
	}

	// ----------- ASSIGN GP (ADMIN) -----------

	@PatchMapping("/transports/{id}/assign-gp")
	public ResponseEntity<?> assignGpToTransport(@PathVariable Long id, @RequestBody AssignGpRequest req) {
		if (req.getGpId() == null) {
			return ResponseEntity.badRequest().body(Map.of("error", "gpId requis"));
		}
		TransportDTO updated = transportService.assignGpAndValidate(id, req.getGpId(), req.getNewStatut());
		if (updated == null) {
			return ResponseEntity.status(404).body(Map.of("error", "Transport ou GP introuvable"));
		}
		return ResponseEntity.ok(updated);
	}

	@PatchMapping("/commandes/{id}/assign-gp")
	public ResponseEntity<?> assignGpToCommande(@PathVariable Long id, @RequestBody AssignGpRequest req) {
		if (req.getGpId() == null) {
			return ResponseEntity.badRequest().body(Map.of("error", "gpId requis"));
		}
		CommandeDTO updated = commandeService.assignGpAndValidate(id, req.getGpId(), req.getNewStatut());
		if (updated == null) {
			return ResponseEntity.status(404).body(Map.of("error", "Commande ou GP introuvable"));
		}
		return ResponseEntity.ok(updated);
	}
}