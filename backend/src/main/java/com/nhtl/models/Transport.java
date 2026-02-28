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
    @Column(name = "numero_telephone", nullable = false)
    private String numeroTelephone;
    @Column(name = "pays_expediteur", nullable = false)
    private String paysExpediteur;
    @Column(name = "ville_expediteur", nullable = false)
    private String villeExpediteur;
    @Column(name = "adresse_expediteur", nullable = false)
    private String adresseExpediteur;
    @Column(name = "pays_destinataire", nullable = false)
    private String paysDestinataire;
    @Column(name = "ville_destinataire", nullable = false)
    private String villeDestinataire;
    @Column(name = "adresse_destinataire", nullable = false)
    private String adresseDestinataire;
    @Column(name = "types_marchandise", nullable = false)
    private String typesMarchandise;
    @Column(nullable = false)
    private String description;
    @Column(nullable = false)
    private Double poids;
    @Column(nullable = false)
    private Double valeurEstimee;
    @Column(name = "type_transport", nullable = false)
    private String typeTransport;
    @Column(name = "point_depart", nullable = false)
    private String pointDepart;
    @Column(name = "point_arrivee", nullable = false)
    private String pointArrivee;
    @Column(nullable = false)
    private String statut;
    @Column(name = "date_creation")
    private LocalDateTime dateCreation;
    @Column(name = "date_modification")
    private LocalDateTime dateModification;

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
    public String getPointDepart() { return pointDepart; }
    public void setPointDepart(String pointDepart) { this.pointDepart = pointDepart; }
    public String getPointArrivee() { return pointArrivee; }
    public void setPointArrivee(String pointArrivee) { this.pointArrivee = pointArrivee; }
    public String getStatut() { return statut; }
    public void setStatut(String statut) { this.statut = statut; }
    public LocalDateTime getDateCreation() { return dateCreation; }
    public void setDateCreation(LocalDateTime dateCreation) { this.dateCreation = dateCreation; }
    public LocalDateTime getDateModification() { return dateModification; }
    public void setDateModification(LocalDateTime dateModification) { this.dateModification = dateModification; }
}