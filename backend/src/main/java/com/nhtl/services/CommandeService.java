package com.nhtl.services;

import java.text.Normalizer;
import java.util.List;
import java.util.Locale;
import java.util.Optional;
import java.util.stream.Collectors;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import com.nhtl.dto.CommandeDTO;
import com.nhtl.models.Commande;
import com.nhtl.models.GpAgent;
import com.nhtl.models.CommandeStatus;
import com.nhtl.notifications.NotificationDispatcher;
import com.nhtl.notifications.NotificationTemplates;
import com.nhtl.repositories.CommandeRepository;
import com.nhtl.repositories.GpAgentRepository;

@Service
public class CommandeService {

    @Autowired
    private CommandeRepository commandeRepo;

    @Autowired
    private GpAgentRepository gpRepo;

    @Autowired
    private NotificationDispatcher notificationDispatcher;

    @Autowired
    private NotificationTemplates templates;

    @Autowired
    private NotificationService notificationService;

    public CommandeDTO createCommande(CommandeDTO dto, String userId) {
        Commande c = new Commande();
        c.setUserId(userId);
        c.setNom(dto.getNom());
        c.setPrenom(dto.getPrenom());
        c.setNumeroTelephone(dto.getNumeroTelephone());
        c.setEmail(dto.getEmail());
        c.setPaysLivraison(dto.getPaysLivraison());
        c.setVilleLivraison(dto.getVilleLivraison());
        c.setAdresseLivraison(dto.getAdresseLivraison());
        c.setPlateforme(dto.getPlateforme());
        c.setLienProduit(dto.getLienProduit());
        c.setDescriptionCommande(dto.getDescriptionCommande());
        c.setQuantite(dto.getQuantite());
        c.setPrixUnitaire(dto.getPrixUnitaire());
        c.setPrixTotal(dto.getPrixTotal());
        c.setDevise(dto.getDevise());
        c.setNotesSpeciales(dto.getNotesSpeciales());
        c.setStatut(parseOrDefault(dto.getStatut(), CommandeStatus.EN_ATTENTE).name());
        c.setArchived(false);
        c.setDateCreation(java.time.LocalDateTime.now());
        c.setDateModification(java.time.LocalDateTime.now());
        c.setGpId(null);
        c.setGpPrenom(null);
        c.setGpNom(null);
        c.setGpPhoneNumber(null);

        Commande saved = commandeRepo.save(c);

        try {
            notificationDispatcher.dispatch(templates.commandeCreated(saved.getUserId(), saved.getEmail(),
                    saved.getNumeroTelephone(), saved.getId()));
        } catch (Exception e) {
            System.out.println("⚠️ Notification commandeCreated échouée: " + e.getMessage());
        }

        return convertToDTO(saved);
    }

    public List<CommandeDTO> getAllCommandesForUser(String userId) {
        return commandeRepo.findByUserId(userId).stream().map(this::convertToDTO).collect(Collectors.toList());
    }

    public List<CommandeDTO> getAllCommandes() {
        return commandeRepo.findAll().stream().map(this::convertToDTO).collect(Collectors.toList());
    }

    public List<CommandeDTO> getCommandesArchives() {
        return commandeRepo.findByArchived(true).stream().map(this::convertToDTO).collect(Collectors.toList());
    }

    public List<CommandeDTO> getArchivées() {
        return commandeRepo.findByArchivedTrue().stream().map(this::convertToDTO).collect(Collectors.toList());
    }

    public List<CommandeDTO> getCommandesArchivesForUser(String userId) {
        return commandeRepo.findByUserIdAndArchived(userId, true).stream().map(this::convertToDTO)
                .collect(Collectors.toList());
    }

    public Optional<CommandeDTO> getCommandeByIdAndUser(Long id, String userId) {
        return commandeRepo.findById(id).filter(c -> c.getUserId().equals(userId)).map(this::convertToDTO);
    }

    public boolean deleteCommandeArchive(Long id, String userId) {
        Optional<Commande> opt = commandeRepo.findById(id);
        if (opt.isPresent() && opt.get().getUserId().equals(userId) && Boolean.TRUE.equals(opt.get().getArchived())) {
            commandeRepo.deleteById(id);
            return true;
        }
        return false;
    }

