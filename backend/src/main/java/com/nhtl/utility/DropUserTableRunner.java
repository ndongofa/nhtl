//package com.nhtl.utility;
//import org.springframework.boot.CommandLineRunner;
//import org.springframework.jdbc.core.JdbcTemplate;
//import org.springframework.stereotype.Component;
//
//@Component
//public class DropUserTableRunner implements CommandLineRunner {
//    private final JdbcTemplate jdbcTemplate;
//
//    public DropUserTableRunner(JdbcTemplate jdbcTemplate) {
//        this.jdbcTemplate = jdbcTemplate;
//    }
//
//    @Override
//    public void run(String... args) {
//        try {
//            jdbcTemplate.execute("DROP TABLE IF EXISTS users");
//            System.out.println("✅ Table users supprimée !");
//        } catch (Exception ex) {
//            System.out.println("Erreur suppression table users: " + ex.getMessage());
//        }
//    }
////}