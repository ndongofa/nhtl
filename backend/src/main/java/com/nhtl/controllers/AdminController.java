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

    // Création d'un user admin via Supabase (POST)
    @PostMapping("/admin/users")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<?> createUserForAdmin(@RequestBody Map<String, String> userInfos) {
        String email = userInfos.get("email");
        String password = userInfos.get("password");
        String name = userInfos.get("name");
        String role = userInfos.getOrDefault("role", "user");

        Map<String, Object> body = new HashMap<>();
        body.put("email", email);
        body.put("password", password);
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
            return ResponseEntity.status(HttpStatus.CREATED).body(response.getBody());
        } catch (Exception e) {
            String message = e.getMessage();
            if (message != null && (message.contains("duplicate key value") || message.contains("User already registered"))) {
                return ResponseEntity.status(HttpStatus.CONFLICT)
                        .body(Map.of("error", "Cet email est déjà utilisé."));
            }
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(Map.of("error", "Erreur Supabase: "+message));
        }
    }
}