package com.nhtl.models;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import jakarta.persistence.*;
import jakarta.validation.constraints.*;
import java.time.LocalDateTime;
import java.math.BigDecimal;

@Entity
@Table(name = "commandes")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class Commande {
    
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
    
    @Email(message = "L'email doit être valide")
    private String email;
    
    // Informations de livraison
    @NotBlank(message = "Le pays de livraison est obligatoire")
    @Column(nullable = false)
    private String paysLivraison;
    
    @NotBlank(message = "La ville de livraison est obligatoire")
    @Column(nullable = false)
    private String villeLivraison;
    
    @NotBlank(message = "L'adresse de livraison est obligatoire")
    @Column(nullable = false, length = 500)
    private String adresseLivraison;
    
    // Plateforme de commande
    @NotNull(message = "La plateforme est obligatoire")
    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private Plateforme plateforme;
    
    // Lien ou URL du produit
    @NotBlank(message = "Le lien du produit est obligatoire")
    @Column(nullable = false, length = 1000)
    private String lienProduit;
    
    // Description du produit commandé
    @NotBlank(message = "La description de la commande est obligatoire")
    @Column(nullable = false, length = 1000)
    private String descriptionCommande;
    
    // Détails de la commande
    @DecimalMin(value = "0.0", inclusive = false, message = "La quantité doit être supérieure à 0")
    @Column(nullable = false)
    private Integer quantite;
    
    @DecimalMin(value = "0.0", inclusive = false, message = "Le prix doit être supérieur à 0")
    @Column(nullable = false)
    private BigDecimal prixUnitaire;
    
    @Column(nullable = false)
    private BigDecimal prixTotal;
    
    // Devise utilisée
    @NotBlank(message = "La devise est obligatoire")
    @Column(nullable = false)
    private String devise = "USD";
    
    // Notes supplémentaires
    @Column(length = 1000)
    private String notesSpeciales;
    
    // Suivi
    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private StatutCommande statut = StatutCommande.EN_ATTENTE;
    
    @Column(nullable = false, updatable = false)
    private LocalDateTime dateCreation = LocalDateTime.now();
    
    private LocalDateTime dateModification;
    
    @PreUpdate
    protected void onUpdate() {
        dateModification = LocalDateTime.now();
    }
}