package com.nhtl.models;

import jakarta.persistence.*;
import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

@Entity
@Table(name = "commandes_ecommerce")
public class CommandeEcommerce {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "user_id", nullable = false)
    private String userId;

    // Infos client
    private String nom;
    private String prenom;
    private String numeroTelephone;
    private String email;

    // Livraison
    private String paysLivraison;
    private String villeLivraison;
    private String adresseLivraison;

    @Enumerated(EnumType.STRING)
    @Column(name = "service_type", nullable = false)
    private ServiceType serviceType;

    @Column(name = "prix_total", nullable = false, precision = 12, scale = 2)
    private BigDecimal prixTotal = BigDecimal.ZERO;

    private String devise = "EUR";

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private EcommerceStatus statut = EcommerceStatus.EN_ATTENTE;

    @Column(nullable = false)
    private Boolean archived = false;

    private String notesSpeciales;

    @Column(name = "date_commande")
    private LocalDateTime dateCommande;

    @Column(name = "date_modification")
    private LocalDateTime dateModification;

    @OneToMany(mappedBy = "commandeEcommerce", cascade = CascadeType.ALL, orphanRemoval = true)
    private List<CommandeEcommerceItem> items = new ArrayList<>();

    @PrePersist
    protected void onCreate() {
        dateCommande     = LocalDateTime.now();
        dateModification = LocalDateTime.now();
    }

    @PreUpdate
    protected void onUpdate() {
        dateModification = LocalDateTime.now();
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

    public ServiceType getServiceType() { return serviceType; }
    public void setServiceType(ServiceType serviceType) { this.serviceType = serviceType; }

    public BigDecimal getPrixTotal() { return prixTotal; }
    public void setPrixTotal(BigDecimal prixTotal) { this.prixTotal = prixTotal; }

    public String getDevise() { return devise; }
    public void setDevise(String devise) { this.devise = devise; }

    public EcommerceStatus getStatut() { return statut; }
    public void setStatut(EcommerceStatus statut) { this.statut = statut; }

    public Boolean getArchived() { return archived; }
    public void setArchived(Boolean archived) { this.archived = archived; }

    public String getNotesSpeciales() { return notesSpeciales; }
    public void setNotesSpeciales(String n) { this.notesSpeciales = n; }

    public LocalDateTime getDateCommande() { return dateCommande; }
    public void setDateCommande(LocalDateTime dateCommande) { this.dateCommande = dateCommande; }

    public LocalDateTime getDateModification() { return dateModification; }
    public void setDateModification(LocalDateTime dateModification) { this.dateModification = dateModification; }

    public List<CommandeEcommerceItem> getItems() { return items; }
    public void setItems(List<CommandeEcommerceItem> items) { this.items = items; }
}
