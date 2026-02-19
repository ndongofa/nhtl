package com.nhtl.controllers;

import com.nhtl.services.AuthService;
import com.nhtl.dto.auth.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.*;

import jakarta.validation.Valid;
import java.util.HashMap;
import java.util.Map;

@RestController
@RequestMapping("/api/auth")
@Validated
@CrossOrigin(origins = "*", maxAge = 3600)
public class AuthController {
    
    @Autowired
    private AuthService authService;
    
    /**
     * Login avec email ou téléphone
     * POST /api/auth/login
     */
    @PostMapping("/login")
    public ResponseEntity<Map<String, Object>> login(@Valid @RequestBody LoginRequest loginRequest) {
        try {
            LoginResponse response = authService.login(loginRequest);
            Map<String, Object> result = new HashMap<>();
            result.put("success", true);
            result.put("message", "Connexion réussie");
            result.put("data", response);
            return ResponseEntity.ok(result);
        } catch (Exception e) {
            Map<String, Object> result = new HashMap<>();
            result.put("success", false);
            result.put("message", e.getMessage());
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(result);
        }
    }
    
    /**
     * Signup/Registration
     * POST /api/auth/signup
     */
    @PostMapping("/signup")
    public ResponseEntity<Map<String, Object>> signup(@Valid @RequestBody SignupRequest signupRequest) {
        try {
            SignupResponse response = authService.signup(signupRequest);
            Map<String, Object> result = new HashMap<>();
            result.put("success", true);
            result.put("message", "Inscription réussie");
            result.put("data", response);
            return ResponseEntity.status(HttpStatus.CREATED).body(result);
        } catch (Exception e) {
            Map<String, Object> result = new HashMap<>();
            result.put("success", false);
            result.put("message", e.getMessage());
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(result);
        }
    }
    
    /**
     * Forgot Password - Demander un reset (Email OU Téléphone)
     * POST /api/auth/forgot-password
     */
    @PostMapping("/forgot-password")
    public ResponseEntity<Map<String, Object>> forgotPassword(@Valid @RequestBody ForgotPasswordRequest request) {
        try {
            authService.sendResetOtp(request.getIdentifier());
            Map<String, Object> result = new HashMap<>();
            result.put("success", true);
            result.put("message", "OTP envoyé!");
            return ResponseEntity.ok(result);
        } catch (Exception e) {
            Map<String, Object> result = new HashMap<>();
            result.put("success", false);
            result.put("message", e.getMessage());
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(result);
        }
    }
    
    /**
     * Verify OTP - Vérifier le code OTP (Email OU Téléphone)
     * POST /api/auth/verify-otp
     */
    @PostMapping("/verify-otp")
    public ResponseEntity<Map<String, Object>> verifyOtp(@Valid @RequestBody VerifyOtpRequest request) {
        try {
            boolean isValid = authService.verifyOtp(request.getIdentifier(), request.getOtp());
            Map<String, Object> result = new HashMap<>();
            result.put("success", isValid);
            result.put("message", isValid ? "OTP valide" : "OTP invalide ou expiré");
            return ResponseEntity.ok(result);
        } catch (Exception e) {
            Map<String, Object> result = new HashMap<>();
            result.put("success", false);
            result.put("message", e.getMessage());
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(result);
        }
    }
    
    /**
     * Reset Password - Réinitialiser le mot de passe (Email OU Téléphone)
     * POST /api/auth/reset-password
     */
    @PostMapping("/reset-password")
    public ResponseEntity<Map<String, Object>> resetPassword(@Valid @RequestBody ResetPasswordRequest request) {
        try {
            authService.resetPassword(request.getIdentifier(), request.getOtp(), request.getNewPassword());
            Map<String, Object> result = new HashMap<>();
            result.put("success", true);
            result.put("message", "Mot de passe réinitialisé avec succès");
            return ResponseEntity.ok(result);
        } catch (Exception e) {
            Map<String, Object> result = new HashMap<>();
            result.put("success", false);
            result.put("message", e.getMessage());
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(result);
        }
    }
    
    /**
     * Refresh Token
     * POST /api/auth/refresh-token
     */
    @PostMapping("/refresh-token")
    public ResponseEntity<Map<String, Object>> refreshToken(@Valid @RequestBody RefreshTokenRequest request) {
        try {
            String newToken = authService.refreshToken(request.getRefreshToken());
            Map<String, Object> result = new HashMap<>();
            result.put("success", true);
            result.put("message", "Token rafraîchi");
            result.put("data", new TokenResponse(newToken));
            return ResponseEntity.ok(result);
        } catch (Exception e) {
            Map<String, Object> result = new HashMap<>();
            result.put("success", false);
            result.put("message", e.getMessage());
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(result);
        }
    }
}