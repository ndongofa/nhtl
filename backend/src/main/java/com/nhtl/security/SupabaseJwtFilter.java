package com.nhtl.security;

import io.jsonwebtoken.Claims;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.SignatureException;
import io.jsonwebtoken.ExpiredJwtException;
import io.jsonwebtoken.MalformedJwtException;
import io.jsonwebtoken.UnsupportedJwtException;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.util.*;

@Slf4j
@Component
public class SupabaseJwtFilter extends OncePerRequestFilter {

    @Value("${supabase.jwt.secret}")
    private String supabaseJwtSecret;

    private static final List<String> PUBLIC_PATHS = Arrays.asList(
        "/auth/",
        "/api/public/",
        "/actuator/health",
        "/actuator/info",
        "/swagger-ui/",
        "/v3/api-docs/",
        "/login",
        "/signup"
    );

    @Override
    protected void doFilterInternal(HttpServletRequest request,
                                    HttpServletResponse response,
                                    FilterChain filterChain) throws ServletException, IOException {

        String path = request.getRequestURI();

        if (shouldNotFilter(request)) {
            filterChain.doFilter(request, response);
            return;
        }

        String authHeader = request.getHeader("Authorization");

        if (authHeader == null || !authHeader.startsWith("Bearer ")) {
            log.debug("Token JWT manquant ou format incorrect pour: {}", path);
            response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
            response.setContentType("application/json");
            response.getWriter().write("{\"error\": \"Token JWT manquant ou format incorrect\"}");
            return;
        }

        String jwt = authHeader.substring(7);

        try {
            Claims claims = Jwts.parser()
                    .setSigningKey(supabaseJwtSecret.getBytes(StandardCharsets.UTF_8))
                    .parseClaimsJws(jwt)
                    .getBody();

            String userId = claims.getSubject();
            String email = claims.get("email", String.class);

            if (userId == null) {
                log.warn("Token JWT sans subject (userId)");
                response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
                response.getWriter().write("{\"error\": \"Token JWT invalide: userId manquant\"}");
                return;
            }

            String role = extractUserRole(claims);
            String username = email != null ? email : userId;

            List<GrantedAuthority> authorities = new ArrayList<>();
            authorities.add(new SimpleGrantedAuthority("ROLE_" + role.toUpperCase()));
            addAdditionalAuthorities(claims, authorities);

            UsernamePasswordAuthenticationToken authentication =
                    new UsernamePasswordAuthenticationToken(username, null, authorities);

            SecurityContextHolder.getContext().setAuthentication(authentication);

            log.debug("Utilisateur authentifié: {}, rôle: {}", username, role);

        } catch (ExpiredJwtException e) {
            log.warn("Token JWT expiré: {}", e.getMessage());
            response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
            response.getWriter().write("{\"error\": \"Token JWT expiré\"}");
            return;
        } catch (SignatureException e) {
            log.error("Signature JWT invalide: {}", e.getMessage());
            response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
            response.getWriter().write("{\"error\": \"Signature JWT invalide\"}");
            return;
        } catch (MalformedJwtException | UnsupportedJwtException | IllegalArgumentException e) {
            log.error("Token JWT invalide: {}", e.getMessage());
            response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
            response.getWriter().write("{\"error\": \"Token JWT invalide\"}");
            return;
        } catch (Exception e) {
            log.error("Erreur inattendue lors de la validation JWT: {}", e.getMessage());
            response.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
            response.getWriter().write("{\"error\": \"Erreur interne d'authentification\"}");
            return;
        }

        filterChain.doFilter(request, response);
    }

    private String extractUserRole(Claims claims) {
        String role = "user";
        try {
            Object metaObj = claims.get("user_metadata");
            if (metaObj instanceof Map) {
                Object foundRole = ((Map<?, ?>) metaObj).get("role");
                if (foundRole != null) {
                    role = foundRole.toString().toLowerCase();
                    log.debug("Rôle trouvé dans user_metadata: {}", role);
                    return role;
                }
            }
            Object appMetaObj = claims.get("app_metadata");
            if (appMetaObj instanceof Map) {
                Object foundRole = ((Map<?, ?>) appMetaObj).get("role");
                if (foundRole != null) {
                    role = foundRole.toString().toLowerCase();
                    log.debug("Rôle trouvé dans app_metadata: {}", role);
                    return role;
                }
            }
            if (claims.get("role") != null) {
                role = claims.get("role").toString().toLowerCase();
                log.debug("Rôle trouvé dans claim direct: {}", role);
            }
        } catch (Exception e) {
            log.warn("Erreur lors de l'extraction du rôle: {}", e.getMessage());
        }
        log.debug("Rôle par défaut utilisé: {}", role);
        return role;
    }

    private void addAdditionalAuthorities(Claims claims, List<GrantedAuthority> authorities) {
        Boolean emailVerified = claims.get("email_verified", Boolean.class);
        if (Boolean.TRUE.equals(emailVerified)) {
            authorities.add(new SimpleGrantedAuthority("EMAIL_VERIFIED"));
        }
        String provider = claims.get("provider", String.class);
        if (provider != null) {
            authorities.add(new SimpleGrantedAuthority("PROVIDER_" + provider.toUpperCase()));
        }
    }

    @Override
    protected boolean shouldNotFilter(HttpServletRequest request) {
        String path = request.getRequestURI();
        if ("OPTIONS".equalsIgnoreCase(request.getMethod())) {
            return true;
        }
        return PUBLIC_PATHS.stream().anyMatch(path::startsWith);
    }
}