    public boolean deleteCommande(Long id, String userId) {
        Optional<Commande> opt = commandeRepo.findById(id);
        if (opt.isPresent() && opt.get().getUserId().equals(userId)) {
            commandeRepo.deleteById(id);
            return true;
        }
        return false;
    }

    public CommandeDTO updateCommande(Long id, CommandeDTO dto, String userId) {
        Optional<Commande> opt = commandeRepo.findById(id);
        if (opt.isPresent() && opt.get().getUserId().equals(userId)) {
            Commande c = opt.get();
            updateFromDto(c, dto);
            c.setDateModification(java.time.LocalDateTime.now());
            Commande saved = commandeRepo.save(c);
            return convertToDTO(saved);
        }
        return null;
    }

    public boolean deleteCommandeAdmin(Long id) {
        if (commandeRepo.existsById(id)) {
            commandeRepo.deleteById(id);
            return true;
        }
        return false;
    }

    public CommandeDTO updateCommandeAdmin(Long id, CommandeDTO dto) {
        Optional<Commande> opt = commandeRepo.findById(id);
        if (opt.isPresent()) {
            Commande c = opt.get();
            updateFromDto(c, dto);
            c.setDateModification(java.time.LocalDateTime.now());
            Commande saved = commandeRepo.save(c);
            return convertToDTO(saved);
        }
        return null;
    }

    public CommandeDTO updateStatut(Long id, String nouveauStatut) {
        Optional<Commande> opt = commandeRepo.findById(id);
        if (opt.isEmpty()) return null;

        Commande c = opt.get();
        CommandeStatus parsed = tryParseStatut(nouveauStatut);
        boolean changed = false;

        if (parsed != null) {
            c.setStatut(parsed.name());
            c.setDateModification(java.time.LocalDateTime.now());
            c = commandeRepo.save(c);
            changed = true;
        }

        if (changed) {
            try {
                CommandeStatus statusEnum = CommandeStatus.valueOf(c.getStatut());
                notificationDispatcher.dispatch(templates.commandeStatusUpdated(c.getUserId(), c.getEmail(),
                        c.getNumeroTelephone(), c.getId(), statusEnum));
                if (statusEnum == CommandeStatus.LIVREE) {
                    notificationDispatcher.dispatch(templates.commandeCompleted(c.getUserId(), c.getEmail(),
                            c.getNumeroTelephone(), c.getId()));
                }
            } catch (Exception e) {
                System.out.println("⚠️ Notification updateStatut commande échouée: " + e.getMessage());
            }
        }

        return convertToDTO(c);
    }

    public CommandeDTO archiverCommande(Long id) {
        Optional<Commande> opt = commandeRepo.findById(id);
        if (opt.isPresent()) {
            Commande c = opt.get();
            c.setArchived(true);
            c.setDateModification(java.time.LocalDateTime.now());
            return convertToDTO(commandeRepo.save(c));
        }
        return null;
    }

    public CommandeDTO desarchiverCommande(Long id) {
        Optional<Commande> opt = commandeRepo.findById(id);
        if (opt.isPresent() && Boolean.TRUE.equals(opt.get().getArchived())) {
            Commande c = opt.get();
            c.setArchived(false);
            c.setDateModification(java.time.LocalDateTime.now());
            return convertToDTO(commandeRepo.save(c));
        }
        return null;
    }

    public CommandeDTO assignGpAndValidate(Long commandeId, Long gpId, String statut) {
        Optional<Commande> optC = commandeRepo.findById(commandeId);
        if (optC.isEmpty()) return null;

        Optional<GpAgent> optGp = gpRepo.findById(gpId);
        if (optGp.isEmpty()) return null;

        Commande c = optC.get();
        GpAgent gp = optGp.get();

        c.setGpId(gp.getId());
        c.setGpPrenom(gp.getPrenom());
        c.setGpNom(gp.getNom());
        c.setGpPhoneNumber(gp.getPhoneNumber());

        CommandeStatus parsed = tryParseStatut(statut);
        if (parsed != null) c.setStatut(parsed.name());

        c.setDateModification(java.time.LocalDateTime.now());
        Commande saved = commandeRepo.save(c);

        try {
            CommandeStatus newStatus = null;
            try { newStatus = CommandeStatus.valueOf(saved.getStatut()); } catch (Exception ignored) {}
            String gpFullName = (gp.getPrenom() + " " + gp.getNom()).trim();
            notificationDispatcher.dispatch(templates.commandeGpAssigned(saved.getUserId(), saved.getEmail(),
                    saved.getNumeroTelephone(), saved.getId(), gpFullName, gp.getPhoneNumber(), newStatus));
        } catch (Exception e) {
            System.out.println("⚠️ Notification commandeGpAssigned échouée: " + e.getMessage());
        }

        return convertToDTO(saved);
    }

