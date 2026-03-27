package com.nhtl.models;

public enum StatutTransport {
    EN_ATTENTE,          // état initial à la création
    DEPART_CONFIRME,     // confirmé pour le prochain départ
    EN_TRANSIT,          // en cours d'acheminement
    EN_DOUANE,           // traitement douanier en cours
    ARRIVE,              // arrivé à destination
    PRET_RECUPERATION,   // disponible pour récupération
    LIVRE                // remis au destinataire — statut final
}