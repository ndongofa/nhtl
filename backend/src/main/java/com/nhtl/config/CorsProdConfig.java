package com.nhtl.config;

import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Profile;
import org.springframework.web.servlet.config.annotation.CorsRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

@Configuration
@Profile("prod")
public class CorsProdConfig implements WebMvcConfigurer {

    @Override
    public void addCorsMappings(CorsRegistry registry) {
        // Mapping pour les endpoints API classiques
        registry.addMapping("/api/**")
            .allowedOrigins(
                "https://nhtl-production-46e3.up.railway.app"   // ← ton front prod Railway
                // Ajoute ici tous tes autres domaines autorisés si besoin
            )
            .allowedMethods("GET", "POST", "PUT", "DELETE", "OPTIONS")
            .allowedHeaders("*")
            .allowCredentials(false)
            .maxAge(3600);

        // Mapping pour les endpoints admin
        registry.addMapping("/admin/**")
            .allowedOrigins(
                "https://nhtl-production-46e3.up.railway.app"   // ← ton front prod Railway
                // Ajoute ici tous tes autres domaines autorisés si besoin
            )
            .allowedMethods("GET", "POST", "PUT", "DELETE", "OPTIONS")
            .allowedHeaders("*")
            .allowCredentials(false)
            .maxAge(3600);
    }
}