    // ── Helpers ───────────────────────────────────────────────────────────────

    private CommandeStatus parseOrDefault(String raw, CommandeStatus def) {
        CommandeStatus parsed = tryParseStatut(raw);
        return parsed != null ? parsed : def;
    }

    private CommandeStatus tryParseStatut(String raw) {
        if (raw == null || raw.trim().isEmpty()) return null;
        String s = raw.trim().toUpperCase(Locale.ROOT);
        s = Normalizer.normalize(s, Normalizer.Form.NFD).replaceAll("\\p{M}", "");
        s = s.replace(' ', '_').replace('-', '_');
        if ("LIVRE".equals(s)) return CommandeStatus.LIVREE;
        try { return CommandeStatus.valueOf(s); } catch (IllegalArgumentException ex) { return null; }
    }

    // ✅ convertToDTO — inclut statutSuivi + champs postaux
    private CommandeDTO convertToDTO(Commande c) {
        CommandeDTO dto = new CommandeDTO();
        dto.setId(c.getId());
        dto.setUserId(c.getUserId());
        dto.setNom(c.getNom());
        dto.setPrenom(c.getPrenom());
        dto.setNumeroTelephone(c.getNumeroTelephone());
        dto.setEmail(c.getEmail());
        dto.setPaysLivraison(c.getPaysLivraison());
        dto.setVilleLivraison(c.getVilleLivraison());
        dto.setAdresseLivraison(c.getAdresseLivraison());
        dto.setPlateforme(c.getPlateforme());
        dto.setLienProduit(c.getLienProduit());
        dto.setDescriptionCommande(c.getDescriptionCommande());
        dto.setQuantite(c.getQuantite());
        dto.setPrixUnitaire(c.getPrixUnitaire());
        dto.setPrixTotal(c.getPrixTotal());
        dto.setDevise(c.getDevise());
        dto.setNotesSpeciales(c.getNotesSpeciales());
        dto.setStatut(c.getStatut());
        dto.setArchived(c.getArchived());
        dto.setDateCreation(c.getDateCreation());
        dto.setDateModification(c.getDateModification());
        dto.setGpId(c.getGpId());
        dto.setGpPrenom(c.getGpPrenom());
        dto.setGpNom(c.getGpNom());
        dto.setGpPhoneNumber(c.getGpPhoneNumber());
        // ✅ Statut logistique
        dto.setStatutSuivi(c.getStatutSuivi() != null ? c.getStatutSuivi().name() : "EN_ATTENTE");
        // ✅ Suivi postal
        dto.setPhotoColisUrl(c.getPhotoColisUrl());
        dto.setPhotoBordereauUrl(c.getPhotoBordereauUrl());
        dto.setNumeroBordereau(c.getNumeroBordereau());
        dto.setDeposePosteAt(c.getDeposePosteAt());
        return dto;
    }

    private void updateFromDto(Commande c, CommandeDTO dto) {
        c.setNom(dto.getNom());
        c.setPrenom(dto.getPrenom());
        c.setNumeroTelephone(dto.getNumeroTelephone());
        c.setEmail(dto.getEmail());
        c.setPaysLivraison(dto.getPaysLivraison());
        c.setVilleLivraison(dto.getVilleLivraison());
        c.setAdresseLivraison(dto.getAdresseLivraison());
        c.setPlateforme(dto.getPlateforme());
        c.setLienProduit(dto.getLienProduit());
        c.setDescriptionCommande(dto.getDescriptionCommande());
        c.setQuantite(dto.getQuantite());
        c.setPrixUnitaire(dto.getPrixUnitaire());
        c.setPrixTotal(dto.getPrixTotal());
        c.setDevise(dto.getDevise());
        c.setNotesSpeciales(dto.getNotesSpeciales());
        c.setStatut(parseOrDefault(dto.getStatut(), CommandeStatus.EN_ATTENTE).name());
        c.setArchived(dto.getArchived());
    }
}