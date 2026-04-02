package com.nhtl.repositories;

import com.nhtl.models.PanierItem;
import com.nhtl.models.ServiceType;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface PanierItemRepository extends JpaRepository<PanierItem, Long> {

    List<PanierItem> findByUserId(String userId);

    List<PanierItem> findByUserIdAndServiceType(String userId, ServiceType serviceType);

    Optional<PanierItem> findByUserIdAndProduitId(String userId, Long produitId);

    void deleteByUserId(String userId);

    void deleteByUserIdAndServiceType(String userId, ServiceType serviceType);
}
