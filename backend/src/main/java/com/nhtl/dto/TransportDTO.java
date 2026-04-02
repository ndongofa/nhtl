package com.nhtl.dto;

import java.math.BigDecimal;
import java.time.LocalDateTime;

public class TransportDTO {
    private Long id;
    private String userId;
    private String nom;
    private String prenom;
    private String numeroTelephone;
    private String email;

    private String pointDepart;
    private String pointArrivee;

    private String paysExpediteur;
    private String villeExpediteur;
    private String adresseExpediteur;

    private String paysDestinataire;
    private String villeDestinataire;
    private String adresseDestinataire;

    private String typesMarchandise;
    private String description;
    private BigDecimal poids;
    private BigDecimal valeurEstimee;
    private String devise;
    private String statut;
    private String typeTransport;

    // ✅ Statut logistique (suivi 7 étapes)
    private String statutSuivi;

    // GP
    private Long gpId;
    private String gpPrenom;
    private String gpNom;
    private String gpPhoneNumber;

    private Boolean archived;
    private LocalDateTime dateCreation;
    private LocalDateTime dateModification;

    // ✅ Suivi postal
    private String photoColisUrl;
    private String photoBordereauUrl;
    private String numeroBordereau;
    private LocalDateTime deposePosteAt;

    // ── Getters & Setters ──────────────────────────────────────────────────────

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public String getUserId() { return userId; }
    public void setUserId(String userId) { this.userId = userId; }

    public String getNom() { return nom; }
    public void setNom(String nom) { this.nom = nom; }

    public String getPrenom() { return prenom; }
    public void setPrenom(String prenom) { this.prenom = prenom; }

    public String getNumeroTelephone() { return numeroTelephone; }
    public void setNumeroTelephone(String numeroTelephone) { this.numeroTelephone = numeroTelephone; }

    public String getEmail() { return email; }
    public void setEmail(String email) { this.email = email; }

    public String getPointDepart() { return pointDepart; }
    public void setPointDepart(String pointDepart) { this.pointDepart = pointDepart; }

    public String getPointArrivee() { return pointArrivee; }
    public void setPointArrivee(String pointArrivee) { this.pointArrivee = pointArrivee; }

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

    public BigDecimal getPoids() { return poids; }
    public void setPoids(BigDecimal poids) { this.poids = poids; }

    public BigDecimal getValeurEstimee() { return valeurEstimee; }
    public void setValeurEstimee(BigDecimal valeurEstimee) { this.valeurEstimee = valeurEstimee; }

    public String getDevise() { return devise; }
    public void setDevise(String devise) { this.devise = devise; }

    public String getStatut() { return statut; }
    public void setStatut(String statut) { this.statut = statut; }

    public String getStatutSuivi() { return statutSuivi; }
    public void setStatutSuivi(String statutSuivi) { this.statutSuivi = statutSuivi; }

    public String getTypeTransport() { return typeTransport; }
    public void setTypeTransport(String typeTransport) { this.typeTransport = typeTransport; }

    public Long getGpId() { return gpId; }
    public void setGpId(Long gpId) { this.gpId = gpId; }

    public String getGpPrenom() { return gpPrenom; }
    public void setGpPrenom(String gpPrenom) { this.gpPrenom = gpPrenom; }

    public String getGpNom() { return gpNom; }
    public void setGpNom(String gpNom) { this.gpNom = gpNom; }

    public String getGpPhoneNumber() { return gpPhoneNumber; }
    public void setGpPhoneNumber(String gpPhoneNumber) { this.gpPhoneNumber = gpPhoneNumber; }

    public Boolean getArchived() { return archived; }
    public void setArchived(Boolean archived) { this.archived = archived; }

    public LocalDateTime getDateCreation() { return dateCreation; }
    public void setDateCreation(LocalDateTime dateCreation) { this.dateCreation = dateCreation; }

    public LocalDateTime getDateModification() { return dateModification; }
    public void setDateModification(LocalDateTime dateModification) { this.dateModification = dateModification; }

    // ✅ Suivi postal
    public String getPhotoColisUrl() { return photoColisUrl; }
    public void setPhotoColisUrl(String u) { this.photoColisUrl = u; }

    public String getPhotoBordereauUrl() { return photoBordereauUrl; }
    public void setPhotoBordereauUrl(String u) { this.photoBordereauUrl = u; }

    public String getNumeroBordereau() { return numeroBordereau; }
    public void setNumeroBordereau(String n) { this.numeroBordereau = n; }

    public LocalDateTime getDeposePosteAt() { return deposePosteAt; }
    public void setDeposePosteAt(LocalDateTime d) { this.deposePosteAt = d; }
}