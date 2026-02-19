package com.nhtl.services;

import com.nhtl.models.Transport;
import com.nhtl.models.StatutTransport;
import com.nhtl.repositories.TransportRepository;
import com.nhtl.dto.TransportDTO;
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
    
    /**
     * Créer une nouvelle demande de transport
     */
    public TransportDTO createTransport(TransportDTO transportDTO) {
        Transport transport = new Transport();
        transport.setNom(transportDTO.getNom());
        transport.setPrenom(transportDTO.getPrenom());
        transport.setNumeroTelephone(transportDTO.getNumeroTelephone());
        transport.setPaysExpediteur(transportDTO.getPaysExpediteur());
        transport.setVilleExpediteur(transportDTO.getVilleExpediteur());
        transport.setAdresseExpediteur(transportDTO.getAdresseExpediteur());
        transport.setPaysDestinataire(transportDTO.getPaysDestinataire());
        transport.setVilleDestinataire(transportDTO.getVilleDestinataire());
        transport.setAdresseDestinataire(transportDTO.getAdresseDestinataire());
        transport.setTypesMarchandise(transportDTO.getTypesMarchandise());
        transport.setDescription(transportDTO.getDescription());
        transport.setPoids(transportDTO.getPoids());
        transport.setValeurEstimee(transportDTO.getValeurEstimee());
        
        Transport savedTransport = transportRepository.save(transport);
        return convertToDTO(savedTransport);
    }
    
    /**
     * Récupérer un transport par ID
     */
    public TransportDTO getTransportById(Long id) {
        Optional<Transport> transport = transportRepository.findById(id);
        return transport.map(this::convertToDTO).orElse(null);
    }
    
    /**
     * Récupérer tous les transports
     */
    public List<TransportDTO> getAllTransports() {
        return transportRepository.findAll()
                .stream()
                .map(this::convertToDTO)
                .collect(Collectors.toList());
    }
    
    /**
     * Récupérer les transports par statut
     */
    public List<TransportDTO> getTransportsByStatut(String statut) {
        StatutTransport enumStatut = StatutTransport.valueOf(statut.toUpperCase());
        return transportRepository.findByStatut(enumStatut)
                .stream()
                .map(this::convertToDTO)
                .collect(Collectors.toList());
    }
    
    /**
     * Récupérer les transports par numéro de téléphone
     */
    public List<TransportDTO> getTransportsByPhoneNumber(String phoneNumber) {
        return transportRepository.findByNumeroTelephone(phoneNumber)
                .stream()
                .map(this::convertToDTO)
                .collect(Collectors.toList());
    }
    
    /**
     * Récupérer les transports par pays de destination
     */
    public List<TransportDTO> getTransportsByDestinationCountry(String country) {
        return transportRepository.findByPaysDestinataire(country)
                .stream()
                .map(this::convertToDTO)
                .collect(Collectors.toList());
    }
    
    /**
     * Chercher les transports par nom ou prénom
     */
    public List<TransportDTO> searchByNomOrPrenom(String nom, String prenom) {
        return transportRepository.searchByNomOrPrenom(nom, prenom)
                .stream()
                .map(this::convertToDTO)
                .collect(Collectors.toList());
    }
    
    /**
     * Mettre à jour un transport
     */
    public TransportDTO updateTransport(Long id, TransportDTO transportDTO) {
        Optional<Transport> existingTransport = transportRepository.findById(id);
        
        if (existingTransport.isPresent()) {
            Transport transport = existingTransport.get();
            transport.setNom(transportDTO.getNom());
            transport.setPrenom(transportDTO.getPrenom());
            transport.setNumeroTelephone(transportDTO.getNumeroTelephone());
            transport.setPaysExpediteur(transportDTO.getPaysExpediteur());
            transport.setVilleExpediteur(transportDTO.getVilleExpediteur());
            transport.setAdresseExpediteur(transportDTO.getAdresseExpediteur());
            transport.setPaysDestinataire(transportDTO.getPaysDestinataire());
            transport.setVilleDestinataire(transportDTO.getVilleDestinataire());
            transport.setAdresseDestinataire(transportDTO.getAdresseDestinataire());
            transport.setTypesMarchandise(transportDTO.getTypesMarchandise());
            transport.setDescription(transportDTO.getDescription());
            transport.setPoids(transportDTO.getPoids());
            transport.setValeurEstimee(transportDTO.getValeurEstimee());
            
            if (transportDTO.getStatut() != null) {
                transport.setStatut(StatutTransport.valueOf(transportDTO.getStatut().toUpperCase()));
            }
            
            Transport updatedTransport = transportRepository.save(transport);
            return convertToDTO(updatedTransport);
        }
        return null;
    }
    
    /**
     * Supprimer un transport
     */
    public boolean deleteTransport(Long id) {
        if (transportRepository.existsById(id)) {
            transportRepository.deleteById(id);
            return true;
        }
        return false;
    }
    
    /**
     * Convertir Transport entity en TransportDTO
     */
    private TransportDTO convertToDTO(Transport transport) {
        TransportDTO dto = new TransportDTO();
        dto.setId(transport.getId());
        dto.setNom(transport.getNom());
        dto.setPrenom(transport.getPrenom());
        dto.setNumeroTelephone(transport.getNumeroTelephone());
        dto.setPaysExpediteur(transport.getPaysExpediteur());
        dto.setVilleExpediteur(transport.getVilleExpediteur());
        dto.setAdresseExpediteur(transport.getAdresseExpediteur());
        dto.setPaysDestinataire(transport.getPaysDestinataire());
        dto.setVilleDestinataire(transport.getVilleDestinataire());
        dto.setAdresseDestinataire(transport.getAdresseDestinataire());
        dto.setTypesMarchandise(transport.getTypesMarchandise());
        dto.setDescription(transport.getDescription());
        dto.setPoids(transport.getPoids());
        dto.setValeurEstimee(transport.getValeurEstimee());
        dto.setStatut(transport.getStatut().toString());
        dto.setDateCreation(transport.getDateCreation());
        dto.setDateModification(transport.getDateModification());
        return dto;
    }
}