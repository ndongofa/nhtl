package com.nhtl.services;

import java.util.HashMap;
import java.util.Map;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.nhtl.dto.auth.LoginRequest;
import com.nhtl.dto.auth.LoginResponse;
import com.nhtl.dto.auth.SignupRequest;
import com.nhtl.dto.auth.SignupResponse;
import com.nhtl.notifications.NotificationDispatcher;
import com.nhtl.notifications.NotificationTemplates;
import com.nhtl.security.JwtTokenProvider;

@Service
public class AuthService {

	@Autowired
	private JwtTokenProvider jwtTokenProvider;

	@Autowired
	private RestTemplate restTemplate;

	@Value("${supabase.url:https://your-supabase-url.supabase.co}")
	private String supabaseUrl;

	@Value("${supabase.anon-key:your-anon-key}")
	private String supabaseAnonKey;

	@Autowired
	private NotificationDispatcher notificationDispatcher;

	@Autowired
	private NotificationTemplates templates;

	/**
	 * Login avec email ou téléphone
	 */
	public LoginResponse login(LoginRequest request) throws Exception {
		System.out.println("1️⃣ Début login pour: " + request.getIdentifier());

		// 1. Récupérer l'utilisateur depuis Supabase
		String userId = getUserIdFromSupabase(request.getIdentifier());

		System.out.println("2️⃣ userId trouvé: " + userId);

		if (userId == null) {
			throw new Exception("Identifiant ou mot de passe incorrect");
		}

		// 2. Vérifier le mot de passe
		System.out.println("3️⃣ Vérification du mot de passe...");
		boolean isPasswordValid = verifyPasswordWithSupabase(request.getIdentifier(), request.getPassword());

		System.out.println("4️⃣ Mot de passe valide: " + isPasswordValid);

		if (!isPasswordValid) {
			throw new Exception("Identifiant ou mot de passe incorrect");
		}

		// 3. Récupérer les infos utilisateur complètes
		System.out.println("5️⃣ Récupération des infos utilisateur...");
		Map<String, Object> userInfo = getUserInfoFromSupabase(request.getIdentifier());

		// 4. Générer les tokens JWT
		System.out.println("6️⃣ Génération des tokens JWT...");
		String accessToken = jwtTokenProvider.generateAccessToken(userId, (String) userInfo.get("email"),
				(String) userInfo.get("role"));
		String refreshToken = jwtTokenProvider.generateRefreshToken(userId);

		// 5. Créer la réponse
		LoginResponse response = new LoginResponse();
		response.setUserId(userId);
		response.setEmail((String) userInfo.get("email"));
		response.setPhone((String) userInfo.get("phone"));
		response.setFullName((String) userInfo.get("fullName"));
		response.setRole((String) userInfo.get("role"));
		response.setAccessToken(accessToken);
		response.setRefreshToken(refreshToken);
		response.setExpiresIn(86400); // 24 heures

		System.out.println("7️⃣ Login réussi!");
		return response;
	}

	/**
	 * Signup/Registration
	 */
	public SignupResponse signup(SignupRequest request) throws Exception {
		System.out.println(
				"1️⃣ Début signup pour: " + (request.getEmail() != null ? request.getEmail() : request.getPhone()));

		// 1. Vérifier les mots de passe
		if (!request.getPassword().equals(request.getConfirmPassword())) {
			throw new Exception("Les mots de passe ne correspondent pas");
		}

		// 2. Créer l'utilisateur dans Supabase
		String userId = createUserInSupabase(request);

		if (userId == null) {
			throw new Exception("Erreur lors de la création de l'utilisateur");
		}

		System.out.println("2️⃣ Utilisateur créé avec l'ID: " + userId);

		// ✅ 2bis. Notifications (ne doit jamais casser le signup)
		try {
			notificationDispatcher.dispatch(templates.signupValidated(userId, request.getEmail(), request.getPhone()));
		} catch (Exception e) {
			System.out.println("⚠️ Notification signup échouée: " + e.getMessage());
		}

		// 3. Créer la réponse
		SignupResponse response = new SignupResponse();
		response.setUserId(userId);
		response.setEmail(request.getEmail());
		response.setPhone(request.getPhone());
		response.setUsername(request.getUsername());
		response.setMessage("Inscription réussie! Vous pouvez maintenant vous connecter.");

		System.out.println("3️⃣ Signup réussi!");
		return response;
	}

