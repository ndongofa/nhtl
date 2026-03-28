package com.nhtl.utility;

import org.springframework.boot.CommandLineRunner;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Component;

@Component
public class AddDeparturesTableRunner implements CommandLineRunner {

    private final JdbcTemplate jdbcTemplate;

    public AddDeparturesTableRunner(JdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate;
    }

    @Override
    public void run(String... args) {

        try {
            jdbcTemplate.execute(
                "CREATE TABLE IF NOT EXISTS departures (" +
                "  id BIGSERIAL PRIMARY KEY," +
                "  route VARCHAR(255) NOT NULL," +
                "  point_depart VARCHAR(255) NOT NULL," +
                "  point_arrivee VARCHAR(255) NOT NULL," +
                "  flag_emoji VARCHAR(50) NOT NULL," +
                "  departure_date_time TIMESTAMP NOT NULL," +
                "  status VARCHAR(20) NOT NULL DEFAULT 'DRAFT'," +
                "  created_at TIMESTAMP," +
                "  updated_at TIMESTAMP" +
                ")"
            );
            System.out.println("✅ [Migration] Table departures OK");
        } catch (Exception ex) {
            System.out.println("⚠️ [Migration] CREATE TABLE departures : " + ex.getMessage());
        }

        try {
            jdbcTemplate.execute(
                "CREATE INDEX IF NOT EXISTS idx_departures_status_datetime " +
                "ON departures(status, departure_date_time)"
            );
            System.out.println("✅ [Migration] Index departures OK");
        } catch (Exception ex) {
            System.out.println("⚠️ [Migration] Index departures : " + ex.getMessage());
        }
    }
}