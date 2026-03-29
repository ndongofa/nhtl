package com.nhtl.controllers;

import java.util.Arrays;
import java.util.List;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.nhtl.models.StatutCommande;

@RestController
@RequestMapping("/api/statuts-commandes")
public class StatutCommandeController {

	// --- Endpoint GET pour la liste des statuts ---
	@GetMapping
	public ResponseEntity<List<String>> getStatutsCommandes() {
		List<String> statuts = Arrays.stream(StatutCommande.values()).map(Enum::name).toList();
		return ResponseEntity.ok(statuts);
	}
}