	/**
	 * Envoyer un OTP pour reset password (Email OU Téléphone) Appelle la fonction
	 * Supabase send_reset_otp
	 */
	public void sendResetOtp(String identifier) throws Exception {
		System.out.println("1️⃣ Envoi OTP pour: " + identifier);

		// 1. Vérifier que l'utilisateur existe
		Map<String, Object> userInfo = getUserInfoFromSupabase(identifier);
		if (userInfo == null) {
			throw new Exception("Utilisateur non trouvé");
		}

		System.out.println("2️⃣ Utilisateur trouvé!");

		// 2. Appeler la fonction Supabase send_reset_otp
		try {
			String url = supabaseUrl + "/rest/v1/rpc/send_reset_otp";

			HttpHeaders headers = new HttpHeaders();
			headers.setContentType(MediaType.APPLICATION_JSON);
			headers.set("apikey", supabaseAnonKey);
			headers.set("Authorization", "Bearer " + supabaseAnonKey);

			String body = "{\"p_identifier\":\"" + escapeJson(identifier) + "\"}";
			HttpEntity<String> entity = new HttpEntity<>(body, headers);

			System.out.println("🔐 Appel send_reset_otp avec: " + body);

			String response = restTemplate.postForObject(url, entity, String.class);

			System.out.println("📥 Réponse send_reset_otp: " + response);

			ObjectMapper mapper = new ObjectMapper();
			JsonNode root = mapper.readTree(response);

			String otp = null;
			boolean success = false;

			if (root.isArray() && root.size() > 0) {
				JsonNode item = root.get(0);
				success = item.has("success") && item.get("success").asBoolean(false);
				otp = item.has("otp") ? item.get("otp").asText() : null;
			} else if (root.isObject()) {
				success = root.has("success") && root.get("success").asBoolean(false);
				otp = root.has("otp") ? root.get("otp").asText() : null;
			}

			if (success && otp != null) {
				System.out.println("3️⃣ ✅ OTP généré: " + otp);

				// 3. Envoyer par email ou SMS (COMPORTEMENT EXISTANT => conservé)
				if (identifier.contains("@")) {
					sendOtpEmail(identifier, otp);
					System.out.println("4️⃣ 📧 OTP envoyé à l'email: " + identifier);
				} else {
					sendOtpSms(identifier, otp);
					System.out.println("4️⃣ 📱 OTP envoyé au téléphone: " + identifier);
				}

				// ✅ 4bis. Notifications centralisées (ne doit jamais casser)
				try {
					String userId = (String) userInfo.get("id");
					String email = (String) userInfo.get("email");
					String phone = (String) userInfo.get("phone");

					notificationDispatcher.dispatch(templates.passwordResetOtpSent(userId, email, phone, otp));
				} catch (Exception e) {
					System.out.println("⚠️ Notification reset OTP échouée: " + e.getMessage());
				}

			} else {
				throw new Exception("Erreur lors de la génération de l'OTP");
			}

		} catch (Exception e) {
			System.out.println("❌ Erreur send_reset_otp: " + e.getMessage());
			e.printStackTrace();
			throw new Exception("Erreur lors de l'envoi de l'OTP: " + e.getMessage());
		}
	}

