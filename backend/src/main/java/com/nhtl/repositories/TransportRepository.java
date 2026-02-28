package com.nhtl.repositories;

import com.nhtl.models.Transport;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;

@Repository
public interface TransportRepository extends JpaRepository<Transport, Long> {
    List<Transport> findByStatut(String statut);
    List<Transport> findByNumeroTelephone(String numeroTelephone);
    List<Transport> findByPaysDestinataire(String paysDestinataire);
    List<Transport> findByTypeTransport(String typeTransport);
    List<Transport> findByPointDepart(String pointDepart);
    List<Transport> findByPointArrivee(String pointArrivee);

    @Query("SELECT t FROM Transport t WHERE t.dateCreation BETWEEN :debut AND :fin")
    List<Transport> findTransportsByDateRange(
            @Param("debut") LocalDateTime debut,
            @Param("fin") LocalDateTime fin
    );

    @Query("SELECT t FROM Transport t WHERE " +
            "LOWER(t.nom) LIKE LOWER(CONCAT('%', :nom, '%')) " +
            "OR LOWER(t.prenom) LIKE LOWER(CONCAT('%', :prenom, '%'))")
    List<Transport> searchByNomOrPrenom(
            @Param("nom") String nom,
            @Param("prenom") String prenom
    );
}