package com.nhtl.repositories;

import java.time.LocalDateTime;
import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import com.nhtl.models.Commande;

@Repository
public interface CommandeRepository extends JpaRepository<Commande, Long> {
	// Toutes les commandes pour un user
	List<Commande> findByUserId(String userId);

	// Trouver les commandes par statut
	List<Commande> findByStatut(String statut);

	// Trouver les commandes par plateforme
	List<Commande> findByPlateforme(String plateforme);

	// Trouver les commandes par numéro de téléphone
	List<Commande> findByNumeroTelephone(String numeroTelephone);

	// Trouver les commandes par pays
	List<Commande> findByPaysLivraison(String paysLivraison);

	// Commandes créées dans une période
	@Query("SELECT c FROM Commande c WHERE c.dateCreation BETWEEN :debut AND :fin")
	List<Commande> findCommandesByDateRange(@Param("debut") LocalDateTime debut, @Param("fin") LocalDateTime fin);

	// Chercher par nom et prénom
	@Query("SELECT c FROM Commande c WHERE LOWER(c.nom) LIKE LOWER(CONCAT('%', :nom, '%')) OR LOWER(c.prenom) LIKE LOWER(CONCAT('%', :prenom, '%'))")
	List<Commande> searchByNomOrPrenom(@Param("nom") String nom, @Param("prenom") String prenom);

	// Commandes par plateforme et statut
	@Query("SELECT c FROM Commande c WHERE c.plateforme = :plateforme AND c.statut = :statut")
	List<Commande> findByPlateformeAndStatut(@Param("plateforme") String plateforme, @Param("statut") String statut);

	// Variante pour filtrer par userId
	List<Commande> findByStatutAndUserId(String statut, String userId);

	List<Commande> findByPlateformeAndUserId(String plateforme, String userId);

	@Query("SELECT c FROM Commande c WHERE c.userId = :userId AND c.dateCreation BETWEEN :debut AND :fin")
	List<Commande> findCommandesByUserIdAndDateRange(@Param("userId") String userId,
			@Param("debut") LocalDateTime debut, @Param("fin") LocalDateTime fin);

	// Commandes archivées pour l'admin
	List<Commande> findByArchivedTrue();

	// Pour getCommandesArchives côté admin/filtrage global
	List<Commande> findByArchived(Boolean archived);

	// Pour filtrer sur user + archivage (archives personnelles)
	List<Commande> findByUserIdAndArchived(String userId, Boolean archived);

	// Optionnel : statut + archived
	List<Commande> findByStatutAndArchived(String statut, Boolean archived);
}