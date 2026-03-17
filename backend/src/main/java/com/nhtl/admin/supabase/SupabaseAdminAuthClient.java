package com.nhtl.admin.supabase;

import java.util.HashMap;
import java.util.Map;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Component;
import org.springframework.web.reactive.function.client.WebClient;
import org.springframework.web.reactive.function.client.WebClientResponseException;

import com.nhtl.admin.dto.AdminCreateUserRequest;
import com.nhtl.admin.dto.AdminResetPasswordRequest;
import com.nhtl.admin.dto.AdminUpdateUserRequest;

import lombok.RequiredArgsConstructor;
import reactor.core.publisher.Mono;

@Component
@RequiredArgsConstructor
public class SupabaseAdminAuthClient {

	private final WebClient.Builder webClientBuilder;

	// Aligné sur tes application-*.properties
	@Value("${supabase.project.url}")
	private String supabaseProjectUrl;

	@Value("${supabase.service.role.key}")
	private String supabaseServiceRoleKey;

	private static boolean looksLikeEmail(String v) {
		return v != null && v.contains("@");
	}

	private static boolean looksLikeE164Phone(String v) {
		return v != null && v.matches("^\\+[1-9]\\d{7,14}$");
	}

	private WebClient client() {
		return webClientBuilder.baseUrl(supabaseProjectUrl)
				.defaultHeader(HttpHeaders.AUTHORIZATION, "Bearer " + supabaseServiceRoleKey)
				.defaultHeader("apikey", supabaseServiceRoleKey)
				.defaultHeader(HttpHeaders.CONTENT_TYPE, MediaType.APPLICATION_JSON_VALUE).build();
	}

	public Mono<String> createUser(AdminCreateUserRequest req) {
		final String identifier = req.getIdentifier() == null ? "" : req.getIdentifier().trim();

		Map<String, Object> body = new HashMap<>();
		body.put("password", req.getPassword());

		Map<String, Object> userMeta = new HashMap<>();
		userMeta.put("prenom", req.getPrenom());
		userMeta.put("nom", req.getNom());
		userMeta.put("role", req.getRole());
		body.put("user_metadata", userMeta);

		if (looksLikeEmail(identifier)) {
			body.put("email", identifier.toLowerCase());
			body.put("email_confirm", true);
		} else {
			if (!looksLikeE164Phone(identifier)) {
				return Mono.error(
						new IllegalArgumentException("Téléphone invalide. Format attendu E.164, ex: +221783042838"));
			}
			body.put("phone", identifier);
			body.put("phone_confirm", true);
		}

		return client().post().uri("/auth/v1/admin/users").bodyValue(body).retrieve().bodyToMono(String.class)
				.onErrorResume(WebClientResponseException.class,
						e -> Mono.error(new RuntimeException("Supabase error: " + e.getResponseBodyAsString(), e)));
	}

	public Mono<String> updateUser(String userId, AdminUpdateUserRequest req) {
		Map<String, Object> body = new HashMap<>();

		if (req.getEmail() != null && !req.getEmail().isBlank()) {
			body.put("email", req.getEmail().trim().toLowerCase());
		}
		if (req.getPhone() != null && !req.getPhone().isBlank()) {
			body.put("phone", req.getPhone().trim());
		}

		Map<String, Object> userMeta = new HashMap<>();
		if (req.getPrenom() != null) {
			userMeta.put("prenom", req.getPrenom());
		}
		if (req.getNom() != null) {
			userMeta.put("nom", req.getNom());
		}
		if (req.getRole() != null) {
			userMeta.put("role", req.getRole());
		}
		if (!userMeta.isEmpty()) {
			body.put("user_metadata", userMeta);
		}

		return client().put().uri("/auth/v1/admin/users/{id}", userId).bodyValue(body).retrieve()
				.bodyToMono(String.class).onErrorResume(WebClientResponseException.class,
						e -> Mono.error(new RuntimeException("Supabase error: " + e.getResponseBodyAsString(), e)));
	}

	public Mono<Void> deleteUser(String userId) {
		return client().delete().uri("/auth/v1/admin/users/{id}", userId).retrieve().bodyToMono(Void.class)
				.onErrorResume(WebClientResponseException.class,
						e -> Mono.error(new RuntimeException("Supabase error: " + e.getResponseBodyAsString(), e)));
	}

	public Mono<String> resetPassword(String userId, AdminResetPasswordRequest req) {
		Map<String, Object> body = new HashMap<>();
		body.put("password", req.getNewPassword());

		return client().put().uri("/auth/v1/admin/users/{id}", userId).bodyValue(body).retrieve()
				.bodyToMono(String.class).onErrorResume(WebClientResponseException.class,
						e -> Mono.error(new RuntimeException("Supabase error: " + e.getResponseBodyAsString(), e)));
	}
}