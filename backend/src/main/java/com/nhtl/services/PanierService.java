package com.nhtl.services;

import com.nhtl.dto.PanierItemDTO;
import com.nhtl.models.PanierItem;
import com.nhtl.models.Produit;
import com.nhtl.models.ServiceType;
import com.nhtl.repositories.PanierItemRepository;
import com.nhtl.repositories.ProduitRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;

@Service
public class PanierService {

    @Autowired
    private PanierItemRepository panierRepo;

    @Autowired
    private ProduitRepository produitRepo;

    public List<PanierItemDTO> getPanierForUser(String userId, String serviceTypeStr) {
        ServiceType type = ServiceType.valueOf(serviceTypeStr.toUpperCase());
        return panierRepo.findByUserIdAndServiceType(userId, type).stream()
                .map(this::enrichAndConvert).collect(Collectors.toList());
    }

    public PanierItemDTO ajouterOuModifier(String userId, Long produitId, int quantite) {
        Optional<Produit> optProduit = produitRepo.findById(produitId);
        if (optProduit.isEmpty()) return null;

        Produit produit = optProduit.get();
        Optional<PanierItem> existing = panierRepo.findByUserIdAndProduitId(userId, produitId);

        PanierItem item;
        if (existing.isPresent()) {
            item = existing.get();
            item.setQuantite(quantite);
        } else {
            item = new PanierItem();
            item.setUserId(userId);
            item.setProduitId(produitId);
            item.setServiceType(produit.getServiceType());
            item.setPrixUnitaire(produit.getPrix());
            item.setDevise(produit.getDevise());
            item.setQuantite(quantite);
        }

        return enrichAndConvert(panierRepo.save(item));
    }

    public boolean supprimerItem(String userId, Long produitId) {
        Optional<PanierItem> opt = panierRepo.findByUserIdAndProduitId(userId, produitId);
        if (opt.isEmpty()) return false;
        panierRepo.delete(opt.get());
        return true;
    }

    @Transactional
    public void viderPanier(String userId, String serviceTypeStr) {
        ServiceType type = ServiceType.valueOf(serviceTypeStr.toUpperCase());
        panierRepo.deleteByUserIdAndServiceType(userId, type);
    }

    // ── Helpers ───────────────────────────────────────────────────────────────

    private PanierItemDTO enrichAndConvert(PanierItem item) {
        PanierItemDTO dto = new PanierItemDTO();
        dto.setId(item.getId());
        dto.setUserId(item.getUserId());
        dto.setProduitId(item.getProduitId());
        dto.setServiceType(item.getServiceType() != null ? item.getServiceType().name() : null);
        dto.setQuantite(item.getQuantite());
        dto.setPrixUnitaire(item.getPrixUnitaire());
        dto.setDevise(item.getDevise());
        dto.setDateAjout(item.getDateAjout());

        // Enrichissement depuis la table produits
        produitRepo.findById(item.getProduitId()).ifPresent(p -> {
            dto.setProduitNom(p.getNom());
            dto.setProduitImageUrl(p.getImageUrl());
        });

        // Calcul sous-total
        if (item.getPrixUnitaire() != null && item.getQuantite() != null) {
            dto.setSousTotal(item.getPrixUnitaire().multiply(BigDecimal.valueOf(item.getQuantite())));
        }

        return dto;
    }
}
