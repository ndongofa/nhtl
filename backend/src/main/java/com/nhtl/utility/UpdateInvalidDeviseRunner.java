//package com.nhtl.utility;
//
//import org.springframework.boot.CommandLineRunner;
//import org.springframework.jdbc.core.JdbcTemplate;
//import org.springframework.stereotype.Component;
//
//@Component
//public class UpdateInvalidDeviseRunner implements CommandLineRunner {
//    private final JdbcTemplate jdbcTemplate;
//
//    public UpdateInvalidDeviseRunner(JdbcTemplate jdbcTemplate) {
//        this.jdbcTemplate = jdbcTemplate;
//    }
//
//    @Override
//    public void run(String... args) {
//        try {
//            int count = jdbcTemplate.update(
//                "UPDATE transport SET devise = 'XAF'::devise_enum " +
//                "WHERE devise IS NULL OR devise NOT IN ('XAF', 'USD', 'EUR', 'GBP', 'CAD')"
//            );
//            System.out.println("✅ " + count + " transport corrigés pour la colonne 'devise'");
//        } catch (Exception ex) {
//            System.out.println("Erreur correction devise: " + ex.getMessage());
//        }
//    }
//}