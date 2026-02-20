package com.nhtl.config;

import com.zaxxer.hikari.HikariDataSource;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import javax.sql.DataSource;
import java.net.URI;

/**
 * Configuration du DataSource pour Railway/Postgres.
 * Convertit DATABASE_URL en JDBC automatiquement.
 */
@Configuration
public class DataSourceConfig {

    @Bean
    public DataSource dataSource() {
        String dbUrl = System.getenv("DATABASE_URL");
        if (dbUrl != null && dbUrl.startsWith("postgres")) {
            try {
                URI uri = new URI(dbUrl);

                // Récupère user/password
                String[] userInfo = uri.getUserInfo().split(":");
                String username = userInfo[0];
                String password = userInfo[1];

                // Construit l'URL JDBC
                String jdbcUrl = "jdbc:postgresql://" + uri.getHost() + ":" + uri.getPort() + uri.getPath();

                HikariDataSource ds = new HikariDataSource();
                ds.setJdbcUrl(jdbcUrl);
                ds.setUsername(username);
                ds.setPassword(password);
                ds.setDriverClassName("org.postgresql.Driver");

                return ds;
            } catch (Exception e) {
                throw new RuntimeException("Erreur lors de la conversion de DATABASE_URL", e);
            }
        }

        throw new RuntimeException("DATABASE_URL non définie ou invalide");
    }
}