package com.nhtl.security;

import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.SignatureAlgorithm;
import io.jsonwebtoken.security.Keys;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import javax.crypto.SecretKey;
import java.util.Date;
import java.util.HashMap;
import java.util.Map;

@Component
public class JwtTokenProvider {
    
    @Value("${jwt.secret:your-secret-key-change-this-in-production-at-least-32-characters}")
    private String jwtSecret;
    
    @Value("${jwt.expiration:86400000}")
    private long jwtExpiration; // 24 heures par défaut
    
    @Value("${jwt.refresh-expiration:604800000}")
    private long refreshExpiration; // 7 jours par défaut
    
    /**
     * Générer un Access Token
     */
    public String generateAccessToken(String userId, String email, String role) {
        Map<String, Object> claims = new HashMap<>();
        claims.put("email", email);
        claims.put("role", role);
        
        return createToken(claims, userId, jwtExpiration);
    }
    
    /**
     * Générer un Refresh Token
     */
    public String generateRefreshToken(String userId) {
        Map<String, Object> claims = new HashMap<>();
        return createToken(claims, userId, refreshExpiration);
    }
    
    /**
     * Créer un token JWT
     */
    private String createToken(Map<String, Object> claims, String subject, long expiration) {
        SecretKey key = Keys.hmacShaKeyFor(jwtSecret.getBytes());
        
        return Jwts.builder()
                .setClaims(claims)
                .setSubject(subject)
                .setIssuedAt(new Date())
                .setExpiration(new Date(System.currentTimeMillis() + expiration))
                .signWith(key, SignatureAlgorithm.HS256)
                .compact();
    }
    
    /**
     * Extraire l'userId du token
     */
    public String extractUserId(String token) {
        try {
            SecretKey key = Keys.hmacShaKeyFor(jwtSecret.getBytes());
            return Jwts.parserBuilder()
                    .setSigningKey(key)
                    .build()
                    .parseClaimsJws(token)
                    .getBody()
                    .getSubject();
        } catch (Exception e) {
            return null;
        }
    }
    
    /**
     * Valider un token
     */
    public boolean validateToken(String token) {
        try {
            SecretKey key = Keys.hmacShaKeyFor(jwtSecret.getBytes());
            Jwts.parserBuilder()
                    .setSigningKey(key)
                    .build()
                    .parseClaimsJws(token);
            return true;
        } catch (Exception e) {
            return false;
        }
    }
    
    /**
     * Extraire l'email du token
     */
    public String extractEmail(String token) {
        try {
            SecretKey key = Keys.hmacShaKeyFor(jwtSecret.getBytes());
            return (String) Jwts.parserBuilder()
                    .setSigningKey(key)
                    .build()
                    .parseClaimsJws(token)
                    .getBody()
                    .get("email");
        } catch (Exception e) {
            return null;
        }
    }
    
    /**
     * Extraire le role du token
     */
    public String extractRole(String token) {
        try {
            SecretKey key = Keys.hmacShaKeyFor(jwtSecret.getBytes());
            return (String) Jwts.parserBuilder()
                    .setSigningKey(key)
                    .build()
                    .parseClaimsJws(token)
                    .getBody()
                    .get("role");
        } catch (Exception e) {
            return null;
        }
    }
}