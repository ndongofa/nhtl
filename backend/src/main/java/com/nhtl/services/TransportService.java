package com.nhtl.services;

import java.text.Normalizer;
import java.util.List;
import java.util.Locale;
import java.util.Optional;
import java.util.stream.Collectors;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import com.nhtl.dto.TransportDTO;
import com.nhtl.models.GpAgent;
import com.nhtl.models.StatutTransport;
import com.nhtl.models.Transport;
import com.nhtl.notifications.NotificationDispatcher;
import com.nhtl.notifications.NotificationTemplates;
import com.nhtl.repositories.GpAgentRepository;
import com.nhtl.repositories.TransportRepository;

@Service
public class TransportService {

	@Autowired
	private TransportRepository transportRepo;

	@Autowired
	private GpAgentRepository gpRepo;

	// ✅ nouveau: dispatcher multi-canaux
	@Autowired
	private NotificationDispatcher notificationDispatcher;

	// ✅ nouveau: templates
	@Autowired
	private NotificationTemplates templates;

	// ✅ conservé pour éviter toute régression ailleurs (mais plus utilisé dans
	// assignGpAndValidate)
	@Autowired
	private NotificationService notificationService;

	// Création de transport utilisateur
	public TransportDTO createTransport(TransportDTO dto, String userId) {
		Transport t = new Transport();
		t.setUserId(userId);
		t.setNom(dto.getNom());
		t.setPrenom(dto.getPrenom());
		t.setNumeroTelephone(dto.getNumeroTelephone());
		t.setEmail(dto.getEmail());
		t.setPaysExpediteur(dto.getPaysExpediteur());
		t.setVilleExpediteur(dto.getVilleExpediteur());
		t.setAdresseExpediteur(dto.getAdresseExpediteur());
		t.setPaysDestinataire(dto.getPaysDestinataire());
		t.setVilleDestinataire(dto.getVilleDestinataire());
		t.setAdresseDestinataire(dto.getAdresseDestinataire());
		t.setPointDepart(dto.getPointDepart());
		t.setPointArrivee(dto.getPointArrivee());
		t.setTypesMarchandise(dto.getTypesMarchandise());
		t.setDescription(dto.getDescription());
		t.setPoids(dto.getPoids());
		t.setValeurEstimee(dto.getValeurEstimee());
		t.setDevise(dto.getDevise());

		// ✅ statut normalisé + validé (fallback EN_ATTENTE)
		t.setStatut(parseOrDefault(dto.getStatut(), StatutTransport.EN_ATTENTE).name());

		t.setTypeTransport(dto.getTypeTransport());
		t.setDateCreation(java.time.LocalDateTime.now());
		t.setDateModification(java.time.LocalDateTime.now());
		t.setArchived(false);

		// champs GP non définis à la création
		t.setGpId(null);
		t.setGpPrenom(null);
		t.setGpNom(null);
		t.setGpPhoneNumber(null);

		Transport saved = transportRepo.save(t);

		// ✅ Notification "transport reçu" (email/sms/in-app) - ne doit jamais casser
		try {
			notificationDispatcher.dispatch(templates.transportCreated(saved.getUserId(), saved.getEmail(),
					saved.getNumeroTelephone(), saved.getId()));
		} catch (Exception e) {
			System.out.println("⚠️ Notification transportCreated échouée: " + e.getMessage());
		}

		return convertToDTO(saved);
	}

	// Tous les transports de l'utilisateur
	public List<TransportDTO> getAllTransportsForUser(String userId) {
		return transportRepo.findByUserId(userId).stream().map(this::convertToDTO).collect(Collectors.toList());
	}

	// Tous les transports (admin)
	public List<TransportDTO> getAllTransports() {
		return transportRepo.findAll().stream().map(this::convertToDTO).collect(Collectors.toList());
	}

	// Transports archivés (user)
	public List<TransportDTO> getTransportsArchivesForUser(String userId) {
		return transportRepo.findByUserIdAndArchived(userId, true).stream().map(this::convertToDTO)
				.collect(Collectors.toList());
	}

	// Transports archivés (admin)
	public List<TransportDTO> getTransportsArchives() {
		return transportRepo.findByArchived(true).stream().map(this::convertToDTO).collect(Collectors.toList());
	}

	// Transport par ID (user)
	public Optional<TransportDTO> getTransportByIdAndUser(Long id, String userId) {
		return transportRepo.findById(id).filter(t -> t.getUserId().equals(userId)).map(this::convertToDTO);
	}

	// Transport par ID (admin)
	public Optional<TransportDTO> getTransportByIdAndAdmin(Long id) {
		return transportRepo.findById(id).map(this::convertToDTO);
	}

	// Suppression transport (user)
	public boolean deleteTransport(Long id, String userId) {
		Optional<Transport> opt = transportRepo.findById(id);
		if (opt.isPresent() && opt.get().getUserId().equals(userId)) {
			transportRepo.deleteById(id);
			return true;
		}
		return false;
	}

	// Suppression transport (admin)
	public boolean deleteTransportAdmin(Long id) {
		if (transportRepo.existsById(id)) {
			transportRepo.deleteById(id);
			return true;
		}
		return false;
	}

