package com.nhtl.dto;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;

public class CommandeEcommerceDTO {
    private Long id;
    private String userId;
    private String nom;
    private String prenom;
    private String numeroTelephone;
    private String email;
    private String paysLivraison;
    private String villeLivraison;
    private String adresseLivraison;
    private String serviceType;
    private BigDecimal prixTotal;
    private String devise;
    private String statut;
    private Boolean archived;
    private String notesSpeciales;
    private LocalDateTime dateCommande;
    private LocalDateTime dateModification;
    private List<CommandeEcommerceItemDTO> items;

    // ── Inner DTO ──────────────────────────────────────────────────────────────
    public static class CommandeEcommerceItemDTO {
        private Long id;
        private Long produitId;
        private String produitNom;
        private Integer quantite;
        private BigDecimal prixUnitaire;
        private BigDecimal sousTotal;
        private String devise;

        public Long getId() { return id; }
        public void setId(Long id) { this.id = id; }
        public Long getProduitId() { return produitId; }
        public void setProduitId(Long produitId) { this.produitId = produitId; }
        public String getProduitNom() { return produitNom; }
        public void setProduitNom(String produitNom) { this.produitNom = produitNom; }
        public Integer getQuantite() { return quantite; }
        public void setQuantite(Integer quantite) { this.quantite = quantite; }
        public BigDecimal getPrixUnitaire() { return prixUnitaire; }
        public void setPrixUnitaire(BigDecimal prixUnitaire) { this.prixUnitaire = prixUnitaire; }
        public BigDecimal getSousTotal() { return sousTotal; }
        public void setSousTotal(BigDecimal sousTotal) { this.sousTotal = sousTotal; }
        public String getDevise() { return devise; }
        public void setDevise(String devise) { this.devise = devise; }
    }

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

    public String getServiceType() { return serviceType; }
    public void setServiceType(String serviceType) { this.serviceType = serviceType; }

    public BigDecimal getPrixTotal() { return prixTotal; }
    public void setPrixTotal(BigDecimal prixTotal) { this.prixTotal = prixTotal; }

    public String getDevise() { return devise; }
    public void setDevise(String devise) { this.devise = devise; }

    public String getStatut() { return statut; }
    public void setStatut(String statut) { this.statut = statut; }

    public Boolean getArchived() { return archived; }
    public void setArchived(Boolean archived) { this.archived = archived; }

    public String getNotesSpeciales() { return notesSpeciales; }
    public void setNotesSpeciales(String notesSpeciales) { this.notesSpeciales = notesSpeciales; }

    public LocalDateTime getDateCommande() { return dateCommande; }
    public void setDateCommande(LocalDateTime dateCommande) { this.dateCommande = dateCommande; }

    public LocalDateTime getDateModification() { return dateModification; }
    public void setDateModification(LocalDateTime dateModification) { this.dateModification = dateModification; }

    public List<CommandeEcommerceItemDTO> getItems() { return items; }
    public void setItems(List<CommandeEcommerceItemDTO> items) { this.items = items; }
}
