package com.nhtl.repositories;

import com.nhtl.models.Produit;
import com.nhtl.models.ServiceType;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface ProduitRepository extends JpaRepository<Produit, Long> {

    List<Produit> findByServiceType(ServiceType serviceType);

    List<Produit> findByServiceTypeAndActifTrue(ServiceType serviceType);

    List<Produit> findByServiceTypeAndCategorie(ServiceType serviceType, String categorie);

    List<Produit> findByServiceTypeAndActifTrueAndCategorieContainingIgnoreCase(
            ServiceType serviceType, String categorie);
}