	// Modification transport (user)
	public TransportDTO updateTransport(Long id, TransportDTO dto, String userId) {
		Optional<Transport> opt = transportRepo.findById(id);
		if (opt.isPresent() && opt.get().getUserId().equals(userId)) {
			Transport t = opt.get();
			updateFromDto(t, dto);
			t.setDateModification(java.time.LocalDateTime.now());
			Transport saved = transportRepo.save(t);
			return convertToDTO(saved);
		}
		return null;
	}

	// Modification transport (admin)
	public TransportDTO updateTransportAdmin(Long id, TransportDTO dto) {
		Optional<Transport> opt = transportRepo.findById(id);
		if (opt.isPresent()) {
			Transport t = opt.get();
			updateFromDto(t, dto);
			t.setDateModification(java.time.LocalDateTime.now());
			Transport saved = transportRepo.save(t);
			return convertToDTO(saved);
		}
		return null;
	}

	// Archivage transport (admin)
	public boolean archiveTransport(Long id) {
		Optional<Transport> opt = transportRepo.findById(id);
		if (opt.isPresent()) {
			Transport t = opt.get();
			if (Boolean.TRUE.equals(t.getArchived())) {
				return false;
			}
			t.setArchived(true);
			t.setDateModification(java.time.LocalDateTime.now());
			transportRepo.save(t);
			return true;
		}
		return false;
	}

	// Désarchivage transport (admin)
	public boolean unarchiveTransport(Long id) {
		Optional<Transport> opt = transportRepo.findById(id);
		if (opt.isPresent()) {
			Transport t = opt.get();
			if (!Boolean.TRUE.equals(t.getArchived())) {
				return false;
			}
			t.setArchived(false);
			t.setDateModification(java.time.LocalDateTime.now());
			transportRepo.save(t);
			return true;
		}
		return false;
	}

	// Recherche par statut (admin)
	public List<TransportDTO> searchByStatut(String statut) {
		return transportRepo.findByStatut(statut).stream().map(this::convertToDTO).collect(Collectors.toList());
	}

	// Suppression transport archivé (user)
	public boolean deleteTransportArchive(Long id, String userId) {
		Optional<Transport> opt = transportRepo.findById(id);
		if (opt.isPresent() && opt.get().getUserId().equals(userId) && Boolean.TRUE.equals(opt.get().getArchived())) {
			transportRepo.deleteById(id);
			return true;
		}
		return false;
	}

	/**
	 * Changement de statut transport (ADMIN, PATCH) - accepte aussi variantes
	 * accentuées / espaces - enregistre toujours la version enum - si statut
	 * invalide => ne change rien (retourne l'état courant)
	 */
	public TransportDTO updateStatut(Long id, String statut) {
		Optional<Transport> opt = transportRepo.findById(id);
		if (opt.isEmpty()) {
			return null;
		}

		Transport t = opt.get();

		StatutTransport parsed = tryParseTransportStatut(statut);
		boolean changed = false;

		if (parsed != null) {
			t.setStatut(parsed.name());
			t.setDateModification(java.time.LocalDateTime.now());
			t = transportRepo.save(t);
			changed = true;
		}

		// ✅ Notifications statut (ne doit jamais casser)
		if (changed) {
			try {
				StatutTransport statusEnum = StatutTransport.valueOf(t.getStatut());

				notificationDispatcher.dispatch(templates.transportStatusUpdated(t.getUserId(), t.getEmail(),
						t.getNumeroTelephone(), t.getId(), statusEnum));

				// "accomplissement" transport
				if (statusEnum == StatutTransport.LIVRE) {
					notificationDispatcher.dispatch(templates.transportCompleted(t.getUserId(), t.getEmail(),
							t.getNumeroTelephone(), t.getId()));
				}
			} catch (Exception e) {
				System.out.println("⚠️ Notification updateStatut transport échouée: " + e.getMessage());
			}
		}

		return convertToDTO(t);
	}

	/**
	 * ADMIN: Assigner un GP + (optionnel) changer le statut, puis notifier
	 * l'utilisateur. - si statut invalide => on n’écrase pas le statut existant
	 *
	 * ✅ FIX: éviter doublons in-app - On ne crée plus la notif via
	 * notificationService.create(...) - Le dispatcher crée déjà l'in-app via
	 * InAppProviderImpl
	 */
	public TransportDTO assignGpAndValidate(Long transportId, Long gpId, String statut) {
		Optional<Transport> optT = transportRepo.findById(transportId);
		if (optT.isEmpty()) {
			return null;
		}

		Optional<GpAgent> optGp = gpRepo.findById(gpId);
		if (optGp.isEmpty()) {
			return null;
		}

		Transport t = optT.get();
		GpAgent gp = optGp.get();

		t.setGpId(gp.getId());
		t.setGpPrenom(gp.getPrenom());
		t.setGpNom(gp.getNom());
		t.setGpPhoneNumber(gp.getPhoneNumber());

		StatutTransport parsed = tryParseTransportStatut(statut);
		if (parsed != null) {
			t.setStatut(parsed.name());
		}

		t.setDateModification(java.time.LocalDateTime.now());
		Transport saved = transportRepo.save(t);

		// ✅ Notification multi-canaux (email/sms/in-app) - ne doit jamais casser
		try {
			StatutTransport newStatus = null;
			try {
				newStatus = StatutTransport.valueOf(saved.getStatut());
			} catch (Exception ignored) {
			}

			String gpFullName = (gp.getPrenom() + " " + gp.getNom()).trim();

			notificationDispatcher.dispatch(templates.transportGpAssigned(saved.getUserId(), saved.getEmail(),
					saved.getNumeroTelephone(), saved.getId(), gpFullName, gp.getPhoneNumber(), newStatus));
		} catch (Exception e) {
			System.out.println("⚠️ Notification transportGpAssigned échouée: " + e.getMessage());
		}

		return convertToDTO(saved);
	}

