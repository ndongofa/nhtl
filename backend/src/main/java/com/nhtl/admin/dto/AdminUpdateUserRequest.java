package com.nhtl.admin.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class AdminUpdateUserRequest {
	private String email;
	private String phone;
	private String prenom;
	private String nom;
	private String role;
}