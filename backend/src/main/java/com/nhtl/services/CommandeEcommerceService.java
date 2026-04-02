package com.nhtl.services;

import com.nhtl.dto.CommandeEcommerceDTO;
import com.nhtl.dto.CommandeEcommerceDTO.CommandeEcommerceItemDTO;
import com.nhtl.dto.PanierItemDTO;
import com.nhtl.models.*;
import com.nhtl.repositories.CommandeEcommerceRepository;
import com.nhtl.repositories.ProduitRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;

@Service
public class CommandeEcommerceService {

    @Autowired
    private CommandeEcommerceRepository commandeRepo;

    @Autowired
    private ProduitRepository produitRepo;

    @Autowired
    private PanierService panierService;

    @Transactional
    public CommandeEcommerceDTO validerPanier(CommandeEcommerceDTO dto, String userId) {
        ServiceType serviceType = ServiceType.valueOf(dto.getServiceType().toUpperCase());

        // Récupérer les items du panier pour ce service
        List<PanierItemDTO> panierItems = panierService.getPanierForUser(userId, dto.getServiceType());
        if (panierItems == null || panierItems.isEmpty()) return null;

        CommandeEcommerce commande = new CommandeEcommerce();
        commande.setUserId(userId);
        commande.setNom(dto.getNom());
        commande.setPrenom(dto.getPrenom());
        commande.setNumeroTelephone(dto.getNumeroTelephone());
        commande.setEmail(dto.getEmail());
        commande.setPaysLivraison(dto.getPaysLivraison());
        commande.setVilleLivraison(dto.getVilleLivraison());
        commande.setAdresseLivraison(dto.getAdresseLivraison());
        commande.setServiceType(serviceType);
        commande.setNotesSpeciales(dto.getNotesSpeciales());
        commande.setDevise(dto.getDevise() != null ? dto.getDevise() : "EUR");
        commande.setStatut(EcommerceStatus.EN_ATTENTE);
        commande.setArchived(false);

        BigDecimal total = BigDecimal.ZERO;
        for (PanierItemDTO pItem : panierItems) {
            CommandeEcommerceItem item = new CommandeEcommerceItem();
            item.setCommandeEcommerce(commande);
            item.setProduitId(pItem.getProduitId());
            item.setProduitNom(pItem.getProduitNom());
            item.setQuantite(pItem.getQuantite());
            item.setPrixUnitaire(pItem.getPrixUnitaire());
            item.setDevise(pItem.getDevise() != null ? pItem.getDevise() : "EUR");
            BigDecimal sous = pItem.getPrixUnitaire().multiply(BigDecimal.valueOf(pItem.getQuantite()));
            item.setSousTotal(sous);
            total = total.add(sous);
            commande.getItems().add(item);
        }
        commande.setPrixTotal(total);

        CommandeEcommerce saved = commandeRepo.save(commande);

        // Vider le panier après validation
        panierService.viderPanier(userId, dto.getServiceType());

        return convertToDTO(saved);
    }

    public List<CommandeEcommerceDTO> getCommandesForUser(String userId, String serviceTypeStr) {
        ServiceType type = ServiceType.valueOf(serviceTypeStr.toUpperCase());
        return commandeRepo.findByUserIdAndServiceTypeAndArchived(userId, type, false).stream()
                .map(this::convertToDTO).collect(Collectors.toList());
    }

    public List<CommandeEcommerceDTO> getArchivesForUser(String userId, String serviceTypeStr) {
        ServiceType type = ServiceType.valueOf(serviceTypeStr.toUpperCase());
        return commandeRepo.findByUserIdAndServiceTypeAndArchived(userId, type, true).stream()
                .map(this::convertToDTO).collect(Collectors.toList());
    }

    public List<CommandeEcommerceDTO> getAllByServiceAdmin(String serviceTypeStr) {
        ServiceType type = ServiceType.valueOf(serviceTypeStr.toUpperCase());
        return commandeRepo.findByServiceType(type).stream()
                .map(this::convertToDTO).collect(Collectors.toList());
    }

    public Optional<CommandeEcommerceDTO> getById(Long id) {
        return commandeRepo.findById(id).map(this::convertToDTO);
    }

    public CommandeEcommerceDTO updateStatut(Long id, String nouveauStatut) {
        Optional<CommandeEcommerce> opt = commandeRepo.findById(id);
        if (opt.isEmpty()) return null;
        CommandeEcommerce c = opt.get();
        try {
            c.setStatut(EcommerceStatus.valueOf(nouveauStatut.toUpperCase()));
        } catch (IllegalArgumentException e) {
            return null;
        }
        c.setDateModification(java.time.LocalDateTime.now());
        return convertToDTO(commandeRepo.save(c));
    }

    public CommandeEcommerceDTO archiver(Long id) {
        Optional<CommandeEcommerce> opt = commandeRepo.findById(id);
        if (opt.isEmpty()) return null;
        CommandeEcommerce c = opt.get();
        c.setArchived(true);
        c.setDateModification(java.time.LocalDateTime.now());
        return convertToDTO(commandeRepo.save(c));
    }

    public CommandeEcommerceDTO desarchiver(Long id) {
        Optional<CommandeEcommerce> opt = commandeRepo.findById(id);
        if (opt.isEmpty() || !Boolean.TRUE.equals(opt.get().getArchived())) return null;
        CommandeEcommerce c = opt.get();
        c.setArchived(false);
        c.setDateModification(java.time.LocalDateTime.now());
        return convertToDTO(commandeRepo.save(c));
    }

    public boolean supprimer(Long id) {
        if (!commandeRepo.existsById(id)) return false;
        commandeRepo.deleteById(id);
        return true;
    }

    // ── Helpers ───────────────────────────────────────────────────────────────

    private CommandeEcommerceDTO convertToDTO(CommandeEcommerce c) {
        CommandeEcommerceDTO dto = new CommandeEcommerceDTO();
        dto.setId(c.getId());
        dto.setUserId(c.getUserId());
        dto.setNom(c.getNom());
        dto.setPrenom(c.getPrenom());
        dto.setNumeroTelephone(c.getNumeroTelephone());
        dto.setEmail(c.getEmail());
        dto.setPaysLivraison(c.getPaysLivraison());
        dto.setVilleLivraison(c.getVilleLivraison());
        dto.setAdresseLivraison(c.getAdresseLivraison());
        dto.setServiceType(c.getServiceType() != null ? c.getServiceType().name() : null);
        dto.setPrixTotal(c.getPrixTotal());
        dto.setDevise(c.getDevise());
        dto.setStatut(c.getStatut() != null ? c.getStatut().name() : "EN_ATTENTE");
        dto.setArchived(c.getArchived());
        dto.setNotesSpeciales(c.getNotesSpeciales());
        dto.setDateCommande(c.getDateCommande());
        dto.setDateModification(c.getDateModification());

        List<CommandeEcommerceItemDTO> itemDtos = c.getItems().stream().map(item -> {
            CommandeEcommerceItemDTO iDto = new CommandeEcommerceItemDTO();
            iDto.setId(item.getId());
            iDto.setProduitId(item.getProduitId());
            iDto.setProduitNom(item.getProduitNom());
            iDto.setQuantite(item.getQuantite());
            iDto.setPrixUnitaire(item.getPrixUnitaire());
            iDto.setSousTotal(item.getSousTotal());
            iDto.setDevise(item.getDevise());
            return iDto;
        }).collect(Collectors.toList());
        dto.setItems(itemDtos);

        return dto;
    }
}
