package com.nhtl.services;

import com.nhtl.models.Commande;
import com.nhtl.models.Plateforme;
import com.nhtl.models.StatutCommande;
import com.nhtl.repositories.CommandeRepository;
import com.nhtl.dto.CommandeDTO;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;

@Service
public class CommandeService {
    
    @Autowired
    private CommandeRepository commandeRepository;
    
    /**
     * Créer une nouvelle commande
     */
    public CommandeDTO createCommande(CommandeDTO commandeDTO) {
        Commande commande = new Commande();
        commande.setNom(commandeDTO.getNom());
        commande.setPrenom(commandeDTO.getPrenom());
        commande.setNumeroTelephone(commandeDTO.getNumeroTelephone());
        commande.setEmail(commandeDTO.getEmail());
        commande.setPaysLivraison(commandeDTO.getPaysLivraison());
        commande.setVilleLivraison(commandeDTO.getVilleLivraison());
        commande.setAdresseLivraison(commandeDTO.getAdresseLivraison());
        commande.setPlateforme(Plateforme.valueOf(commandeDTO.getPlateforme().toUpperCase()));
        commande.setLienProduit(commandeDTO.getLienProduit());
        commande.setDescriptionCommande(commandeDTO.getDescriptionCommande());
        commande.setQuantite(commandeDTO.getQuantite());
        commande.setPrixUnitaire(commandeDTO.getPrixUnitaire());
        
        // Calculer le prix total
        BigDecimal prixTotal = commandeDTO.getPrixUnitaire()
                .multiply(new BigDecimal(commandeDTO.getQuantite()));
        commande.setPrixTotal(prixTotal);
        
        commande.setDevise(commandeDTO.getDevise());
        commande.setNotesSpeciales(commandeDTO.getNotesSpeciales());
        
        Commande savedCommande = commandeRepository.save(commande);
        return convertToDTO(savedCommande);
    }
    
    /**
     * Récupérer une commande par ID
     */
    public CommandeDTO getCommandeById(Long id) {
        Optional<Commande> commande = commandeRepository.findById(id);
        return commande.map(this::convertToDTO).orElse(null);
    }
    
    /**
     * Récupérer toutes les commandes
     */
    public List<CommandeDTO> getAllCommandes() {
        return commandeRepository.findAll()
                .stream()
                .map(this::convertToDTO)
                .collect(Collectors.toList());
    }
    
    /**
     * Récupérer les commandes par statut
     */
    public List<CommandeDTO> getCommandesByStatut(String statut) {
        StatutCommande enumStatut = StatutCommande.valueOf(statut.toUpperCase());
        return commandeRepository.findByStatut(enumStatut)
                .stream()
                .map(this::convertToDTO)
                .collect(Collectors.toList());
    }
    
    /**
     * Récupérer les commandes par plateforme
     */
    public List<CommandeDTO> getCommandesByPlateforme(String plateforme) {
        Plateforme enumPlateforme = Plateforme.valueOf(plateforme.toUpperCase());
        return commandeRepository.findByPlateforme(enumPlateforme)
                .stream()
                .map(this::convertToDTO)
                .collect(Collectors.toList());
    }
    
    /**
     * Récupérer les commandes par numéro de téléphone
     */
    public List<CommandeDTO> getCommandesByPhoneNumber(String phoneNumber) {
        return commandeRepository.findByNumeroTelephone(phoneNumber)
                .stream()
                .map(this::convertToDTO)
                .collect(Collectors.toList());
    }
    
    /**
     * Récupérer les commandes par pays
     */
    public List<CommandeDTO> getCommandesByCountry(String country) {
        return commandeRepository.findByPaysLivraison(country)
                .stream()
                .map(this::convertToDTO)
                .collect(Collectors.toList());
    }
    
    /**
     * Chercher les commandes par nom ou prénom
     */
    public List<CommandeDTO> searchByNomOrPrenom(String nom, String prenom) {
        return commandeRepository.searchByNomOrPrenom(nom, prenom)
                .stream()
                .map(this::convertToDTO)
                .collect(Collectors.toList());
    }
    
    /**
     * Mettre à jour une commande
     */
    public CommandeDTO updateCommande(Long id, CommandeDTO commandeDTO) {
        Optional<Commande> existingCommande = commandeRepository.findById(id);
        
        if (existingCommande.isPresent()) {
            Commande commande = existingCommande.get();
            commande.setNom(commandeDTO.getNom());
            commande.setPrenom(commandeDTO.getPrenom());
            commande.setNumeroTelephone(commandeDTO.getNumeroTelephone());
            commande.setEmail(commandeDTO.getEmail());
            commande.setPaysLivraison(commandeDTO.getPaysLivraison());
            commande.setVilleLivraison(commandeDTO.getVilleLivraison());
            commande.setAdresseLivraison(commandeDTO.getAdresseLivraison());
            commande.setPlateforme(Plateforme.valueOf(commandeDTO.getPlateforme().toUpperCase()));
            commande.setLienProduit(commandeDTO.getLienProduit());
            commande.setDescriptionCommande(commandeDTO.getDescriptionCommande());
            commande.setQuantite(commandeDTO.getQuantite());
            commande.setPrixUnitaire(commandeDTO.getPrixUnitaire());
            
            // Recalculer le prix total
            BigDecimal prixTotal = commandeDTO.getPrixUnitaire()
                    .multiply(new BigDecimal(commandeDTO.getQuantite()));
            commande.setPrixTotal(prixTotal);
            
            commande.setDevise(commandeDTO.getDevise());
            commande.setNotesSpeciales(commandeDTO.getNotesSpeciales());
            
            if (commandeDTO.getStatut() != null) {
                commande.setStatut(StatutCommande.valueOf(commandeDTO.getStatut().toUpperCase()));
            }
            
            Commande updatedCommande = commandeRepository.save(commande);
            return convertToDTO(updatedCommande);
        }
        return null;
    }
    
    /**
     * Supprimer une commande
     */
    public boolean deleteCommande(Long id) {
        if (commandeRepository.existsById(id)) {
            commandeRepository.deleteById(id);
            return true;
        }
        return false;
    }
    
    /**
     * Convertir Commande entity en CommandeDTO
     */
    private CommandeDTO convertToDTO(Commande commande) {
        CommandeDTO dto = new CommandeDTO();
        dto.setId(commande.getId());
        dto.setNom(commande.getNom());
        dto.setPrenom(commande.getPrenom());
        dto.setNumeroTelephone(commande.getNumeroTelephone());
        dto.setEmail(commande.getEmail());
        dto.setPaysLivraison(commande.getPaysLivraison());
        dto.setVilleLivraison(commande.getVilleLivraison());
        dto.setAdresseLivraison(commande.getAdresseLivraison());
        dto.setPlateforme(commande.getPlateforme().toString());
        dto.setLienProduit(commande.getLienProduit());
        dto.setDescriptionCommande(commande.getDescriptionCommande());
        dto.setQuantite(commande.getQuantite());
        dto.setPrixUnitaire(commande.getPrixUnitaire());
        dto.setPrixTotal(commande.getPrixTotal());
        dto.setDevise(commande.getDevise());
        dto.setNotesSpeciales(commande.getNotesSpeciales());
        dto.setStatut(commande.getStatut().toString());
        dto.setDateCreation(commande.getDateCreation());
        dto.setDateModification(commande.getDateModification());
        return dto;
    }
}