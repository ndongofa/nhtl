package com.nhtl.admin.controller;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

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

	@PostMapping
	public ResponseEntity<String> create(@Valid @RequestBody AdminCreateUserRequest req) {
		String json = supabaseAdminAuthClient.createUser(req).block();
		return ResponseEntity.ok(json);
	}

	@PatchMapping("/{id}")
	public ResponseEntity<String> update(@PathVariable("id") String id, @RequestBody AdminUpdateUserRequest req) {
		String json = supabaseAdminAuthClient.updateUser(id, req).block();
		return ResponseEntity.ok(json);
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