//package com.nhtl.utility;
//
//import org.springframework.boot.CommandLineRunner;
//import org.springframework.jdbc.core.JdbcTemplate;
//import org.springframework.stereotype.Component;
//
///**
// * Corrige les commandes ayant le statut "modifie" au démarrage de l'application.
// * Remplace par "EN_ATTENTE".
// */
//@Component
//public class UpdateModifieStatutRunner implements CommandLineRunner {
//    private final JdbcTemplate jdbcTemplate;
//
//    public UpdateModifieStatutRunner(JdbcTemplate jdbcTemplate) {
//        this.jdbcTemplate = jdbcTemplate;
//    }
//
//    @Override
//    public void run(String... args) {
//        try {
//            int count = jdbcTemplate.update(
//            		"UPDATE commandes SET statut = 'EN_ATTENTE' WHERE statut = 'StatutExemple'"
//            );
//            System.out.println("✅ " + count + " commandes corrigées du statut 'StatutExemple'");
//        } catch (Exception ex) {
//            System.out.println("Erreur correction statut StatutExemple: " + ex.getMessage());
//        }
//    }
//}
