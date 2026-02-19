package com.nhtl.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import jakarta.validation.constraints.*;
import java.time.LocalDateTime;
import java.math.BigDecimal;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class CommandeDTO {
    
    private Long id;
    
    @NotBlank(message = "Le nom est obligatoire")
    private String nom;
    
    @NotBlank(message = "Le prénom est obligatoire")
    private String prenom;
    
    @NotBlank(message = "Le numéro de téléphone est obligatoire")
    @Pattern(regexp = "^[+]?[0-9]{9,15}$", message = "Numéro de téléphone invalide")
    private String numeroTelephone;
    
    @Email(message = "L'email doit être valide")
    private String email;
    
    @NotBlank(message = "Le pays de livraison est obligatoire")
    private String paysLivraison;
    
    @NotBlank(message = "La ville de livraison est obligatoire")
    private String villeLivraison;
    
    @NotBlank(message = "L'adresse de livraison est obligatoire")
    @Size(min = 10, max = 500, message = "L'adresse doit faire entre 10 et 500 caractères")
    private String adresseLivraison;
    
    @NotNull(message = "La plateforme est obligatoire")
    private String plateforme;
    
    @NotBlank(message = "Le lien du produit est obligatoire")
    private String lienProduit;
    
    @NotBlank(message = "La description de la commande est obligatoire")
    @Size(min = 10, max = 1000, message = "La description doit faire entre 10 et 1000 caractères")
    private String descriptionCommande;
    
    @DecimalMin(value = "1", message = "La quantité doit être au minimum 1")
    private Integer quantite;
    
    @DecimalMin(value = "0.0", inclusive = false, message = "Le prix doit être supérieur à 0")
    private BigDecimal prixUnitaire;
    
    @DecimalMin(value = "0.0", inclusive = false, message = "Le prix total doit être supérieur à 0")
    private BigDecimal prixTotal;
    
    @NotBlank(message = "La devise est obligatoire")
    private String devise = "USD";
    
    private String notesSpeciales;
    
    private String statut;
    
    private LocalDateTime dateCreation;
    
    private LocalDateTime dateModification;
}