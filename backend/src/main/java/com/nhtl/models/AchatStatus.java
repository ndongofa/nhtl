package com.nhtl.models;

public enum AchatStatus {
    EN_ATTENTE,          // demande reçue, en attente de traitement
    ACHAT_CONFIRME,      // achat validé et pris en charge par l'agent
    ACHAT_EFFECTUE,      // produit trouvé et acheté par l'agent
    EN_TRANSIT,          // colis en acheminement vers le client
    ARRIVE,              // arrivé à destination (entrepôt SAMA)
    PRET_LIVRAISON,      // prêt à être livré au destinataire
    LIVRE                // remis au destinataire — statut final
}
