package com.nhtl.dto.auth;

import jakarta.validation.constraints.NotBlank;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class LoginRequest {
    
    @NotBlank(message = "Identifiant (email ou téléphone) est requis")
    private String identifier; // Email ou téléphone
    
    @NotBlank(message = "Mot de passe est requis")
    private String password;
}