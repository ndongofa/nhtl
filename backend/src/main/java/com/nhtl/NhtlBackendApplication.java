package com.nhtl;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.web.client.RestTemplateBuilder;
import org.springframework.context.annotation.Bean;
import org.springframework.web.client.RestTemplate;

import jakarta.annotation.PostConstruct;

@SpringBootApplication
public class NhtlBackendApplication {

    public static void main(String[] args) {
        SpringApplication.run(NhtlBackendApplication.class, args);
    }
    
    @Bean
    public RestTemplate restTemplate(RestTemplateBuilder builder) {
        return builder.build();
    }
    @PostConstruct
    public void checkEnv() {
        System.getenv().forEach((key, value) -> {
            if (key.contains("SUPABASE")) {
                System.out.println(key + " = " + value);
            }
        });
    }

}