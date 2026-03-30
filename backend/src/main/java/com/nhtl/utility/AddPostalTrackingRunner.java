package com.nhtl.utility;

import org.springframework.boot.CommandLineRunner;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Component;

/**
 * Migration automatique — ajoute les colonnes de suivi postal
 * sur les tables transports et commandes.
 */
@Component
public class AddPostalTrackingRunner implements CommandLineRunner {

    private final JdbcTemplate jdbc;

    public AddPostalTrackingRunner(JdbcTemplate jdbc) {
        this.jdbc = jdbc;
    }

    @Override
    public void run(String... args) {
        migrateTable("transports");
        migrateTable("commandes");
    }

    private void migrateTable(String table) {
        String[][] columns = {
            {"photo_colis_url",     "TEXT"},
            {"photo_bordereau_url", "TEXT"},
            {"numero_bordereau",    "VARCHAR(100)"},
            {"depose_poste_at",     "TIMESTAMP"},
        };
        for (String[] col : columns) {
            try {
                jdbc.execute("ALTER TABLE " + table
                    + " ADD COLUMN IF NOT EXISTS "
                    + col[0] + " " + col[1]);
                System.out.println("✅ [Migration] " + table + "." + col[0] + " OK");
            } catch (Exception e) {
                System.out.println("⚠️ [Migration] " + table + "."
                    + col[0] + " : " + e.getMessage());
            }
        }
    }
}