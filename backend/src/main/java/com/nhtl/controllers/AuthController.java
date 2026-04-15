package com.nhtl.controllers;

import java.util.Map;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.nhtl.admin.supabase.SupabaseAdminAuthClient;
import com.nhtl.dto.auth.ForgotPasswordRequest;
import com.nhtl.dto.auth.ResetPasswordRequest;
import com.nhtl.dto.auth.VerifyOtpRequest;
import com.nhtl.services.AuthService;

@RestController
@RequestMapping("/api/auth")
public class AuthController {

	private final AuthService service;
	private final SupabaseAdminAuthClient adminAuthClient;

	public AuthController(AuthService service, SupabaseAdminAuthClient adminAuthClient) {
		this.service = service;
		this.adminAuthClient = adminAuthClient;
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

	/**
	 * Confirme un numéro de téléphone sans OTP, en cas de panne SMS (Brevo + Twilio KO).
	 * Utilise le service_role Supabase pour forcer {@code phone_confirmed_at} en base.
	 * <p>
	 * Corps attendu : {@code {"phone": "+221783042838"}}
	 */
	@PostMapping("/skip-phone-otp")
	public ResponseEntity<?> skipPhoneOtp(@RequestBody Map<String, String> body) {
		String phone = body == null ? null : body.get("phone");
		if (phone == null || phone.isBlank()) {
			return ResponseEntity.badRequest().body(Map.of("error", "Le champ 'phone' est requis."));
		}
		try {
			String userId = adminAuthClient.confirmPhoneByPhone(phone.trim()).block();
			return ResponseEntity.ok(Map.of("success", true, "userId", userId != null ? userId : ""));
		} catch (Exception e) {
			String msg = e.getMessage() != null ? e.getMessage() : "Erreur interne.";
			return ResponseEntity.status(500).body(Map.of("success", false, "error", msg));
		}
	}
}