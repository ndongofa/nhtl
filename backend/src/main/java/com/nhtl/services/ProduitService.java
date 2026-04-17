package com.nhtl.services;

import com.nhtl.dto.ProduitDTO;
import com.nhtl.models.Produit;
import com.nhtl.models.ServiceType;
import com.nhtl.repositories.ProduitRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;

@Service
public class ProduitService {

    @Autowired
    private ProduitRepository produitRepo;

    public ProduitDTO createProduit(ProduitDTO dto) {
        Produit p = new Produit();
        updateFromDto(p, dto);
        return convertToDTO(produitRepo.save(p));
    }

    public List<ProduitDTO> getAllByService(String serviceTypeStr) {
        ServiceType type = ServiceType.valueOf(serviceTypeStr.toUpperCase());
        return produitRepo.findByServiceTypeAndActifTrue(type).stream()
                .map(this::convertToDTO).collect(Collectors.toList());
    }

    public List<ProduitDTO> getAllByServiceAdmin(String serviceTypeStr) {
        ServiceType type = ServiceType.valueOf(serviceTypeStr.toUpperCase());
        return produitRepo.findByServiceType(type).stream()
                .map(this::convertToDTO).collect(Collectors.toList());
    }

    public Optional<ProduitDTO> getById(Long id) {
        return produitRepo.findById(id).map(this::convertToDTO);
    }

    public ProduitDTO updateProduit(Long id, ProduitDTO dto) {
        Optional<Produit> opt = produitRepo.findById(id);
        if (opt.isEmpty()) return null;
        Produit p = opt.get();
        updateFromDto(p, dto);
        return convertToDTO(produitRepo.save(p));
    }

    public boolean deleteProduit(Long id) {
        if (!produitRepo.existsById(id)) return false;
        produitRepo.deleteById(id);
        return true;
    }

    public ProduitDTO updateStock(Long id, int newStock) {
        Optional<Produit> opt = produitRepo.findById(id);
        if (opt.isEmpty()) return null;
        Produit p = opt.get();
        p.setStock(newStock);
        return convertToDTO(produitRepo.save(p));
    }

    private void updateFromDto(Produit p, ProduitDTO dto) {
        if (dto.getServiceType() != null) {
            p.setServiceType(ServiceType.valueOf(dto.getServiceType().toUpperCase()));
        }
        p.setNom(dto.getNom());
        p.setDescription(dto.getDescription());
        p.setPrix(dto.getPrix());
        p.setDevise(dto.getDevise() != null ? dto.getDevise() : "EUR");
        p.setCategorie(dto.getCategorie());
        // imageUrls is the authoritative list; imageUrl is kept as the first image for backward compat
        List<String> urls = dto.getImageUrls() != null ? dto.getImageUrls() : new ArrayList<>();
        p.setImageUrls(urls);
        p.setImageUrl(!urls.isEmpty() ? urls.get(0) : dto.getImageUrl());
        if (dto.getStock() != null) p.setStock(dto.getStock());
        p.setUnite(dto.getUnite());
        if (dto.getActif() != null) p.setActif(dto.getActif());
    }

    private ProduitDTO convertToDTO(Produit p) {
        ProduitDTO dto = new ProduitDTO();
        dto.setId(p.getId());
        dto.setServiceType(p.getServiceType() != null ? p.getServiceType().name() : null);
        dto.setNom(p.getNom());
        dto.setDescription(p.getDescription());
        dto.setPrix(p.getPrix());
        dto.setDevise(p.getDevise());
        dto.setCategorie(p.getCategorie());
        // Build imageUrls from stored list; fall back to imageUrl for backward compat
        List<String> urls = p.getImageUrls() != null ? new ArrayList<>(p.getImageUrls()) : new ArrayList<>();
        if (urls.isEmpty() && p.getImageUrl() != null && !p.getImageUrl().isBlank()) {
            urls.add(p.getImageUrl());
        }
        dto.setImageUrls(urls);
        dto.setImageUrl(!urls.isEmpty() ? urls.get(0) : p.getImageUrl());
        dto.setStock(p.getStock());
        dto.setUnite(p.getUnite());
        dto.setActif(p.getActif());
        dto.setDateAjout(p.getDateAjout());
        dto.setDateModification(p.getDateModification());
        return dto;
    }
}
