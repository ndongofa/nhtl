package com.nhtl.repositories;

import com.nhtl.models.Transport;
import com.nhtl.models.StatutTransport;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;

@Repository
public interface TransportRepository extends JpaRepository<Transport, Long> {
    
    // Trouver les transports par statut
    List<Transport> findByStatut(StatutTransport statut);
    
    // Trouver les transports par numéro de téléphone
    List<Transport> findByNumeroTelephone(String numeroTelephone);
    
    // Trouver les transports par pays de destination
    List<Transport> findByPaysDestinataire(String paysDestinataire);
    
    // Requête personnalisée: transports créés dans une période
    @Query("SELECT t FROM Transport t WHERE t.dateCreation BETWEEN :debut AND :fin")
    List<Transport> findTransportsByDateRange(
        @Param("debut") LocalDateTime debut,
        @Param("fin") LocalDateTime fin
    );
    
    // Chercher par nom et prénom
    @Query("SELECT t FROM Transport t WHERE LOWER(t.nom) LIKE LOWER(CONCAT('%', :nom, '%')) OR LOWER(t.prenom) LIKE LOWER(CONCAT('%', :prenom, '%'))")
    List<Transport> searchByNomOrPrenom(
        @Param("nom") String nom,
        @Param("prenom") String prenom
    );
}