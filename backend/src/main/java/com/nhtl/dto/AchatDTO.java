package com.nhtl.dto;

import java.math.BigDecimal;
import java.time.LocalDateTime;

public class AchatDTO {
    private Long id;
    private String userId;
    private String nom;
    private String prenom;
    private String numeroTelephone;
    private String email;
    private String paysLivraison;
    private String villeLivraison;
    private String adresseLivraison;
    private String marche;
    private String typeProduit;
    private String descriptionAchat;
    private Integer quantite;
    private BigDecimal prixEstime;
    private BigDecimal prixTotal;
    private String devise;
    private String notesSpeciales;
    private String statut;

    // Statut logistique (suivi 7 étapes)
    private String statutSuivi;

    // GP
    private Long gpId;
    private String gpPrenom;
    private String gpNom;
    private String gpPhoneNumber;

    private Boolean archived;
    private LocalDateTime dateCreation;
    private LocalDateTime dateModification;

    // Suivi postal
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

    public String getPaysLivraison() { return paysLivraison; }
    public void setPaysLivraison(String paysLivraison) { this.paysLivraison = paysLivraison; }

    public String getVilleLivraison() { return villeLivraison; }
    public void setVilleLivraison(String villeLivraison) { this.villeLivraison = villeLivraison; }

    public String getAdresseLivraison() { return adresseLivraison; }
    public void setAdresseLivraison(String adresseLivraison) { this.adresseLivraison = adresseLivraison; }

    public String getMarche() { return marche; }
    public void setMarche(String marche) { this.marche = marche; }

    public String getTypeProduit() { return typeProduit; }
    public void setTypeProduit(String typeProduit) { this.typeProduit = typeProduit; }

    public String getDescriptionAchat() { return descriptionAchat; }
    public void setDescriptionAchat(String descriptionAchat) { this.descriptionAchat = descriptionAchat; }

    public Integer getQuantite() { return quantite; }
    public void setQuantite(Integer quantite) { this.quantite = quantite; }

    public BigDecimal getPrixEstime() { return prixEstime; }
    public void setPrixEstime(BigDecimal prixEstime) { this.prixEstime = prixEstime; }

    public BigDecimal getPrixTotal() { return prixTotal; }
    public void setPrixTotal(BigDecimal prixTotal) { this.prixTotal = prixTotal; }

    public String getDevise() { return devise; }
    public void setDevise(String devise) { this.devise = devise; }

    public String getNotesSpeciales() { return notesSpeciales; }
    public void setNotesSpeciales(String notesSpeciales) { this.notesSpeciales = notesSpeciales; }

    public String getStatut() { return statut; }
    public void setStatut(String statut) { this.statut = statut; }

    public String getStatutSuivi() { return statutSuivi; }
    public void setStatutSuivi(String statutSuivi) { this.statutSuivi = statutSuivi; }

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

    public String getPhotoColisUrl() { return photoColisUrl; }
    public void setPhotoColisUrl(String u) { this.photoColisUrl = u; }

    public String getPhotoBordereauUrl() { return photoBordereauUrl; }
    public void setPhotoBordereauUrl(String u) { this.photoBordereauUrl = u; }

    public String getNumeroBordereau() { return numeroBordereau; }
    public void setNumeroBordereau(String n) { this.numeroBordereau = n; }

    public LocalDateTime getDeposePosteAt() { return deposePosteAt; }
    public void setDeposePosteAt(LocalDateTime d) { this.deposePosteAt = d; }
}
