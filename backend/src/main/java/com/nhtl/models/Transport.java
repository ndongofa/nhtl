package com.nhtl.models;

import jakarta.persistence.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "transports")
public class Transport {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private String nom;
    private String prenom;
    private String numeroTelephone;
    private String paysExpediteur;
    private String villeExpediteur;
    private String adresseExpediteur;
    private String paysDestinataire;
    private String villeDestinataire;
    private String adresseDestinataire;
    private String typesMarchandise;
    private String description;
    private Double poids;
    private Double valeurEstimee;

    @Column(name = "type_transport", nullable = false)
    private String typeTransport; // <-- OBLIGATOIRE !

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private StatutTransport statut;

    private LocalDateTime dateCreation;
    private LocalDateTime dateModification;

    // Getters & setters
    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }
    public String getNom() { return nom; }
    public void setNom(String nom) { this.nom = nom; }
    public String getPrenom() { return prenom; }
    public void setPrenom(String prenom) { this.prenom = prenom; }
    public String getNumeroTelephone() { return numeroTelephone; }
    public void setNumeroTelephone(String numeroTelephone) { this.numeroTelephone = numeroTelephone; }
    public String getPaysExpediteur() { return paysExpediteur; }
    public void setPaysExpediteur(String paysExpediteur) { this.paysExpediteur = paysExpediteur; }
    public String getVilleExpediteur() { return villeExpediteur; }
    public void setVilleExpediteur(String villeExpediteur) { this.villeExpediteur = villeExpediteur; }
    public String getAdresseExpediteur() { return adresseExpediteur; }
    public void setAdresseExpediteur(String adresseExpediteur) { this.adresseExpediteur = adresseExpediteur; }
    public String getPaysDestinataire() { return paysDestinataire; }
    public void setPaysDestinataire(String paysDestinataire) { this.paysDestinataire = paysDestinataire; }
    public String getVilleDestinataire() { return villeDestinataire; }
    public void setVilleDestinataire(String villeDestinataire) { this.villeDestinataire = villeDestinataire; }
    public String getAdresseDestinataire() { return adresseDestinataire; }
    public void setAdresseDestinataire(String adresseDestinataire) { this.adresseDestinataire = adresseDestinataire; }
    public String getTypesMarchandise() { return typesMarchandise; }
    public void setTypesMarchandise(String typesMarchandise) { this.typesMarchandise = typesMarchandise; }
    public String getDescription() { return description; }
    public void setDescription(String description) { this.description = description; }
    public Double getPoids() { return poids; }
    public void setPoids(Double poids) { this.poids = poids; }
    public Double getValeurEstimee() { return valeurEstimee; }
    public void setValeurEstimee(Double valeurEstimee) { this.valeurEstimee = valeurEstimee; }
    public String getTypeTransport() { return typeTransport; }
    public void setTypeTransport(String typeTransport) { this.typeTransport = typeTransport; }
    public StatutTransport getStatut() { return statut; }
    public void setStatut(StatutTransport statut) { this.statut = statut; }
    public LocalDateTime getDateCreation() { return dateCreation; }
    public void setDateCreation(LocalDateTime dateCreation) { this.dateCreation = dateCreation; }
    public LocalDateTime getDateModification() { return dateModification; }
    public void setDateModification(LocalDateTime dateModification) { this.dateModification = dateModification; }
}