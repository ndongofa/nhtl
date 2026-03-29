// lib/models/commande.dart

class Commande {
  final int? id;
  final String nom;
  final String prenom;
  final String numeroTelephone;
  final String? email;
  final String paysLivraison;
  final String villeLivraison;
  final String adresseLivraison;
  final String plateforme;
  final String lienProduit;
  final String descriptionCommande;
  final int quantite;
  final double prixUnitaire;
  final double prixTotal;
  final String devise;
  final String? notesSpeciales;

  // Statut ADMINISTRATIF (gestion du dossier)
  // Valeurs : EN_ATTENTE, EN_COURS, LIVRE, ANNULE
  final String statut;

  // ✅ Statut LOGISTIQUE (suivi physique de la livraison)
  // Valeurs : EN_ATTENTE, COMMANDE_CONFIRMEE, EN_TRANSIT, EN_DOUANE,
  //           ARRIVE, PRET_LIVRAISON, LIVRE
  final String statutSuivi;

  final bool archived;
  final String? userId;
  final DateTime? dateCreation;
  final DateTime? dateModification;

  // GP assignment
  final int? gpId;
  final String? gpPrenom;
  final String? gpNom;
  final String? gpPhoneNumber;

  Commande({
    this.id,
    required this.nom,
    required this.prenom,
    required this.numeroTelephone,
    this.email,
    required this.paysLivraison,
    required this.villeLivraison,
    required this.adresseLivraison,
    required this.plateforme,
    required this.lienProduit,
    required this.descriptionCommande,
    required this.quantite,
    required this.prixUnitaire,
    required this.prixTotal,
    this.devise = 'EUR',
    this.notesSpeciales,
    this.statut = 'EN_ATTENTE',
    this.statutSuivi = 'EN_ATTENTE',
    this.archived = false,
    this.userId,
    this.dateCreation,
    this.dateModification,
    this.gpId,
    this.gpPrenom,
    this.gpNom,
    this.gpPhoneNumber,
  });

  Commande copyWith({
    int? id,
    String? nom,
    String? prenom,
    String? numeroTelephone,
    String? email,
    String? paysLivraison,
    String? villeLivraison,
    String? adresseLivraison,
    String? plateforme,
    String? lienProduit,
    String? descriptionCommande,
    int? quantite,
    double? prixUnitaire,
    double? prixTotal,
    String? devise,
    String? notesSpeciales,
    String? statut,
    String? statutSuivi,
    bool? archived,
    String? userId,
    DateTime? dateCreation,
    DateTime? dateModification,
    int? gpId,
    String? gpPrenom,
    String? gpNom,
    String? gpPhoneNumber,
  }) {
    return Commande(
      id: id ?? this.id,
      nom: nom ?? this.nom,
      prenom: prenom ?? this.prenom,
      numeroTelephone: numeroTelephone ?? this.numeroTelephone,
      email: email ?? this.email,
      paysLivraison: paysLivraison ?? this.paysLivraison,
      villeLivraison: villeLivraison ?? this.villeLivraison,
      adresseLivraison: adresseLivraison ?? this.adresseLivraison,
      plateforme: plateforme ?? this.plateforme,
      lienProduit: lienProduit ?? this.lienProduit,
      descriptionCommande: descriptionCommande ?? this.descriptionCommande,
      quantite: quantite ?? this.quantite,
      prixUnitaire: prixUnitaire ?? this.prixUnitaire,
      prixTotal: prixTotal ?? this.prixTotal,
      devise: devise ?? this.devise,
      notesSpeciales: notesSpeciales ?? this.notesSpeciales,
      statut: statut ?? this.statut,
      statutSuivi: statutSuivi ?? this.statutSuivi,
      archived: archived ?? this.archived,
      userId: userId ?? this.userId,
      dateCreation: dateCreation ?? this.dateCreation,
      dateModification: dateModification ?? this.dateModification,
      gpId: gpId ?? this.gpId,
      gpPrenom: gpPrenom ?? this.gpPrenom,
      gpNom: gpNom ?? this.gpNom,
      gpPhoneNumber: gpPhoneNumber ?? this.gpPhoneNumber,
    );
  }

  factory Commande.fromJson(Map<String, dynamic> json) {
    return Commande(
      id: (json['id'] as num?)?.toInt(),
      nom: json['nom'] as String? ?? '',
      prenom: json['prenom'] as String? ?? '',
      numeroTelephone: json['numeroTelephone'] as String? ?? '',
      email: json['email'] as String?,
      paysLivraison: json['paysLivraison'] as String? ?? '',
      villeLivraison: json['villeLivraison'] as String? ?? '',
      adresseLivraison: json['adresseLivraison'] as String? ?? '',
      plateforme: json['plateforme'] as String? ?? '',
      lienProduit: json['lienProduit'] as String? ?? '',
      descriptionCommande: json['descriptionCommande'] as String? ?? '',
      quantite: (json['quantite'] as num?)?.toInt() ?? 1,
      prixUnitaire: (json['prixUnitaire'] is int)
          ? (json['prixUnitaire'] as int).toDouble()
          : (json['prixUnitaire'] as double? ?? 0.0),
      prixTotal: (json['prixTotal'] is int)
          ? (json['prixTotal'] as int).toDouble()
          : (json['prixTotal'] as double? ?? 0.0),
      devise: json['devise'] as String? ?? 'EUR',
      notesSpeciales: json['notesSpeciales'] as String?,
      statut: json['statut'] as String? ?? 'EN_ATTENTE',
      // ✅ statutSuivi logistique — défaut EN_ATTENTE si absent
      statutSuivi: json['statutSuivi'] as String? ?? 'EN_ATTENTE',
      archived: json['archived'] is int
          ? (json['archived'] == 1)
          : (json['archived'] as bool? ?? false),
      userId: json['userId'] as String?,
      dateCreation: json['dateCreation'] != null
          ? DateTime.tryParse(json['dateCreation'].toString())
          : null,
      dateModification: json['dateModification'] != null
          ? DateTime.tryParse(json['dateModification'].toString())
          : null,
      gpId: (json['gpId'] as num?)?.toInt(),
      gpPrenom: json['gpPrenom'] as String?,
      gpNom: json['gpNom'] as String?,
      gpPhoneNumber: json['gpPhoneNumber'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nom': nom,
      'prenom': prenom,
      'numeroTelephone': numeroTelephone,
      'email': email,
      'paysLivraison': paysLivraison,
      'villeLivraison': villeLivraison,
      'adresseLivraison': adresseLivraison,
      'plateforme': plateforme,
      'lienProduit': lienProduit,
      'descriptionCommande': descriptionCommande,
      'quantite': quantite,
      'prixUnitaire': prixUnitaire,
      'prixTotal': prixTotal,
      'devise': devise,
      'notesSpeciales': notesSpeciales,
      'statut': statut,
      // statutSuivi géré par PATCH /api/admin/commandes/{id}/status
      'gpId': gpId,
      'gpPrenom': gpPrenom,
      'gpNom': gpNom,
      'gpPhoneNumber': gpPhoneNumber,
    };
  }
}
