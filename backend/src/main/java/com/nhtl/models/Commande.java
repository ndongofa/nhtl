package com.nhtl.models;

import jakarta.persistence.*;
import java.math.BigDecimal;
import java.time.LocalDateTime;

@Entity
@Table(name = "commandes")
public class Commande {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private String userId;

    private String nom;
    private String prenom;
    private String numeroTelephone;
    private String email;

    private String paysLivraison;
    private String villeLivraison;
    @Column(columnDefinition = "TEXT")
    private String adresseLivraison;

    private String plateforme;

    @Column(columnDefinition = "TEXT")
    private String lienProduit;

    @Column(name = "liens_produits", columnDefinition = "TEXT")
    private String liensProduits;

    @Column(name = "photos_produits", columnDefinition = "TEXT")
    private String photosProduits;

    @Column(name = "articles_json", columnDefinition = "TEXT")
    private String articlesJson;

    @Column(columnDefinition = "TEXT")
    private String descriptionCommande;

    private Integer quantite;
    private BigDecimal prixUnitaire;
    private BigDecimal prixTotal;
    private String devise;
    @Column(columnDefinition = "TEXT")
    private String notesSpeciales;

    // Statut ADMINISTRATIF (gestion du dossier)
    // Valeurs : EN_ATTENTE, EN_COURS, LIVRE, ANNULE
    private String statut = "EN_ATTENTE";

    // ✅ Statut LOGISTIQUE (suivi de la livraison physique)
    @Enumerated(EnumType.STRING)
    @Column(name = "statut_suivi_commande", nullable = false)
    private CommandeStatus statutSuivi = CommandeStatus.EN_ATTENTE;

    @Column(nullable = false)
    private Boolean archived = false;

    // GP assignment
    @Column(name = "gp_id")
    private Long gpId;
    @Column(name = "gp_prenom")
    private String gpPrenom;
    @Column(name = "gp_nom")
    private String gpNom;
    @Column(name = "gp_phone_number")
    private String gpPhoneNumber;

    private LocalDateTime dateCreation;
    private LocalDateTime dateModification;

    @PrePersist
    protected void onCreate() {
        dateCreation     = LocalDateTime.now();
        dateModification = LocalDateTime.now();
    }

    @PreUpdate
    protected void onUpdate() {
        dateModification = LocalDateTime.now();
    }

    // ── Helpers ────────────────────────────────────────────────────────────

    public String getReference() {
        return "#" + id + " — " + (plateforme != null ? plateforme : "?")
                + " → " + (paysLivraison != null ? paysLivraison : "?");
    }

    public String getClientFullName() {
        String p = prenom != null ? prenom : "";
        String n = nom    != null ? nom    : "";
        return (p + " " + n).trim();
    }

    // ── Getters & Setters ──────────────────────────────────────────────────

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public String getUserId() { return userId; }
    public void setUserId(String userId) { this.userId = userId; }

    public String getNom() { return nom; }
    public void setNom(String nom) { this.nom = nom; }

    public String getPrenom() { return prenom; }
    public void setPrenom(String prenom) { this.prenom = prenom; }

    public String getNumeroTelephone() { return numeroTelephone; }
    public void setNumeroTelephone(String n) { this.numeroTelephone = n; }

    public String getEmail() { return email; }
    public void setEmail(String email) { this.email = email; }

    public String getPaysLivraison() { return paysLivraison; }
    public void setPaysLivraison(String p) { this.paysLivraison = p; }

    public String getVilleLivraison() { return villeLivraison; }
    public void setVilleLivraison(String v) { this.villeLivraison = v; }

    public String getAdresseLivraison() { return adresseLivraison; }
    public void setAdresseLivraison(String a) { this.adresseLivraison = a; }

    public String getPlateforme() { return plateforme; }
    public void setPlateforme(String p) { this.plateforme = p; }

    public String getLienProduit() { return lienProduit; }
    public void setLienProduit(String l) { this.lienProduit = l; }

    public String getLiensProduits() { return liensProduits; }
    public void setLiensProduits(String l) { this.liensProduits = l; }

    public String getPhotosProduits() { return photosProduits; }
    public void setPhotosProduits(String p) { this.photosProduits = p; }

    public String getArticlesJson() { return articlesJson; }
    public void setArticlesJson(String a) { this.articlesJson = a; }

    public String getDescriptionCommande() { return descriptionCommande; }
    public void setDescriptionCommande(String d) { this.descriptionCommande = d; }

    public Integer getQuantite() { return quantite; }
    public void setQuantite(Integer q) { this.quantite = q; }

    public BigDecimal getPrixUnitaire() { return prixUnitaire; }
    public void setPrixUnitaire(BigDecimal p) { this.prixUnitaire = p; }

    public BigDecimal getPrixTotal() { return prixTotal; }
    public void setPrixTotal(BigDecimal p) { this.prixTotal = p; }

    public String getDevise() { return devise; }
    public void setDevise(String d) { this.devise = d; }

    public String getNotesSpeciales() { return notesSpeciales; }
    public void setNotesSpeciales(String n) { this.notesSpeciales = n; }

    public String getStatut() { return statut; }
    public void setStatut(String s) { this.statut = s; }

    public CommandeStatus getStatutSuivi() { return statutSuivi; }
    public void setStatutSuivi(CommandeStatus s) { this.statutSuivi = s; }

    public Boolean getArchived() { return archived; }
    public void setArchived(Boolean a) { this.archived = a; }

    public Long getGpId() { return gpId; }
    public void setGpId(Long g) { this.gpId = g; }

    public String getGpPrenom() { return gpPrenom; }
    public void setGpPrenom(String g) { this.gpPrenom = g; }

    public String getGpNom() { return gpNom; }
    public void setGpNom(String g) { this.gpNom = g; }

    public String getGpPhoneNumber() { return gpPhoneNumber; }
    public void setGpPhoneNumber(String g) { this.gpPhoneNumber = g; }

    public LocalDateTime getDateCreation() { return dateCreation; }
    public void setDateCreation(LocalDateTime d) { this.dateCreation = d; }

    public LocalDateTime getDateModification() { return dateModification; }
    public void setDateModification(LocalDateTime d) { this.dateModification = d; }

    // ── Suivi postal ──────────────────────────────────────────────────────────
    @Column(name = "photo_colis_url")
    private String photoColisUrl;

    @Column(name = "photo_bordereau_url")
    private String photoBordereauUrl;

    @Column(name = "numero_bordereau", length = 100)
    private String numeroBordereau;

    @Column(name = "depose_poste_at")
    private LocalDateTime deposePosteAt;

    public String getPhotoColisUrl() { return photoColisUrl; }
    public void setPhotoColisUrl(String u) { this.photoColisUrl = u; }

    public String getPhotoBordereauUrl() { return photoBordereauUrl; }
    public void setPhotoBordereauUrl(String u) { this.photoBordereauUrl = u; }

    public String getNumeroBordereau() { return numeroBordereau; }
    public void setNumeroBordereau(String n) { this.numeroBordereau = n; }

    public LocalDateTime getDeposePosteAt() { return deposePosteAt; }
    public void setDeposePosteAt(LocalDateTime d) { this.deposePosteAt = d; }

    public boolean isDeposePoste() { return deposePosteAt != null; }
}