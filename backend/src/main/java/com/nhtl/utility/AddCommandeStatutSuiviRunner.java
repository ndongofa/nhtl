package com.nhtl.utility;

import org.springframework.boot.CommandLineRunner;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Component;

@Component
public class AddCommandeStatutSuiviRunner implements CommandLineRunner {

    private final JdbcTemplate jdbcTemplate;

    public AddCommandeStatutSuiviRunner(JdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate;
    }

    @Override
    public void run(String... args) {

        try {
            jdbcTemplate.execute(
                "ALTER TABLE commandes " +
                "ADD COLUMN IF NOT EXISTS statut_suivi_commande VARCHAR(30) " +
                "NOT NULL DEFAULT 'EN_ATTENTE'"
            );
            System.out.println("✅ [Migration] Colonne statut_suivi_commande OK");
        } catch (Exception ex) {
            System.out.println("⚠️ [Migration] ADD COLUMN statut_suivi_commande : "
                    + ex.getMessage());
        }

        try {
            jdbcTemplate.execute(
                "CREATE INDEX IF NOT EXISTS idx_commandes_statut_suivi " +
                "ON commandes(statut_suivi_commande)"
            );
            System.out.println("✅ [Migration] Index statut_suivi_commande OK");
        } catch (Exception ex) {
            System.out.println("⚠️ [Migration] Index statut_suivi_commande : "
                    + ex.getMessage());
        }

        try {
            int count = jdbcTemplate.update(
                "UPDATE commandes SET statut_suivi_commande = 'EN_ATTENTE' " +
                "WHERE statut_suivi_commande IS NULL OR statut_suivi_commande = ''"
            );
            if (count > 0) {
                System.out.println("✅ [Migration] " + count
                        + " commande(s) initialisée(s) à EN_ATTENTE");
            }
        } catch (Exception ex) {
            System.out.println("⚠️ [Migration] UPDATE statut_suivi_commande : "
                    + ex.getMessage());
        }
    }
}