package com.nhtl.repositories;

import com.nhtl.models.Commande;
import com.nhtl.models.Plateforme;
import com.nhtl.models.StatutCommande;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;

@Repository
public interface CommandeRepository extends JpaRepository<Commande, Long> {
    
    // Trouver les commandes par statut
    List<Commande> findByStatut(StatutCommande statut);
    
    // Trouver les commandes par plateforme
    List<Commande> findByPlateforme(Plateforme plateforme);
    
    // Trouver les commandes par numéro de téléphone
    List<Commande> findByNumeroTelephone(String numeroTelephone);
    
    // Trouver les commandes par pays
    List<Commande> findByPaysLivraison(String paysLivraison);
    
    // Requête personnalisée: commandes créées dans une période
    @Query("SELECT c FROM Commande c WHERE c.dateCreation BETWEEN :debut AND :fin")
    List<Commande> findCommandesByDateRange(
        @Param("debut") LocalDateTime debut,
        @Param("fin") LocalDateTime fin
    );
    
    // Chercher par nom et prénom
    @Query("SELECT c FROM Commande c WHERE LOWER(c.nom) LIKE LOWER(CONCAT('%', :nom, '%')) OR LOWER(c.prenom) LIKE LOWER(CONCAT('%', :prenom, '%'))")
    List<Commande> searchByNomOrPrenom(
        @Param("nom") String nom,
        @Param("prenom") String prenom
    );
    
    // Commandes par plateforme et statut
    @Query("SELECT c FROM Commande c WHERE c.plateforme = :plateforme AND c.statut = :statut")
    List<Commande> findByPlateformeAndStatut(
        @Param("plateforme") Plateforme plateforme,
        @Param("statut") StatutCommande statut
    );
}