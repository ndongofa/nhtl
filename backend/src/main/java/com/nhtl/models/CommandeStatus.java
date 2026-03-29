package com.nhtl.models;

public enum CommandeStatus {
    EN_ATTENTE,          // commande reçue, en attente de traitement
    COMMANDE_CONFIRMEE,  // commande passée sur la plateforme
    EN_TRANSIT,          // colis en acheminement vers le client
    EN_DOUANE,           // traitement douanier en cours
    ARRIVE,              // arrivé à destination (entrepôt SAMA)
    PRET_LIVRAISON,      // prêt à être livré au destinataire
    LIVREE                // remis au destinataire — statut final
}