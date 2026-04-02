package com.nhtl.repositories;

import com.nhtl.models.Achat;
import com.nhtl.models.AchatStatus;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface AchatRepository extends JpaRepository<Achat, Long> {

    List<Achat> findByUserId(String userId);

    List<Achat> findByStatut(String statut);

    List<Achat> findByStatutSuivi(AchatStatus statutSuivi);

    List<Achat> findByArchivedTrue();

    List<Achat> findByArchived(Boolean archived);

    List<Achat> findByUserIdAndArchived(String userId, Boolean archived);
}
