package com.nhtl.services;

import java.text.Normalizer;
import java.util.ArrayList;
import java.util.List;
import java.util.Locale;
import java.util.Optional;
import java.util.stream.Collectors;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.nhtl.dto.AchatDTO;
import com.nhtl.models.Achat;
import com.nhtl.models.AchatStatus;
import com.nhtl.models.GpAgent;
import com.nhtl.notifications.NotificationDispatcher;
import com.nhtl.notifications.NotificationTemplates;
import com.nhtl.repositories.AchatRepository;
import com.nhtl.repositories.GpAgentRepository;

@Service
public class AchatService {

    @Autowired
    private AchatRepository achatRepo;

    @Autowired
    private GpAgentRepository gpRepo;

    @Autowired
    private NotificationDispatcher notificationDispatcher;

    @Autowired
    private NotificationTemplates templates;

    @Autowired
    private NotificationService notificationService;

    private final ObjectMapper objectMapper = new ObjectMapper();

    private String toJsonList(List<String> list) {
        if (list == null || list.isEmpty()) return null;
        try {
            return objectMapper.writeValueAsString(list);
        } catch (Exception e) {
            return null;
        }
    }

    private List<String> parseJsonList(String json) {
        if (json == null || json.trim().isEmpty()) return new ArrayList<>();
        try {
            return objectMapper.readValue(json, new TypeReference<List<String>>() {});
        } catch (Exception e) {
            return new ArrayList<>();
        }
    }

    public AchatDTO createAchat(AchatDTO dto, String userId) {
        Achat a = new Achat();
        a.setUserId(userId);
        a.setNom(dto.getNom());
        a.setPrenom(dto.getPrenom());
        a.setNumeroTelephone(dto.getNumeroTelephone());
        a.setEmail(dto.getEmail());
        a.setPaysLivraison(dto.getPaysLivraison());
        a.setVilleLivraison(dto.getVilleLivraison());
        a.setAdresseLivraison(dto.getAdresseLivraison());
        a.setMarche(dto.getMarche());
        a.setTypeProduit(dto.getTypeProduit());
        a.setDescriptionAchat(dto.getDescriptionAchat());
        a.setLiensProduits(toJsonList(dto.getLiensProduits()));
        a.setPhotosProduits(toJsonList(dto.getPhotosProduits()));
        a.setArticlesJson(dto.getArticlesJson());
        a.setQuantite(dto.getQuantite());
        a.setPrixEstime(dto.getPrixEstime());
        a.setPrixTotal(dto.getPrixTotal());
        a.setDevise(dto.getDevise());
        a.setNotesSpeciales(dto.getNotesSpeciales());
        a.setStatut(parseOrDefault(dto.getStatut(), AchatStatus.EN_ATTENTE).name());
        a.setArchived(false);
        a.setDateCreation(java.time.LocalDateTime.now());
        a.setDateModification(java.time.LocalDateTime.now());
        a.setGpId(null);
        a.setGpPrenom(null);
        a.setGpNom(null);
        a.setGpPhoneNumber(null);

        Achat saved = achatRepo.save(a);

        try {
            notificationDispatcher.dispatch(templates.achatCreated(saved.getUserId(), saved.getEmail(),
                    saved.getNumeroTelephone(), saved.getId()));
        } catch (Exception e) {
            System.out.println("⚠️ Notification achatCreated échouée: " + e.getMessage());
        }

        try {
            notificationDispatcher.dispatch(templates.adminAchatCreated(saved.getId(), saved.getNom(),
                    saved.getPrenom(), saved.getNumeroTelephone()));
        } catch (Exception e) {
            System.out.println("⚠️ Notification adminAchatCreated échouée: " + e.getMessage());
        }

        return convertToDTO(saved);
    }

    public List<AchatDTO> getAllAchatsForUser(String userId) {
        return achatRepo.findByUserId(userId).stream().map(this::convertToDTO).collect(Collectors.toList());
    }

    public List<AchatDTO> getAllAchats() {
        return achatRepo.findAll().stream().map(this::convertToDTO).collect(Collectors.toList());
    }

    public List<AchatDTO> getAchatsArchives() {
        return achatRepo.findByArchived(true).stream().map(this::convertToDTO).collect(Collectors.toList());
    }

    public List<AchatDTO> getArchivés() {
        return achatRepo.findByArchivedTrue().stream().map(this::convertToDTO).collect(Collectors.toList());
    }

    public List<AchatDTO> getAchatsArchivesForUser(String userId) {
        return achatRepo.findByUserIdAndArchived(userId, true).stream().map(this::convertToDTO)
                .collect(Collectors.toList());
    }

