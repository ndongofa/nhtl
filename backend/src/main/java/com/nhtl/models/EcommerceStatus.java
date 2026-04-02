package com.nhtl.models;

public enum EcommerceStatus {
    EN_ATTENTE,      // commande reçue, en attente de validation
    CONFIRMEE,       // commande confirmée et en préparation
    EN_PREPARATION,  // colis en cours de préparation / expédition
    EN_TRANSIT,      // colis en acheminement vers le client
    LIVREE           // remis au destinataire — statut final
}
