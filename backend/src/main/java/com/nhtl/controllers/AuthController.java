package com.nhtl.controllers;

import java.util.Map;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.nhtl.dto.auth.ForgotPasswordRequest;
import com.nhtl.dto.auth.ResetPasswordRequest;
import com.nhtl.dto.auth.VerifyOtpRequest;
import com.nhtl.services.AuthService;

@RestController
@RequestMapping("/api/auth")
public class AuthController {

	private final AuthService service;

	public AuthController(AuthService service) {
		this.service = service;
	}

	@PostMapping("/reset/otp")
	public ResponseEntity<?> sendResetOtp(@RequestBody ForgotPasswordRequest req) throws Exception {
		service.sendResetOtp(req.getIdentifier());
		return ResponseEntity.ok(Map.of("success", true));
	}

	@PostMapping("/reset/verify")
	public ResponseEntity<?> verifyOtp(@RequestBody VerifyOtpRequest req) throws Exception {
		boolean ok = service.verifyOtp(req.getIdentifier(), req.getOtp());
		return ResponseEntity.ok(Map.of("success", ok));
	}

	@PostMapping("/reset/password")
	public ResponseEntity<?> resetPassword(@RequestBody ResetPasswordRequest req) throws Exception {
		service.resetPassword(req.getIdentifier(), req.getOtp(), req.getNewPassword());
		return ResponseEntity.ok(Map.of("success", true));
	}
}