package com.nhtl.security;

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.security.Key;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Base64;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.MediaType;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import io.jsonwebtoken.Claims;
import io.jsonwebtoken.ExpiredJwtException;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.MalformedJwtException;
import io.jsonwebtoken.UnsupportedJwtException;
import io.jsonwebtoken.security.Keys;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import lombok.extern.slf4j.Slf4j;

@Slf4j
@Component
public class SupabaseJwtFilter extends OncePerRequestFilter {

	/**
	 * Supabase JWT secret (HS256) est souvent fourni en Base64 dans les settings
	 * Supabase. Ici on conserve ton approche: Base64 decode -> hmacShaKeyFor.
	 */
	@Value("${supabase.jwt.secret}")
	private String supabaseJwtSecret;

	private static final List<String> PUBLIC_PATHS = Arrays.asList("/auth/", "/api/public/", "/actuator/health",
			"/actuator/info", "/swagger-ui/", "/v3/api-docs/", "/login", "/signup", "/api/auth/login",
			"/api/auth/register", "/api/departures/public",
			"/api/maad/produits", "/api/teranga/produits", "/api/bestseller/produits");

	@Override
	protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response, FilterChain filterChain)
			throws ServletException, IOException {

		if (shouldNotFilter(request)) {
			filterChain.doFilter(request, response);
			return;
		}

		final String authHeader = request.getHeader("Authorization");

		// Ne JAMAIS logger le JWT en clair
		log.debug("Authorization header present: {}", authHeader != null);

		if (authHeader == null || !authHeader.startsWith("Bearer ")) {
			writeJsonError(response, HttpServletResponse.SC_UNAUTHORIZED, "Token JWT manquant ou format incorrect");
			return;
		}

		final String jwt = authHeader.substring(7).trim();
		if (jwt.isEmpty()) {
			writeJsonError(response, HttpServletResponse.SC_UNAUTHORIZED, "Token JWT manquant ou format incorrect");
			return;
		}

		try {
			Claims claims = parseClaims(jwt);

			// subject = user id (uuid supabase)
			final String userId = claims.getSubject();

			// Role depuis user_metadata.role (ton choix actuel)
			final String role = extractRole(claims); // ex: USER / ADMIN

			// Authorities
			final List<GrantedAuthority> authorities = new ArrayList<>();
			authorities.add(new SimpleGrantedAuthority("ROLE_AUTHENTICATED"));
			if (role != null && !role.isBlank() && !"AUTHENTICATED".equalsIgnoreCase(role)) {
				authorities.add(new SimpleGrantedAuthority("ROLE_" + role.toUpperCase()));
			}

			// Principal = userId (comme ton code)
			UsernamePasswordAuthenticationToken authentication = new UsernamePasswordAuthenticationToken(userId, null,
					authorities);

			SecurityContextHolder.getContext().setAuthentication(authentication);

			log.debug("JWT ok userId={} authorities={}", userId,
					authorities.stream().map(GrantedAuthority::getAuthority).collect(Collectors.toList()));

		} catch (ExpiredJwtException e) {
			log.warn("Token JWT expiré : {}", e.getMessage());
			writeJsonError(response, HttpServletResponse.SC_UNAUTHORIZED, "Token JWT expiré");
			return;

		} catch (io.jsonwebtoken.security.SecurityException e) {
			log.warn("Signature JWT invalide : {}", e.getMessage());
			writeJsonError(response, HttpServletResponse.SC_UNAUTHORIZED, "Signature JWT invalide");
			return;

		} catch (MalformedJwtException | UnsupportedJwtException | IllegalArgumentException e) {
			log.warn("Token JWT invalide : {}", e.getMessage());
			writeJsonError(response, HttpServletResponse.SC_UNAUTHORIZED, "Token JWT invalide");
			return;

		} catch (Exception e) {
			log.error("Erreur inattendue d'authentification: {}", e.getMessage(), e);
			writeJsonError(response, HttpServletResponse.SC_INTERNAL_SERVER_ERROR, "Erreur interne d'authentification");
			return;
		}

		filterChain.doFilter(request, response);
	}

	private Claims parseClaims(String jwt) {
		byte[] decodedKey = Base64.getDecoder().decode(supabaseJwtSecret);
		Key key = Keys.hmacShaKeyFor(decodedKey);

		return Jwts.parserBuilder().setSigningKey(key).build().parseClaimsJws(jwt).getBody();
	}

	/**
	 * Extrait le rôle métier depuis user_metadata.role si présent. Fallback: claim
	 * "role" si présent (rare, dépend de la config).
	 */
	private String extractRole(Claims claims) {
		String role = "USER";

		Object metadataObj = claims.get("user_metadata");
		if (metadataObj instanceof Map<?, ?> meta) {
			Object roleInMeta = meta.get("role");
			if (roleInMeta != null) {
				role = roleInMeta.toString();
			}
		} else if (claims.get("role") != null) {
			role = claims.get("role").toString();
		}

		return role == null ? "USER" : role.toUpperCase();
	}

	private void writeJsonError(HttpServletResponse response, int statusCode, String message) throws IOException {
		response.setStatus(statusCode);
		response.setContentType(MediaType.APPLICATION_JSON_VALUE);
		response.setCharacterEncoding(StandardCharsets.UTF_8.name());
		response.getWriter().write("{\"error\": \"" + escapeJson(message) + "\"}");
	}

	// Évite de casser le JSON si message contient des guillemets/backslashes
	private String escapeJson(String v) {
		if (v == null) {
			return "";
		}
		return v.replace("\\", "\\\\").replace("\"", "\\\"");
	}

	@Override
	protected boolean shouldNotFilter(HttpServletRequest request) {
		if ("OPTIONS".equalsIgnoreCase(request.getMethod())) {
			return true;
		}
		String path = request.getRequestURI();
		return PUBLIC_PATHS.stream().anyMatch(path::startsWith);
	}
}