package com.nhtl.controllers;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.*;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.client.RestTemplate;

import java.util.HashMap;
import java.util.Map;

@RestController
public class AdminController {

    @Value("${supabase.project.url}") 
    private String supabaseProjectUrl;

    @Value("${supabase.service.role.key}") 
    private String supabaseServiceRoleKey;

    private final RestTemplate restTemplate = new RestTemplate();

    @PostMapping("/admin/users")
    @PreAuthorize("hasRole('ADMIN')") // Sécurité Spring
    public ResponseEntity<?> createUserForAdmin(@RequestBody Map<String, String> userInfos) {
        String email = userInfos.get("email");
        String password = userInfos.get("password");
        String name = userInfos.get("name");
        String role = userInfos.getOrDefault("role", "user");

        // Construction du body pour Supabase Auth Admin REST API
        Map<String, Object> body = new HashMap<>();
        body.put("email", email);
        body.put("password", password);
        // Attention, c'est "user_metadata" dans Supabase
        Map<String, String> userMeta = new HashMap<>();
        userMeta.put("full_name", name);
        userMeta.put("role", role);
        body.put("user_metadata", userMeta);

        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_JSON);
        headers.setBearerAuth(supabaseServiceRoleKey);

        HttpEntity<Map<String, Object>> entity = new HttpEntity<>(body, headers);

        String url = supabaseProjectUrl + "/auth/v1/admin/users"; 

        try {
            ResponseEntity<Map> response = restTemplate.postForEntity(url, entity, Map.class);
            // Propagation au front : retourne l'utilisateur créé et "201 created"
            return ResponseEntity.status(HttpStatus.CREATED).body(response.getBody());
        } catch (Exception e) {
            // Gérer les erreurs Supabase, e.g. email already used, etc.
            String message = e.getMessage();
            if (message.contains("duplicate key value") || message.contains("User already registered")) {
                return ResponseEntity.status(HttpStatus.CONFLICT)
                        .body(Map.of("error", "Cet email est déjà utilisé."));
            }
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(Map.of("error", "Erreur Supabase: "+message));
        }
    }
}