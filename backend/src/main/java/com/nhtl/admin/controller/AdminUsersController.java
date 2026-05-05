package com.nhtl.admin.controller;

import java.util.Map;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.nhtl.admin.dto.AdminCreateUserRequest;
import com.nhtl.admin.dto.AdminResetPasswordRequest;
import com.nhtl.admin.dto.AdminUpdateUserRequest;
import com.nhtl.admin.supabase.SupabaseAdminAuthClient;

import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;

@RestController
@RequestMapping("/api/admin/users")
@RequiredArgsConstructor
public class AdminUsersController {

	private final SupabaseAdminAuthClient supabaseAdminAuthClient;
	private final ObjectMapper objectMapper;

	@PostMapping
	public ResponseEntity<String> create(@Valid @RequestBody AdminCreateUserRequest req) {
		String json = supabaseAdminAuthClient.createUser(req).block();
		return ResponseEntity.ok(json);
	}

	@PatchMapping("/{id}")
	public ResponseEntity<String> update(@PathVariable("id") String id, @RequestBody AdminUpdateUserRequest req) {
		try {
			String json = supabaseAdminAuthClient.updateUser(id, req).block();
			return ResponseEntity.ok(json);
		} catch (IllegalArgumentException e) {
			return buildError(HttpStatus.BAD_REQUEST, e.getMessage());
		} catch (RuntimeException e) {
			String msg = e.getMessage() != null ? e.getMessage() : "Erreur interne du serveur";
			return buildError(HttpStatus.INTERNAL_SERVER_ERROR, msg);
		}
	}

	private ResponseEntity<String> buildError(HttpStatus status, String message) {
		try {
			return ResponseEntity.status(status)
					.body(objectMapper.writeValueAsString(Map.of("error", message)));
		} catch (JsonProcessingException ex) {
			return ResponseEntity.status(status).body("{\"error\":\"Erreur interne\"}");
		}
	}

	@DeleteMapping("/{id}")
	public ResponseEntity<Void> delete(@PathVariable("id") String id) {
		supabaseAdminAuthClient.deleteUser(id).block();
		return ResponseEntity.noContent().build();
	}

	@PostMapping("/{id}/reset-password")
	public ResponseEntity<String> resetPassword(@PathVariable("id") String id,
			@Valid @RequestBody AdminResetPasswordRequest req) {
		String json = supabaseAdminAuthClient.resetPassword(id, req).block();
		return ResponseEntity.ok(json);
	}
}