	/**
	 * Vérifier l'OTP (Email OU Téléphone) Appelle la fonction Supabase verify_otp
	 */
	public boolean verifyOtp(String identifier, String otp) throws Exception {
		System.out.println("1️⃣ Vérification OTP pour: " + identifier);

		try {
			String url = supabaseUrl + "/rest/v1/rpc/verify_otp";

			HttpHeaders headers = new HttpHeaders();
			headers.setContentType(MediaType.APPLICATION_JSON);
			headers.set("apikey", supabaseAnonKey);
			headers.set("Authorization", "Bearer " + supabaseAnonKey);

			String body = "{\"p_identifier\":\"" + escapeJson(identifier) + "\",\"p_otp\":\"" + escapeJson(otp) + "\"}";
			HttpEntity<String> entity = new HttpEntity<>(body, headers);

			System.out.println("🔐 Appel verify_otp avec: " + body);

			String response = restTemplate.postForObject(url, entity, String.class);

			System.out.println("📥 Réponse verify_otp: " + response);

			ObjectMapper mapper = new ObjectMapper();
			JsonNode root = mapper.readTree(response);

			boolean success = false;
			String error = null;

			if (root.isArray() && root.size() > 0) {
				JsonNode item = root.get(0);
				success = item.has("success") && item.get("success").asBoolean(false);
				error = item.has("error") ? item.get("error").asText() : null;
			} else if (root.isObject()) {
				success = root.has("success") && root.get("success").asBoolean(false);
				error = root.has("error") ? root.get("error").asText() : null;
			}

			if (success) {
				System.out.println("✅ OTP valide!");
				return true;
			} else {
				System.out.println("❌ OTP invalide: " + error);
				throw new Exception(error != null ? error : "OTP invalide ou expiré");
			}

		} catch (Exception e) {
			System.out.println("❌ Erreur verify_otp: " + e.getMessage());
			throw new Exception("Erreur lors de la vérification de l'OTP: " + e.getMessage());
		}
	}

	/**
	 * Reset password avec OTP (Email OU Téléphone) Appelle la fonction Supabase
	 * reset_password
	 */
	public void resetPassword(String identifier, String otp, String newPassword) throws Exception {
		System.out.println("1️⃣ Réinitialisation du mot de passe pour: " + identifier);

		try {
			String url = supabaseUrl + "/rest/v1/rpc/reset_password";

			HttpHeaders headers = new HttpHeaders();
			headers.setContentType(MediaType.APPLICATION_JSON);
			headers.set("apikey", supabaseAnonKey);
			headers.set("Authorization", "Bearer " + supabaseAnonKey);

			String body = "{\"p_identifier\":\"" + escapeJson(identifier) + "\",\"p_otp\":\"" + escapeJson(otp)
					+ "\",\"p_new_password\":\"" + escapeJson(newPassword) + "\"}";
			HttpEntity<String> entity = new HttpEntity<>(body, headers);

			System.out.println("🔐 Appel reset_password avec identifier=" + identifier);

			String response = restTemplate.postForObject(url, entity, String.class);

			System.out.println("📥 Réponse reset_password: " + response);

			ObjectMapper mapper = new ObjectMapper();
			JsonNode root = mapper.readTree(response);

			boolean success = false;
			String error = null;

			if (root.isArray() && root.size() > 0) {
				JsonNode item = root.get(0);
				success = item.has("success") && item.get("success").asBoolean(false);
				error = item.has("error") ? item.get("error").asText() : null;
			} else if (root.isObject()) {
				success = root.has("success") && root.get("success").asBoolean(false);
				error = root.has("error") ? root.get("error").asText() : null;
			}

			if (success) {
				System.out.println("2️⃣ ✅ Mot de passe réinitialisé!");

				// ✅ notification succès reset (ne doit jamais casser)
				try {
					Map<String, Object> userInfo = getUserInfoFromSupabase(identifier);
					String userId = userInfo != null ? (String) userInfo.get("id") : null;
					String email = userInfo != null ? (String) userInfo.get("email") : null;
					String phone = userInfo != null ? (String) userInfo.get("phone") : null;

					notificationDispatcher.dispatch(templates.passwordResetSuccess(userId, email, phone));
				} catch (Exception e) {
					System.out.println("⚠️ Notification reset success échouée: " + e.getMessage());
				}

			} else {
				throw new Exception(error != null ? error : "Erreur lors de la réinitialisation du mot de passe");
			}

		} catch (Exception e) {
			System.out.println("❌ Erreur reset_password: " + e.getMessage());
			e.printStackTrace();
			throw new Exception("Erreur lors de la réinitialisation: " + e.getMessage());
		}
	}

