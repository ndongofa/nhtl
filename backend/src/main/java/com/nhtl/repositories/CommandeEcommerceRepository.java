package com.nhtl.repositories;

import com.nhtl.models.CommandeEcommerce;
import com.nhtl.models.EcommerceStatus;
import com.nhtl.models.ServiceType;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface CommandeEcommerceRepository extends JpaRepository<CommandeEcommerce, Long> {

    List<CommandeEcommerce> findByUserId(String userId);

    List<CommandeEcommerce> findByUserIdAndServiceType(String userId, ServiceType serviceType);

    List<CommandeEcommerce> findByServiceType(ServiceType serviceType);

    List<CommandeEcommerce> findByStatut(EcommerceStatus statut);

    List<CommandeEcommerce> findByArchivedTrue();

    List<CommandeEcommerce> findByArchived(Boolean archived);

    List<CommandeEcommerce> findByUserIdAndArchived(String userId, Boolean archived);

    List<CommandeEcommerce> findByUserIdAndServiceTypeAndArchived(
            String userId, ServiceType serviceType, Boolean archived);
}
