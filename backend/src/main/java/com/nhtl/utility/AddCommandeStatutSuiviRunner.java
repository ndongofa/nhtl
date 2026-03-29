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

        // 1️⃣ Ajouter la colonne si elle n'existe pas
        try {
            jdbcTemplate.execute(
                "ALTER TABLE commandes " +
                "ADD COLUMN IF NOT EXISTS statut_suivi_commande VARCHAR(30)"
            );
            System.out.println("✅ [Migration] Colonne statut_suivi_commande créée (si inexistante)");
        } catch (Exception ex) {
            System.out.println("⚠️ [Migration] ADD COLUMN statut_suivi_commande : " + ex.getMessage());
        }

        // 2️⃣ Remplir les lignes existantes avec une valeur par défaut
        try {
            int count = jdbcTemplate.update(
                "UPDATE commandes SET statut_suivi_commande = 'EN_ATTENTE' " +
                "WHERE statut_suivi_commande IS NULL OR statut_suivi_commande = ''"
            );
            if (count > 0) {
                System.out.println("✅ [Migration] " + count + " commande(s) initialisée(s) à EN_ATTENTE");
            } else {
                System.out.println("ℹ️ [Migration] Toutes les commandes ont déjà une valeur");
            }
        } catch (Exception ex) {
            System.out.println("⚠️ [Migration] UPDATE statut_suivi_commande : " + ex.getMessage());
        }

        // 3️⃣ Ajouter la contrainte NOT NULL
        try {
            jdbcTemplate.execute(
                "ALTER TABLE commandes " +
                "ALTER COLUMN statut_suivi_commande SET NOT NULL"
            );
            System.out.println("✅ [Migration] Contrainte NOT NULL appliquée");
        } catch (Exception ex) {
            System.out.println("⚠️ [Migration] NOT NULL statut_suivi_commande : " + ex.getMessage());
        }

        // 4️⃣ Ajouter la contrainte CHECK
        try {
            jdbcTemplate.execute(
                "ALTER TABLE commandes " +
                "ADD CONSTRAINT IF NOT EXISTS statut_suivi_commande_check " +
                "CHECK (statut_suivi_commande IN (" +
                "'EN_ATTENTE','COMMANDE_CONFIRMEE','EN_TRANSIT','EN_DOUANE','ARRIVE','PRET_LIVRAISON','LIVREE'))"
            );
            System.out.println("✅ [Migration] Contrainte CHECK appliquée");
        } catch (Exception ex) {
            System.out.println("⚠️ [Migration] CHECK statut_suivi_commande : " + ex.getMessage());
        }

        // 5️⃣ Ajouter l'index
        try {
            jdbcTemplate.execute(
                "CREATE INDEX IF NOT EXISTS idx_commandes_statut_suivi " +
                "ON commandes(statut_suivi_commande)"
            );
            System.out.println("✅ [Migration] Index statut_suivi_commande OK");
        } catch (Exception ex) {
            System.out.println("⚠️ [Migration] Index statut_suivi_commande : " + ex.getMessage());
        }
    }
}