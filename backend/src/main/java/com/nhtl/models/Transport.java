package com.nhtl.models;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import jakarta.persistence.*;
import jakarta.validation.constraints.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "transports")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class Transport {
    
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    
    // Informations du client
    @NotBlank(message = "Le nom est obligatoire")
    @Column(nullable = false)
    private String nom;
    
    @NotBlank(message = "Le prénom est obligatoire")
    @Column(nullable = false)
    private String prenom;
    
    @NotBlank(message = "Le numéro de téléphone est obligatoire")
    @Column(nullable = false)
    private String numeroTelephone;
    
    // Informations de l'expéditeur
    @NotBlank(message = "Le pays de l'expéditeur est obligatoire")
    @Column(nullable = false)
    private String paysExpediteur;
    
    @NotBlank(message = "La ville de l'expéditeur est obligatoire")
    @Column(nullable = false)
    private String villeExpediteur;
    
    @NotBlank(message = "L'adresse de l'expéditeur est obligatoire")
    @Column(nullable = false)
    private String adresseExpediteur;
    
    // Informations du destinataire
    @NotBlank(message = "Le pays du destinataire est obligatoire")
    @Column(nullable = false)
    private String paysDestinataire;
    
    @NotBlank(message = "La ville du destinataire est obligatoire")
    @Column(nullable = false)
    private String villeDestinataire;
    
    @NotBlank(message = "L'adresse du destinataire est obligatoire")
    @Column(nullable = false)
    private String adresseDestinataire;
    
    // Informations sur la marchandise
    @NotBlank(message = "Le type de marchandise est obligatoire")
    @Column(nullable = false)
    private String typesMarchandise;
    
    @NotBlank(message = "La description est obligatoire")
    @Column(nullable = false, length = 1000)
    private String description;
    
    @DecimalMin(value = "0.0", inclusive = false, message = "Le poids doit être supérieur à 0")
    private Double poids; // en kg
    
    @DecimalMin(value = "0.0", inclusive = false, message = "La valeur estimée doit être supérieure à 0")
    private Double valeurEstimee; // en devise locale
    
    // Suivi
    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private StatutTransport statut = StatutTransport.EN_ATTENTE;
    
    @Column(nullable = false, updatable = false)
    private LocalDateTime dateCreation = LocalDateTime.now();
    
    private LocalDateTime dateModification;
    
    @PreUpdate
    protected void onUpdate() {
        dateModification = LocalDateTime.now();
    }
}