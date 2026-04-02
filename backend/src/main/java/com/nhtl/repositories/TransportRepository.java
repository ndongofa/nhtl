package com.nhtl.repositories;

import java.time.LocalDateTime;
import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import com.nhtl.models.Transport;

@Repository
public interface TransportRepository extends JpaRepository<Transport, Long> {
	List<Transport> findByUserId(String userId);

	List<Transport> findByStatut(String statut);

	List<Transport> findByTypesMarchandise(String typesMarchandise);

	List<Transport> findByPointDepart(String pointDepart);

	List<Transport> findByPaysExpediteur(String paysExpediteur);

	@Query("SELECT t FROM Transport t WHERE t.dateCreation BETWEEN :debut AND :fin")
	List<Transport> findTransportsByDateRange(@Param("debut") LocalDateTime debut, @Param("fin") LocalDateTime fin);

	@Query("SELECT t FROM Transport t WHERE LOWER(t.nom) LIKE LOWER(CONCAT('%', :nom, '%')) OR LOWER(t.prenom) LIKE LOWER(CONCAT('%', :prenom, '%'))")
	List<Transport> searchByNomOrPrenom(@Param("nom") String nom, @Param("prenom") String prenom);

	@Query("SELECT t FROM Transport t WHERE t.typeTransport = :typeTransport AND t.statut = :statut")
	List<Transport> findByTypeTransportAndStatut(@Param("typeTransport") String typeTransport,
			@Param("statut") String statut);

	List<Transport> findByStatutAndUserId(String statut, String userId);

	List<Transport> findByTypeTransportAndUserId(String typeTransport, String userId);

	@Query("SELECT t FROM Transport t WHERE t.userId = :userId AND t.dateCreation BETWEEN :debut AND :fin")
	List<Transport> findTransportsByUserIdAndDateRange(@Param("userId") String userId,
			@Param("debut") LocalDateTime debut, @Param("fin") LocalDateTime fin);

	List<Transport> findByArchivedTrue();

	List<Transport> findByArchived(Boolean archived);

	List<Transport> findByUserIdAndArchived(String userId, Boolean archived);

	List<Transport> findByStatutAndArchived(String statut, Boolean archived);
}