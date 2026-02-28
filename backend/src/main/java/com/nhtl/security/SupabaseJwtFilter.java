package com.nhtl.security;

import io.jsonwebtoken.Claims;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.ExpiredJwtException;
import io.jsonwebtoken.MalformedJwtException;
import io.jsonwebtoken.UnsupportedJwtException;
import io.jsonwebtoken.security.Keys;
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
import java.security.Key;
import java.util.*;
import java.util.Base64;

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
                                    FilterChain filterChain)
            throws ServletException, IOException {

        if (shouldNotFilter(request)) {
            filterChain.doFilter(request, response);
            return;
        }

        String authHeader = request.getHeader("Authorization");

        if (authHeader == null || !authHeader.startsWith("Bearer ")) {
            response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
            response.setContentType("application/json");
            response.getWriter().write("{\"error\": \"Token JWT manquant ou format incorrect\"}");
            return;
        }

        String jwt = authHeader.substring(7);

        try {
            // 🔐 Décodage Base64 du secret Supabase (HS256)
            byte[] decodedKey = Base64.getDecoder().decode(supabaseJwtSecret);
            Key key = Keys.hmacShaKeyFor(decodedKey);

            Claims claims = Jwts.parserBuilder()
                    .setSigningKey(key)
                    .build()
                    .parseClaimsJws(jwt)
                    .getBody();

            String userId = claims.getSubject();

            // 🎯 Extraction et normalisation du rôle ("user", "admin", "authenticated"...)
            String role = "USER";
            if (claims.get("role") != null) {
                role = claims.get("role").toString().toUpperCase();
            }

            List<GrantedAuthority> authorities = new ArrayList<>();
            // Toujours ajouter AUTHENTICATED pour toutes les personnes connectées
            authorities.add(new SimpleGrantedAuthority("ROLE_AUTHENTICATED"));

            // Ajouter des rôles métiers supplémentaires s'ils sont présents (user, admin, etc.)
            if (!role.equals("AUTHENTICATED")) {
                authorities.add(new SimpleGrantedAuthority("ROLE_" + role));
            }

            UsernamePasswordAuthenticationToken authentication =
                    new UsernamePasswordAuthenticationToken(userId, null, authorities);

            SecurityContextHolder.getContext().setAuthentication(authentication);

            log.info("JWT valide et authentifié pour user: {} avec rôles: {}", userId, authorities);

        } catch (ExpiredJwtException e) {
            response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
            response.setContentType("application/json");
            response.getWriter().write("{\"error\": \"Token JWT expiré\"}");
            return;

        } catch (io.jsonwebtoken.security.SecurityException e) {
            response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
            response.setContentType("application/json");
            response.getWriter().write("{\"error\": \"Signature JWT invalide\"}");
            return;

        } catch (MalformedJwtException | UnsupportedJwtException | IllegalArgumentException e) {
            response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
            response.setContentType("application/json");
            response.getWriter().write("{\"error\": \"Token JWT invalide\"}");
            return;

        } catch (Exception e) {
            log.error("Erreur inattendue: {}", e.getMessage());
            response.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
            response.setContentType("application/json");
            response.getWriter().write("{\"error\": \"Erreur interne d'authentification\"}");
            return;
        }

        filterChain.doFilter(request, response);
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