	/**
	 * Refresh Token
	 */
	public String refreshToken(String refreshToken) throws Exception {
		System.out.println("1️⃣ Refresh token");

		// 1. Valider le refresh token
		if (!jwtTokenProvider.validateToken(refreshToken)) {
			throw new Exception("Refresh token invalide");
		}

		System.out.println("2️⃣ Refresh token valide!");

		// 2. Extraire l'userId
		String userId = jwtTokenProvider.extractUserId(refreshToken);

		System.out.println("3️⃣ userId extrait: " + userId);

		// 3. Récupérer les infos utilisateur
		Map<String, Object> userInfo = getUserInfoFromSupabaseById(userId);

		System.out.println("4️⃣ Infos utilisateur récupérées!");

		// 4. Générer un nouveau access token
		String newAccessToken = jwtTokenProvider.generateAccessToken(userId, (String) userInfo.get("email"),
				(String) userInfo.get("role"));

		System.out.println("5️⃣ ✅ Nouveau access token généré!");
		return newAccessToken;
	}

	// ==================== MÉTHODES UTILITAIRES ====================

	/**
	 * Échapper les caractères spéciaux JSON
	 */
	private String escapeJson(String input) {
		if (input == null) {
			return "";
		}
		return input.replace("\\", "\\\\").replace("\"", "\\\"").replace("\n", "\\n").replace("\r", "\\r").replace("\t",
				"\\t");
	}

	// ==================== MÉTHODES SUPABASE ====================

	/**
	 * Récupérer l'ID utilisateur depuis Supabase
	 */
	private String getUserIdFromSupabase(String identifier) {
		try {
			HttpHeaders headers = new HttpHeaders();
			headers.set("apikey", supabaseAnonKey);
			headers.set("Authorization", "Bearer " + supabaseAnonKey);
			headers.setContentType(MediaType.APPLICATION_JSON);

			// ✅ Construire l'URL avec URLEncoder pour les caractères spéciaux
			String encodedIdentifier = java.net.URLEncoder.encode(identifier, java.nio.charset.StandardCharsets.UTF_8);

			String url;
			if (identifier.contains("@")) {
				url = supabaseUrl + "/rest/v1/users?select=id&email=eq." + encodedIdentifier;
			} else {
				url = supabaseUrl + "/rest/v1/users?select=id&phone_number=eq." + encodedIdentifier;
			}

			System.out.println("🔍 URL: " + url);
			System.out.println("🔍 Identifier: " + identifier);
			System.out.println("🔍 Identifier encodé: " + encodedIdentifier);

			HttpEntity<String> entity = new HttpEntity<>(headers);

			// ✅ Utiliser URI.create pour éviter le double encodage
			HttpEntity<String> response = restTemplate.exchange(java.net.URI.create(url),
					org.springframework.http.HttpMethod.GET, entity, String.class);

			System.out.println("📥 Réponse brute: " + response.getBody());

			ObjectMapper mapper = new ObjectMapper();
			JsonNode root = mapper.readTree(response.getBody());

			System.out.println("📊 Taille: " + (root.isArray() ? root.size() : "pas array"));

			if (root.isArray() && root.size() > 0) {
				String id = root.get(0).get("id").asText();
				System.out.println("✅ ID trouvé: " + id);
				return id;
			}

			System.out.println("❌ Aucun utilisateur trouvé!");
			return null;
		} catch (Exception e) {
			System.out.println("❌ Erreur: " + e.getMessage());
			e.printStackTrace();
			return null;
		}
	}

