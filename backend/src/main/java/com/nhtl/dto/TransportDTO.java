package com.nhtl.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import jakarta.validation.constraints.*;
import java.time.LocalDateTime;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class TransportDTO {
    
    private Long id;
    
    @NotBlank(message = "Le nom est obligatoire")
    private String nom;
    
    @NotBlank(message = "Le prénom est obligatoire")
    private String prenom;
    
    @NotBlank(message = "Le numéro de téléphone est obligatoire")
    @Pattern(regexp = "^[+]?[0-9]{9,15}$", message = "Numéro de téléphone invalide")
    private String numeroTelephone;
    
    @NotBlank(message = "Le pays de l'expéditeur est obligatoire")
    private String paysExpediteur;
    
    @NotBlank(message = "La ville de l'expéditeur est obligatoire")
    private String villeExpediteur;
    
    @NotBlank(message = "L'adresse de l'expéditeur est obligatoire")
    private String adresseExpediteur;
    
    @NotBlank(message = "Le pays du destinataire est obligatoire")
    private String paysDestinataire;
    
    @NotBlank(message = "La ville du destinataire est obligatoire")
    private String villeDestinataire;
    
    @NotBlank(message = "L'adresse du destinataire est obligatoire")
    private String adresseDestinataire;
    
    @NotBlank(message = "Le type de marchandise est obligatoire")
    private String typesMarchandise;
    
    @NotBlank(message = "La description est obligatoire")
    @Size(min = 10, max = 1000, message = "La description doit faire entre 10 et 1000 caractères")
    private String description;
    
    @DecimalMin(value = "0.0", inclusive = false, message = "Le poids doit être supérieur à 0")
    private Double poids;
    
    @DecimalMin(value = "0.0", inclusive = false, message = "La valeur estimée doit être supérieure à 0")
    private Double valeurEstimee;
    
    private String statut;
    
    private LocalDateTime dateCreation;
    
    private LocalDateTime dateModification;
}