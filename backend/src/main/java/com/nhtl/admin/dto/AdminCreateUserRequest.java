package com.nhtl.admin.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class AdminCreateUserRequest {
	@NotBlank
	private String identifier; // email OU téléphone E.164

	@NotBlank
	private String password;

	@NotBlank
	private String prenom;

	@NotBlank
	private String nom;

	@NotBlank
	private String role; // admin | user
}