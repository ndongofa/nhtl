package com.nhtl.dto.auth;

import jakarta.validation.constraints.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class SignupRequest {
    
    @Email(message = "Email invalide")
    private String email;
    
    @Pattern(regexp = "^\\+?[1-9]\\d{1,14}$", message = "Téléphone invalide")
    private String phone;
    
    @NotBlank(message = "Nom d'utilisateur requis")
    @Size(min = 3, max = 50, message = "Username entre 3 et 50 caractères")
    private String username;
    
    @NotBlank(message = "Nom complet requis")
    private String fullName;
    
    @NotBlank(message = "Mot de passe requis")
    @Size(min = 8, message = "Mot de passe minimum 8 caractères")
    private String password;
    
    @NotBlank(message = "Confirmation mot de passe requis")
    private String confirmPassword;
    
    // Validation personnalisée: email OU phone requis
    @AssertTrue(message = "Email ou téléphone requis")
    private boolean isEmailOrPhonePresent() {
        return (email != null && !email.isEmpty()) || (phone != null && !phone.isEmpty());
    }
}