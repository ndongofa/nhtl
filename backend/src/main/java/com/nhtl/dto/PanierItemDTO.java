package com.nhtl.dto;

import java.math.BigDecimal;
import java.time.LocalDateTime;

public class PanierItemDTO {
    private Long id;
    private String userId;
    private Long produitId;
    private String serviceType;
    private Integer quantite;
    private BigDecimal prixUnitaire;
    private String devise;
    private LocalDateTime dateAjout;

    // Enrichissement côté service (nom produit, image)
    private String produitNom;
    private String produitImageUrl;
    private BigDecimal sousTotal;

    // ── Getters & Setters ──────────────────────────────────────────────────────

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public String getUserId() { return userId; }
    public void setUserId(String userId) { this.userId = userId; }

    public Long getProduitId() { return produitId; }
    public void setProduitId(Long produitId) { this.produitId = produitId; }

    public String getServiceType() { return serviceType; }
    public void setServiceType(String serviceType) { this.serviceType = serviceType; }

    public Integer getQuantite() { return quantite; }
    public void setQuantite(Integer quantite) { this.quantite = quantite; }

    public BigDecimal getPrixUnitaire() { return prixUnitaire; }
    public void setPrixUnitaire(BigDecimal prixUnitaire) { this.prixUnitaire = prixUnitaire; }

    public String getDevise() { return devise; }
    public void setDevise(String devise) { this.devise = devise; }

    public LocalDateTime getDateAjout() { return dateAjout; }
    public void setDateAjout(LocalDateTime dateAjout) { this.dateAjout = dateAjout; }

    public String getProduitNom() { return produitNom; }
    public void setProduitNom(String produitNom) { this.produitNom = produitNom; }

    public String getProduitImageUrl() { return produitImageUrl; }
    public void setProduitImageUrl(String produitImageUrl) { this.produitImageUrl = produitImageUrl; }

    public BigDecimal getSousTotal() { return sousTotal; }
    public void setSousTotal(BigDecimal sousTotal) { this.sousTotal = sousTotal; }
}
