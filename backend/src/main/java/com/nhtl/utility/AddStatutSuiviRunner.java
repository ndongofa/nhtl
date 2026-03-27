package com.nhtl.utility;

import org.springframework.boot.CommandLineRunner;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Component;

/**
 * Ajoute la colonne statut_suivi à la table transports au démarrage de
 * l'application si elle n'existe pas encore (migration idempotente).
 *
 * ✅ Exécuté une seule fois : ADD COLUMN IF NOT EXISTS est sans effet
 *    si la colonne existe déjà.
 * ✅ Initialise les lignes existantes à 'EN_ATTENTE'.
 * ✅ Compatible PostgreSQL (Railway).
 *
 * Copier dans : backend/src/main/java/com/nhtl/utility/AddStatutSuiviRunner.java
 */
@Component
public class AddStatutSuiviRunner implements CommandLineRunner {

    private final JdbcTemplate jdbcTemplate;

    public AddStatutSuiviRunner(JdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate;
    }

    @Override
    public void run(String... args) {

        // 1 — Ajouter la colonne si elle n'existe pas
        try {
            jdbcTemplate.execute(
                "ALTER TABLE transports " +
                "ADD COLUMN IF NOT EXISTS statut_suivi VARCHAR(30) NOT NULL DEFAULT 'EN_ATTENTE'"
            );
            System.out.println("✅ [Migration] Colonne statut_suivi OK (ajoutée ou déjà présente)");
        } catch (Exception ex) {
            System.out.println("⚠️ [Migration] ADD COLUMN statut_suivi : " + ex.getMessage());
        }

        // 2 — Index pour les requêtes admin par statut
        try {
            jdbcTemplate.execute(
                "CREATE INDEX IF NOT EXISTS idx_transports_statut_suivi " +
                "ON transports(statut_suivi)"
            );
            System.out.println("✅ [Migration] Index idx_transports_statut_suivi OK");
        } catch (Exception ex) {
            System.out.println("⚠️ [Migration] CREATE INDEX statut_suivi : " + ex.getMessage());
        }

        // 3 — Corriger les lignes NULL (sécurité)
        try {
            int count = jdbcTemplate.update(
                "UPDATE transports SET statut_suivi = 'EN_ATTENTE' " +
                "WHERE statut_suivi IS NULL OR statut_suivi = ''"
            );
            if (count > 0) {
                System.out.println("✅ [Migration] " + count + " ligne(s) initialisée(s) à EN_ATTENTE");
            }
        } catch (Exception ex) {
            System.out.println("⚠️ [Migration] UPDATE statut_suivi NULL : " + ex.getMessage());
        }
    }
}