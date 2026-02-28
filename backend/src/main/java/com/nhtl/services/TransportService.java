package com.nhtl.services;

import com.nhtl.models.Transport;
import com.nhtl.dto.TransportDTO;
import com.nhtl.repositories.TransportRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;

@Service
public class TransportService {

    @Autowired
    private TransportRepository transportRepository;

    public TransportDTO createTransport(TransportDTO dto) {
        Transport t = new Transport();
        t.setNom(dto.getNom());
        t.setPrenom(dto.getPrenom());
        t.setNumeroTelephone(dto.getNumeroTelephone());
        t.setPaysExpediteur(dto.getPaysExpediteur());
        t.setVilleExpediteur(dto.getVilleExpediteur());
        t.setAdresseExpediteur(dto.getAdresseExpediteur());
        t.setPaysDestinataire(dto.getPaysDestinataire());
        t.setVilleDestinataire(dto.getVilleDestinataire());
        t.setAdresseDestinataire(dto.getAdresseDestinataire());
        t.setTypesMarchandise(dto.getTypesMarchandise());
        t.setDescription(dto.getDescription());
        t.setPoids(dto.getPoids());
        t.setValeurEstimee(dto.getValeurEstimee());
        t.setTypeTransport(dto.getTypeTransport());
        t.setPointDepart(dto.getPointDepart());
        t.setPointArrivee(dto.getPointArrivee());
        t.setStatut(dto.getStatut());
        t.setDateCreation(LocalDateTime.now());
        t.setDateModification(LocalDateTime.now());
        Transport saved = transportRepository.save(t);
        return convertToDTO(saved);
    }

    public TransportDTO getTransportById(Long id) {
        Optional<Transport> t = transportRepository.findById(id);
        return t.map(this::convertToDTO).orElse(null);
    }

    public List<TransportDTO> getAllTransports() {
        return transportRepository.findAll().stream().map(this::convertToDTO).collect(Collectors.toList());
    }

    public List<TransportDTO> getTransportsByStatut(String statut) {
        return transportRepository.findByStatut(statut)
                .stream().map(this::convertToDTO).collect(Collectors.toList());
    }

    public List<TransportDTO> getTransportsByDestinationCountry(String country) {
        return transportRepository.findByPaysDestinataire(country)
                .stream().map(this::convertToDTO).collect(Collectors.toList());
    }

    public List<TransportDTO> getTransportsByPhoneNumber(String numeroTelephone) {
        return transportRepository.findByNumeroTelephone(numeroTelephone)
                .stream().map(this::convertToDTO).collect(Collectors.toList());
    }

    public List<TransportDTO> getTransportsByTypeTransport(String typeTransport) {
        return transportRepository.findByTypeTransport(typeTransport)
                .stream().map(this::convertToDTO).collect(Collectors.toList());
    }

    public List<TransportDTO> getTransportsByPointDepart(String pointDepart) {
        return transportRepository.findByPointDepart(pointDepart)
                .stream().map(this::convertToDTO).collect(Collectors.toList());
    }

    public List<TransportDTO> getTransportsByPointArrivee(String pointArrivee) {
        return transportRepository.findByPointArrivee(pointArrivee)
                .stream().map(this::convertToDTO).collect(Collectors.toList());
    }

    public List<TransportDTO> searchByNomOrPrenom(String nom, String prenom) {
        String nomParam = nom != null ? nom : "";
        String prenomParam = prenom != null ? prenom : "";
        return transportRepository.searchByNomOrPrenom(nomParam, prenomParam)
                .stream()
                .map(this::convertToDTO)
                .collect(Collectors.toList());
    }

    public TransportDTO updateTransport(Long id, TransportDTO dto) {
        Optional<Transport> opt = transportRepository.findById(id);
        if (opt.isPresent()) {
            Transport t = opt.get();
            t.setNom(dto.getNom());
            t.setPrenom(dto.getPrenom());
            t.setNumeroTelephone(dto.getNumeroTelephone());
            t.setPaysExpediteur(dto.getPaysExpediteur());
            t.setVilleExpediteur(dto.getVilleExpediteur());
            t.setAdresseExpediteur(dto.getAdresseExpediteur());
            t.setPaysDestinataire(dto.getPaysDestinataire());
            t.setVilleDestinataire(dto.getVilleDestinataire());
            t.setAdresseDestinataire(dto.getAdresseDestinataire());
            t.setTypesMarchandise(dto.getTypesMarchandise());
            t.setDescription(dto.getDescription());
            t.setPoids(dto.getPoids());
            t.setValeurEstimee(dto.getValeurEstimee());
            t.setTypeTransport(dto.getTypeTransport());
            t.setPointDepart(dto.getPointDepart());
            t.setPointArrivee(dto.getPointArrivee());
            t.setStatut(dto.getStatut());
            t.setDateModification(LocalDateTime.now());
            Transport updated = transportRepository.save(t);
            return convertToDTO(updated);
        }
        return null;
    }

    public boolean deleteTransport(Long id) {
        if (transportRepository.existsById(id)) {
            transportRepository.deleteById(id);
            return true;
        }
        return false;
    }

    private TransportDTO convertToDTO(Transport t) {
        TransportDTO dto = new TransportDTO();
        dto.setId(t.getId());
        dto.setNom(t.getNom());
        dto.setPrenom(t.getPrenom());
        dto.setNumeroTelephone(t.getNumeroTelephone());
        dto.setPaysExpediteur(t.getPaysExpediteur());
        dto.setVilleExpediteur(t.getVilleExpediteur());
        dto.setAdresseExpediteur(t.getAdresseExpediteur());
        dto.setPaysDestinataire(t.getPaysDestinataire());
        dto.setVilleDestinataire(t.getVilleDestinataire());
        dto.setAdresseDestinataire(t.getAdresseDestinataire());
        dto.setTypesMarchandise(t.getTypesMarchandise());
        dto.setDescription(t.getDescription());
        dto.setPoids(t.getPoids());
        dto.setValeurEstimee(t.getValeurEstimee());
        dto.setTypeTransport(t.getTypeTransport());
        dto.setPointDepart(t.getPointDepart());
        dto.setPointArrivee(t.getPointArrivee());
        dto.setStatut(t.getStatut());
        dto.setDateCreation(t.getDateCreation());
        dto.setDateModification(t.getDateModification());
        return dto;
    }
}