	/**
	 * Récupérer les infos utilisateur complets
	 */
	private Map<String, Object> getUserInfoFromSupabase(String identifier) {
		try {
			HttpHeaders headers = new HttpHeaders();
			headers.set("apikey", supabaseAnonKey);
			headers.set("Authorization", "Bearer " + supabaseAnonKey);
			headers.setContentType(MediaType.APPLICATION_JSON);

			// ✅ Construire l'URL avec URLEncoder
			String encodedIdentifier = java.net.URLEncoder.encode(identifier, java.nio.charset.StandardCharsets.UTF_8);

			String url;
			if (identifier.contains("@")) {
				url = supabaseUrl + "/rest/v1/users?select=*&email=eq." + encodedIdentifier;
			} else {
				url = supabaseUrl + "/rest/v1/users?select=*&phone_number=eq." + encodedIdentifier;
			}

			System.out.println("🔍 getUserInfoFromSupabase URL: " + url);
			System.out.println("🔍 Identifier encodé: " + encodedIdentifier);

			HttpEntity<String> entity = new HttpEntity<>(headers);

			// ✅ Utiliser URI.create pour éviter le double encodage
			HttpEntity<String> response = restTemplate.exchange(java.net.URI.create(url),
					org.springframework.http.HttpMethod.GET, entity, String.class);

			System.out.println("📥 Réponse: " + response.getBody());

			ObjectMapper mapper = new ObjectMapper();
			JsonNode root = mapper.readTree(response.getBody());

			if (root.isArray() && root.size() > 0) {
				JsonNode user = root.get(0);
				Map<String, Object> result = new HashMap<>();
				result.put("id", user.get("id").asText());
				result.put("email", user.has("email") ? user.get("email").asText() : "");
				result.put("phone", user.has("phone_number") ? user.get("phone_number").asText() : "");
				result.put("fullName", user.has("full_name") ? user.get("full_name").asText() : "");
				result.put("role", user.has("role") ? user.get("role").asText() : "user");
				result.put("passwordHash", user.has("password_hash") ? user.get("password_hash").asText() : "");

				System.out.println("✅ Utilisateur trouvé!");
				return result;
			}

			System.out.println("❌ Aucun utilisateur trouvé!");
			return null;
		} catch (Exception e) {
			System.out.println("❌ Erreur: " + e.getMessage());
			e.printStackTrace();
			return null;
		}
	}

	/**
	 * Récupérer les infos utilisateur par ID
	 */
	private Map<String, Object> getUserInfoFromSupabaseById(String userId) {
		try {
			HttpHeaders headers = new HttpHeaders();
			headers.set("apikey", supabaseAnonKey);
			headers.set("Authorization", "Bearer " + supabaseAnonKey);
			headers.setContentType(MediaType.APPLICATION_JSON);

			String url = supabaseUrl + "/rest/v1/users?select=*&id=eq." + userId;

			HttpEntity<String> entity = new HttpEntity<>(headers);

			// ✅ Utiliser URI.create
			HttpEntity<String> response = restTemplate.exchange(java.net.URI.create(url),
					org.springframework.http.HttpMethod.GET, entity, String.class);

			ObjectMapper mapper = new ObjectMapper();
			JsonNode root = mapper.readTree(response.getBody());

			if (root.isArray() && root.size() > 0) {
				JsonNode user = root.get(0);
				Map<String, Object> result = new HashMap<>();
				result.put("id", user.get("id").asText());
				result.put("email", user.has("email") ? user.get("email").asText() : "");
				result.put("phone", user.has("phone_number") ? user.get("phone_number").asText() : "");
				result.put("fullName", user.has("full_name") ? user.get("full_name").asText() : "");
				result.put("role", user.has("role") ? user.get("role").asText() : "user");
				return result;
			}

			return null;
		} catch (Exception e) {
			System.out.println("Erreur getUserInfoFromSupabaseById: " + e.getMessage());
			return null;
		}
	}

