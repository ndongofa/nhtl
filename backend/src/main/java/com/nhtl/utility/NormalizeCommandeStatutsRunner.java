package com.nhtl.utility;

import org.springframework.boot.CommandLineRunner;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Component;

@Component
public class NormalizeCommandeStatutsRunner implements CommandLineRunner {

	private final JdbcTemplate jdbcTemplate;

	public NormalizeCommandeStatutsRunner(JdbcTemplate jdbcTemplate) {
		this.jdbcTemplate = jdbcTemplate;
	}

	@Override
	public void run(String... args) {
		try {
			int total = 0;

			total += jdbcTemplate
					.update("update commandes set statut = 'CONFIRMEE' where statut in ('CONFIRMÉE','CONFIRMEE')");
			total += jdbcTemplate
					.update("update commandes set statut = 'EXPEDIEE' where statut in ('EXPEDIÉE','EXPEDIEE')");
			total += jdbcTemplate
					.update("update commandes set statut = 'LIVREE' where statut in ('LIVRÉ','LIVREE','LIVRE')");
			total += jdbcTemplate
					.update("update commandes set statut = 'ANNULEE' where statut in ('ANNULÉE','ANNULEE')");
			total += jdbcTemplate
					.update("update commandes set statut = 'REMBOURSEE' where statut in ('REMBOURSÉE','REMBOURSEE')");

			System.out.println("✅ Normalisation statuts commandes terminée. Total modifié = " + total);

		} catch (Exception ex) {
			System.out.println("❌ Erreur normalisation statuts commandes: " + ex.getMessage());
		}
	}
}