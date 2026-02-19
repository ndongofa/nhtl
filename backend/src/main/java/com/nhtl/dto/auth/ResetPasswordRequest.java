package com.nhtl.dto.auth;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class ResetPasswordRequest {
    
    @NotBlank(message = "Email ou téléphone requis")
    private String identifier;  // Email OU Téléphone
    
    @NotBlank(message = "OTP requis")
    @Size(min = 6, max = 6, message = "OTP doit être 6 chiffres")
    private String otp;
    
    @NotBlank(message = "Nouveau mot de passe requis")
    @Size(min = 8, message = "Mot de passe minimum 8 caractères")
    private String newPassword;
}