    public Optional<AchatDTO> getAchatByIdAndUser(Long id, String userId) {
        return achatRepo.findById(id).filter(a -> a.getUserId().equals(userId)).map(this::convertToDTO);
    }

    public Optional<AchatDTO> getAchatByIdAndAdmin(Long id) {
        return achatRepo.findById(id).map(this::convertToDTO);
    }

    public boolean deleteAchatArchive(Long id, String userId) {
        Optional<Achat> opt = achatRepo.findById(id);
        if (opt.isPresent() && opt.get().getUserId().equals(userId) && Boolean.TRUE.equals(opt.get().getArchived())) {
            achatRepo.deleteById(id);
            return true;
        }
        return false;
    }

    public boolean deleteAchat(Long id, String userId) {
        Optional<Achat> opt = achatRepo.findById(id);
        if (opt.isPresent() && opt.get().getUserId().equals(userId)) {
            achatRepo.deleteById(id);
            return true;
        }
        return false;
    }

    public AchatDTO updateAchat(Long id, AchatDTO dto, String userId) {
        Optional<Achat> opt = achatRepo.findById(id);
        if (opt.isPresent() && opt.get().getUserId().equals(userId)) {
            Achat a = opt.get();
            updateFromDto(a, dto);
            a.setDateModification(java.time.LocalDateTime.now());
            Achat saved = achatRepo.save(a);
            return convertToDTO(saved);
        }
        return null;
    }

    public boolean deleteAchatAdmin(Long id) {
        if (achatRepo.existsById(id)) {
            achatRepo.deleteById(id);
            return true;
        }
        return false;
    }

    public AchatDTO updateAchatAdmin(Long id, AchatDTO dto) {
        Optional<Achat> opt = achatRepo.findById(id);
        if (opt.isPresent()) {
            Achat a = opt.get();
            updateFromDto(a, dto);
            a.setDateModification(java.time.LocalDateTime.now());
            Achat saved = achatRepo.save(a);
            return convertToDTO(saved);
        }
        return null;
    }

    public AchatDTO updateStatut(Long id, String nouveauStatut) {
        Optional<Achat> opt = achatRepo.findById(id);
        if (opt.isEmpty()) return null;

        Achat a = opt.get();
        AchatStatus parsed = tryParseStatut(nouveauStatut);
        boolean changed = false;

        if (parsed != null) {
            a.setStatut(parsed.name());
            a.setDateModification(java.time.LocalDateTime.now());
            a = achatRepo.save(a);
            changed = true;
        }

        if (changed) {
            try {
                AchatStatus statusEnum = AchatStatus.valueOf(a.getStatut());
                notificationDispatcher.dispatch(templates.achatStatusUpdated(a.getUserId(), a.getEmail(),
                        a.getNumeroTelephone(), a.getId(), statusEnum));
                if (statusEnum == AchatStatus.LIVRE) {
                    notificationDispatcher.dispatch(templates.achatCompleted(a.getUserId(), a.getEmail(),
                            a.getNumeroTelephone(), a.getId()));
                }
            } catch (Exception e) {
                System.out.println("⚠️ Notification updateStatut achat échouée: " + e.getMessage());
            }
        }

        return convertToDTO(a);
    }

    public AchatDTO archiverAchat(Long id) {
        Optional<Achat> opt = achatRepo.findById(id);
        if (opt.isPresent()) {
            Achat a = opt.get();
            a.setArchived(true);
            a.setDateModification(java.time.LocalDateTime.now());
            return convertToDTO(achatRepo.save(a));
        }
        return null;
    }

    public AchatDTO desarchiverAchat(Long id) {
        Optional<Achat> opt = achatRepo.findById(id);
        if (opt.isPresent() && Boolean.TRUE.equals(opt.get().getArchived())) {
            Achat a = opt.get();
            a.setArchived(false);
            a.setDateModification(java.time.LocalDateTime.now());
            return convertToDTO(achatRepo.save(a));
        }
        return null;
    }

    public AchatDTO assignGpAndValidate(Long achatId, Long gpId, String statut) {
        Optional<Achat> optA = achatRepo.findById(achatId);
        if (optA.isEmpty()) return null;

        Optional<GpAgent> optGp = gpRepo.findById(gpId);
        if (optGp.isEmpty()) return null;

        Achat a = optA.get();
        GpAgent gp = optGp.get();

        a.setGpId(gp.getId());
        a.setGpPrenom(gp.getPrenom());
        a.setGpNom(gp.getNom());
        a.setGpPhoneNumber(gp.getPhoneNumber());

        AchatStatus parsed = tryParseStatut(statut);
        if (parsed != null) a.setStatut(parsed.name());

        a.setDateModification(java.time.LocalDateTime.now());
        Achat saved = achatRepo.save(a);

        try {
            AchatStatus newStatus = null;
            try { newStatus = AchatStatus.valueOf(saved.getStatut()); } catch (Exception ignored) {}
            String gpFullName = (gp.getPrenom() + " " + gp.getNom()).trim();
            notificationDispatcher.dispatch(templates.achatGpAssigned(saved.getUserId(), saved.getEmail(),
                    saved.getNumeroTelephone(), saved.getId(), gpFullName, gp.getPhoneNumber(), newStatus));
        } catch (Exception e) {
            System.out.println("⚠️ Notification achatGpAssigned échouée: " + e.getMessage());
        }

        return convertToDTO(saved);
    }

