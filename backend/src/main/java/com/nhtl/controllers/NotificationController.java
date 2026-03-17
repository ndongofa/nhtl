package com.nhtl.controllers;

import java.security.Principal;
import java.util.List;
import java.util.Map;

import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.nhtl.dto.NotificationDTO;
import com.nhtl.services.NotificationService;

@RestController
@RequestMapping("/api/notifications")
public class NotificationController {

	private final NotificationService service;

	public NotificationController(NotificationService service) {
		this.service = service;
	}

	private String getUserId(Principal principal) {
		return principal.getName();
	}

	@PreAuthorize("isAuthenticated()")
	@GetMapping
	public ResponseEntity<List<NotificationDTO>> getMyNotifications(Principal principal) {
		return ResponseEntity.ok(service.getForUser(getUserId(principal)));
	}

	@PreAuthorize("isAuthenticated()")
	@PatchMapping("/{id}/read")
	public ResponseEntity<?> markRead(@PathVariable Long id, Principal principal) {
		boolean ok = service.markRead(id, getUserId(principal));
		if (!ok) {
			return ResponseEntity.status(403).body(Map.of("error", "Accès refusé"));
		}
		return ResponseEntity.ok(Map.of("success", true));
	}
}