	/**
	 * Vérifier le mot de passe avec Supabase
	 */
	private boolean verifyPasswordWithSupabase(String identifier, String password) {
		try {
			String url = supabaseUrl + "/rest/v1/rpc/login_user";

			HttpHeaders headers = new HttpHeaders();
			headers.setContentType(MediaType.APPLICATION_JSON);
			headers.set("apikey", supabaseAnonKey);
			headers.set("Authorization", "Bearer " + supabaseAnonKey);

			String body = "{\"p_identifier\":\"" + escapeJson(identifier) + "\",\"p_password\":\""
					+ escapeJson(password) + "\"}";
			HttpEntity<String> entity = new HttpEntity<>(body, headers);

			System.out.println("🔐 Appel login_user avec: " + body);

			try {
				String response = restTemplate.postForObject(url, entity, String.class);

				System.out.println("🔐 Réponse login_user: " + response);

				ObjectMapper mapper = new ObjectMapper();
				JsonNode root = mapper.readTree(response);

				boolean success = false;
				if (root.isArray() && root.size() > 0) {
					JsonNode item = root.get(0);
					if (item.has("success")) {
						success = item.get("success").asBoolean(false);
					}
				} else if (root.isObject()) {
					if (root.has("success")) {
						success = root.get("success").asBoolean(false);
					}
				}

				System.out.println("🔐 Résultat: " + success);
				return success;
			} catch (org.springframework.web.client.HttpClientErrorException e) {
				// ✅ Gérer l'erreur 300 Multiple Choices
				if (e.getStatusCode().value() == 300) {
					System.out.println("⚠️ Erreur 300 Multiple Choices - Function overloading issue");
					System.out.println("⚠️ Réponse: " + e.getResponseBodyAsString());
				}
				System.out.println("❌ Erreur HTTP: " + e.getMessage());
				return false;
			}
		} catch (Exception e) {
			System.out.println("❌ Erreur login_user: " + e.getMessage());
			e.printStackTrace();
			return false;
		}
	}

	/**
	 * Créer un utilisateur dans Supabase
	 */
	private String createUserInSupabase(SignupRequest request) {
		try {
			String url = supabaseUrl + "/rest/v1/rpc/register_user";

			HttpHeaders headers = new HttpHeaders();
			headers.setContentType(MediaType.APPLICATION_JSON);
			headers.set("apikey", supabaseAnonKey);
			headers.set("Authorization", "Bearer " + supabaseAnonKey);

			// Déterminer la méthode d'authentification
			String authMethod = request.getEmail() != null ? "email" : "phone";
			String identifier = authMethod.equals("email") ? request.getEmail() : request.getPhone();

			String body = "{\"p_identifier\":\"" + escapeJson(identifier) + "\",\"p_password\":\""
					+ escapeJson(request.getPassword()) + "\",\"p_auth_method\":\"" + authMethod
					+ "\",\"p_role\":\"user\"}";
			HttpEntity<String> entity = new HttpEntity<>(body, headers);

			System.out.println("📤 Envoi à Supabase: " + body);

			String response = restTemplate.postForObject(url, entity, String.class);

			System.out.println("📥 Réponse Supabase: " + response);

			ObjectMapper mapper = new ObjectMapper();
			JsonNode root = mapper.readTree(response);

			System.out.println("📊 Structure: " + root.toPrettyString());

			if (root.isArray() && root.size() > 0) {
				JsonNode item = root.get(0);
				if (item.has("success") && item.get("success").asBoolean(false)) {
					return item.get("user_id").asText();
				}
			} else if (root.isObject()) {
				if (root.has("success") && root.get("success").asBoolean(false)) {
					return root.get("user_id").asText();
				}
			}

			return null;
		} catch (Exception e) {
			System.out.println("❌ Erreur lors de la création: " + e.getMessage());
			e.printStackTrace();
			return null;
		}
	}

	/**
	 * Envoyer un OTP par email
	 */
	private void sendOtpEmail(String email, String otp) {
		// À implémenter avec JavaMailSender
		System.out.println("📧 OTP pour " + email + ": " + otp);
	}

	/**
	 * Envoyer un OTP par SMS
	 */
	private void sendOtpSms(String phone, String otp) {
		// À implémenter avec un service SMS (Twilio, etc.)
		System.out.println("📱 OTP pour " + phone + ": " + otp);
	}
}