    // ── Helpers ───────────────────────────────────────────────────────────────

    private AchatStatus parseOrDefault(String raw, AchatStatus def) {
        AchatStatus parsed = tryParseStatut(raw);
        return parsed != null ? parsed : def;
    }

    private AchatStatus tryParseStatut(String raw) {
        if (raw == null || raw.trim().isEmpty()) return null;
        String s = raw.trim().toUpperCase(Locale.ROOT);
        s = Normalizer.normalize(s, Normalizer.Form.NFD).replaceAll("\\p{M}", "");
        s = s.replace(' ', '_').replace('-', '_');
        if ("LIVRE".equals(s)) return AchatStatus.LIVRE;
        try { return AchatStatus.valueOf(s); } catch (IllegalArgumentException ex) { return null; }
    }

    private AchatDTO convertToDTO(Achat a) {
        AchatDTO dto = new AchatDTO();
        dto.setId(a.getId());
        dto.setUserId(a.getUserId());
        dto.setNom(a.getNom());
        dto.setPrenom(a.getPrenom());
        dto.setNumeroTelephone(a.getNumeroTelephone());
        dto.setEmail(a.getEmail());
        dto.setPaysLivraison(a.getPaysLivraison());
        dto.setVilleLivraison(a.getVilleLivraison());
        dto.setAdresseLivraison(a.getAdresseLivraison());
        dto.setMarche(a.getMarche());
        dto.setTypeProduit(a.getTypeProduit());
        dto.setDescriptionAchat(a.getDescriptionAchat());
        dto.setLiensProduits(parseJsonList(a.getLiensProduits()));
        dto.setPhotosProduits(parseJsonList(a.getPhotosProduits()));
        dto.setArticlesJson(a.getArticlesJson());
        dto.setQuantite(a.getQuantite());
        dto.setPrixEstime(a.getPrixEstime());
        dto.setPrixTotal(a.getPrixTotal());
        dto.setDevise(a.getDevise());
        dto.setNotesSpeciales(a.getNotesSpeciales());
        dto.setStatut(a.getStatut());
        dto.setArchived(a.getArchived());
        dto.setDateCreation(a.getDateCreation());
        dto.setDateModification(a.getDateModification());
        dto.setGpId(a.getGpId());
        dto.setGpPrenom(a.getGpPrenom());
        dto.setGpNom(a.getGpNom());
        dto.setGpPhoneNumber(a.getGpPhoneNumber());
        dto.setStatutSuivi(a.getStatutSuivi() != null ? a.getStatutSuivi().name() : "EN_ATTENTE");
        dto.setPhotoColisUrl(a.getPhotoColisUrl());
        dto.setPhotoBordereauUrl(a.getPhotoBordereauUrl());
        dto.setNumeroBordereau(a.getNumeroBordereau());
        dto.setDeposePosteAt(a.getDeposePosteAt());
        return dto;
    }

    private void updateFromDto(Achat a, AchatDTO dto) {
        a.setNom(dto.getNom());
        a.setPrenom(dto.getPrenom());
        a.setNumeroTelephone(dto.getNumeroTelephone());
        a.setEmail(dto.getEmail());
        a.setPaysLivraison(dto.getPaysLivraison());
        a.setVilleLivraison(dto.getVilleLivraison());
        a.setAdresseLivraison(dto.getAdresseLivraison());
        a.setMarche(dto.getMarche());
        a.setTypeProduit(dto.getTypeProduit());
        a.setDescriptionAchat(dto.getDescriptionAchat());
        a.setLiensProduits(toJsonList(dto.getLiensProduits()));
        a.setPhotosProduits(toJsonList(dto.getPhotosProduits()));
        a.setArticlesJson(dto.getArticlesJson());
        a.setQuantite(dto.getQuantite());
        a.setPrixEstime(dto.getPrixEstime());
        a.setPrixTotal(dto.getPrixTotal());
        a.setDevise(dto.getDevise());
        a.setNotesSpeciales(dto.getNotesSpeciales());
        a.setStatut(parseOrDefault(dto.getStatut(), AchatStatus.EN_ATTENTE).name());
        a.setArchived(dto.getArchived());
    }
}
