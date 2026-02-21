package com.nhtl.config;

import javax.sql.DataSource;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Profile;

import com.zaxxer.hikari.HikariConfig;
import com.zaxxer.hikari.HikariDataSource;

@Configuration
public class DataSourceConfig {

    // Configuration pour PROD / Railway
    @Bean
    @Profile("prod")
    public DataSource prodDataSource() {
        // Check très simple pour valider que Railway injecte bien les variables du backend service
        String check = System.getenv("ENV_CHECK");
        System.out.println("[ENV] ENV_CHECK=" + check);

        String jdbcUrl = System.getenv("DATABASE_URL");
        String pgHost = System.getenv("PGHOST");
        String pgUser = System.getenv("PGUSER");

        System.out.println("[ENV] DATABASE_URL present=" + (jdbcUrl != null && !jdbcUrl.isBlank()));
        System.out.println("[ENV] PGHOST present=" + (pgHost != null && !pgHost.isBlank()));
        System.out.println("[ENV] PGUSER present=" + (pgUser != null && !pgUser.isBlank()));

        if (jdbcUrl != null) {
            String safe = jdbcUrl.replaceAll("password=[^&]+", "password=***");
            System.out.println("[ENV] DATABASE_URL value=" + safe);
        }

        if (jdbcUrl == null || jdbcUrl.isEmpty()) {
            throw new RuntimeException("DATABASE_URL non définie ou invalide");
        }

        HikariConfig config = new HikariConfig();
        config.setJdbcUrl(jdbcUrl);
        config.setMaximumPoolSize(10);
        config.setMinimumIdle(2);
        config.setPoolName("HikariCP");

        return new HikariDataSource(config);
    }

    // Configuration pour DEV local (H2)
    @Bean
    @Profile("dev")
    public DataSource devDataSource() {
        HikariConfig config = new HikariConfig();
        config.setJdbcUrl("jdbc:h2:mem:nhtldb;DB_CLOSE_DELAY=-1;DB_CLOSE_ON_EXIT=FALSE");
        config.setDriverClassName("org.h2.Driver");
        config.setUsername("sa");
        config.setPassword("");
        config.setMaximumPoolSize(5);
        config.setPoolName("H2Pool");
        return new HikariDataSource(config);
    }
}