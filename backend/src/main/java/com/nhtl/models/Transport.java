package com.nhtl.models;

import java.math.BigDecimal;
import java.time.LocalDateTime;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.PrePersist;
import jakarta.persistence.PreUpdate;
import jakarta.persistence.Table;

@Entity
@Table(name = "transports")
public class Transport {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
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

    // Ancien statut texte libre — conservé pour compatibilité
    private String statut;

    // ✅ NOUVEAU — suivi structuré 6 étapes
    @Enumerated(EnumType.STRING)
    @Column(name = "statut_suivi", nullable = false)
    private TransportStatus statutSuivi = TransportStatus.EN_ATTENTE;

    private String typeTransport;

    @Column(name = "gp_id")
    private Long gpId;

    @Column(name = "gp_prenom")
    private String gpPrenom;

    @Column(name = "gp_nom")
    private String gpNom;

    @Column(name = "gp_phone_number")
    private String gpPhoneNumber;

    @Column(nullable = false)
    private Boolean archived = false;

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

    /** Ex : #42 — Dakar → Paris */
    public String getReference() {
        String dep = pointDepart  != null ? pointDepart  : "?";
        String arr = pointArrivee != null ? pointArrivee : "?";
        return "#" + id + " — " + dep + " → " + arr;
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

    public String getPointDepart() { return pointDepart; }
    public void setPointDepart(String p) { this.pointDepart = p; }

    public String getPointArrivee() { return pointArrivee; }
    public void setPointArrivee(String p) { this.pointArrivee = p; }

    public String getPaysExpediteur() { return paysExpediteur; }
    public void setPaysExpediteur(String p) { this.paysExpediteur = p; }

    public String getVilleExpediteur() { return villeExpediteur; }
    public void setVilleExpediteur(String v) { this.villeExpediteur = v; }

    public String getAdresseExpediteur() { return adresseExpediteur; }
    public void setAdresseExpediteur(String a) { this.adresseExpediteur = a; }

    public String getPaysDestinataire() { return paysDestinataire; }
    public void setPaysDestinataire(String p) { this.paysDestinataire = p; }

    public String getVilleDestinataire() { return villeDestinataire; }
    public void setVilleDestinataire(String v) { this.villeDestinataire = v; }

    public String getAdresseDestinataire() { return adresseDestinataire; }
    public void setAdresseDestinataire(String a) { this.adresseDestinataire = a; }

    public String getTypesMarchandise() { return typesMarchandise; }
    public void setTypesMarchandise(String t) { this.typesMarchandise = t; }

    public String getDescription() { return description; }
    public void setDescription(String d) { this.description = d; }

    public BigDecimal getPoids() { return poids; }
    public void setPoids(BigDecimal p) { this.poids = p; }

    public BigDecimal getValeurEstimee() { return valeurEstimee; }
    public void setValeurEstimee(BigDecimal v) { this.valeurEstimee = v; }

    public String getDevise() { return devise; }
    public void setDevise(String d) { this.devise = d; }

    public String getStatut() { return statut; }
    public void setStatut(String s) { this.statut = s; }

    public TransportStatus getStatutSuivi() { return statutSuivi; }
    public void setStatutSuivi(TransportStatus s) { this.statutSuivi = s; }

    public String getTypeTransport() { return typeTransport; }
    public void setTypeTransport(String t) { this.typeTransport = t; }

    public Long getGpId() { return gpId; }
    public void setGpId(Long g) { this.gpId = g; }

    public String getGpPrenom() { return gpPrenom; }
    public void setGpPrenom(String g) { this.gpPrenom = g; }

    public String getGpNom() { return gpNom; }
    public void setGpNom(String g) { this.gpNom = g; }

    public String getGpPhoneNumber() { return gpPhoneNumber; }
    public void setGpPhoneNumber(String g) { this.gpPhoneNumber = g; }

    public Boolean getArchived() { return archived; }
    public void setArchived(Boolean a) { this.archived = a; }

    public LocalDateTime getDateCreation() { return dateCreation; }
    public void setDateCreation(LocalDateTime d) { this.dateCreation = d; }

    public LocalDateTime getDateModification() { return dateModification; }
    public void setDateModification(LocalDateTime d) { this.dateModification = d; }
}