	// ===================== Helpers (normalisation) =====================

	private StatutTransport parseOrDefault(String raw, StatutTransport def) {
		StatutTransport parsed = tryParseTransportStatut(raw);
		return parsed != null ? parsed : def;
	}

	private StatutTransport tryParseTransportStatut(String raw) {
		if (raw == null || raw.trim().isEmpty()) {
			return null;
		}

		String s = raw.trim().toUpperCase(Locale.ROOT);

		// enlever accents
		s = Normalizer.normalize(s, Normalizer.Form.NFD).replaceAll("\\p{M}", "");

		// espaces/tirets -> underscore
		s = s.replace(' ', '_').replace('-', '_');

		// compat éventuelle
		if ("LIVREE".equals(s) || "LIVRE".equals(s)) {
			return StatutTransport.LIVRE;
		}

		try {
			return StatutTransport.valueOf(s);
		} catch (IllegalArgumentException ex) {
			return null;
		}
	}

	// Conversion entity => DTO
	private TransportDTO convertToDTO(Transport t) {
		TransportDTO dto = new TransportDTO();
		dto.setId(t.getId());
		dto.setUserId(t.getUserId());
		dto.setNom(t.getNom());
		dto.setPrenom(t.getPrenom());
		dto.setNumeroTelephone(t.getNumeroTelephone());
		dto.setEmail(t.getEmail());
		dto.setPaysExpediteur(t.getPaysExpediteur());
		dto.setVilleExpediteur(t.getVilleExpediteur());
		dto.setAdresseExpediteur(t.getAdresseExpediteur());
		dto.setPaysDestinataire(t.getPaysDestinataire());
		dto.setVilleDestinataire(t.getVilleDestinataire());
		dto.setAdresseDestinataire(t.getAdresseDestinataire());
		dto.setPointDepart(t.getPointDepart());
		dto.setPointArrivee(t.getPointArrivee());
		dto.setTypesMarchandise(t.getTypesMarchandise());
		dto.setDescription(t.getDescription());
		dto.setPoids(t.getPoids());
		dto.setValeurEstimee(t.getValeurEstimee());
		dto.setDevise(t.getDevise());
		dto.setStatut(t.getStatut());
		dto.setTypeTransport(t.getTypeTransport());
		dto.setDateCreation(t.getDateCreation());
		dto.setDateModification(t.getDateModification());
		dto.setArchived(t.getArchived());

		// GP mapping
		dto.setGpId(t.getGpId());
		dto.setGpPrenom(t.getGpPrenom());
		dto.setGpNom(t.getGpNom());
		dto.setGpPhoneNumber(t.getGpPhoneNumber());

		return dto;
	}

	// Mise à jour entity depuis DTO
	private void updateFromDto(Transport t, TransportDTO dto) {
		t.setNom(dto.getNom());
		t.setPrenom(dto.getPrenom());
		t.setNumeroTelephone(dto.getNumeroTelephone());
		t.setEmail(dto.getEmail());
		t.setPaysExpediteur(dto.getPaysExpediteur());
		t.setVilleExpediteur(dto.getVilleExpediteur());
		t.setAdresseExpediteur(dto.getAdresseExpediteur());
		t.setPaysDestinataire(dto.getPaysDestinataire());
		t.setVilleDestinataire(dto.getVilleDestinataire());
		t.setAdresseDestinataire(dto.getAdresseDestinataire());
		t.setPointDepart(dto.getPointDepart());
		t.setPointArrivee(dto.getPointArrivee());
		t.setTypesMarchandise(dto.getTypesMarchandise());
		t.setDescription(dto.getDescription());
		t.setPoids(dto.getPoids());
		t.setValeurEstimee(dto.getValeurEstimee());
		t.setDevise(dto.getDevise());

		// ✅ normalisé + validé
		t.setStatut(parseOrDefault(dto.getStatut(), StatutTransport.EN_ATTENTE).name());

		t.setTypeTransport(dto.getTypeTransport());
		t.setArchived(dto.getArchived());
		// Ne pas modifier userId ni dateCreation sur update
		// Ne pas modifier GP ici: l'assignation se fait via assignGpAndValidate()
	}
}