package com.nhtl.repositories;

import com.nhtl.models.Commande;
import com.nhtl.models.CommandeStatus;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface CommandeRepository extends JpaRepository<Commande, Long> {

    List<Commande> findByUserId(String userId);

    List<Commande> findByStatut(String statut);

    List<Commande> findByStatutSuivi(CommandeStatus statutSuivi);

    List<Commande> findByArchivedTrue();

    List<Commande> findByArchived(Boolean archived);

    List<Commande> findByUserIdAndArchived(String userId, Boolean archived);
}