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
  final String statut;
  final bool archived;
  final String? userId;
  final DateTime? dateCreation;
  final DateTime? dateModification;

  // --- GP assignment (nouveau) ---
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
    this.devise = 'USD',
    this.notesSpeciales,
    this.statut = 'EN_ATTENTE',
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
      nom: json['nom'] as String,
      prenom: json['prenom'] as String,
      numeroTelephone: json['numeroTelephone'] as String,
      email: json['email'] as String?,
      paysLivraison: json['paysLivraison'] as String,
      villeLivraison: json['villeLivraison'] as String,
      adresseLivraison: json['adresseLivraison'] as String,
      plateforme: json['plateforme'] as String,
      lienProduit: json['lienProduit'] as String,
      descriptionCommande: json['descriptionCommande'] as String,
      quantite: (json['quantite'] as num).toInt(),
      prixUnitaire: (json['prixUnitaire'] as num).toDouble(),
      prixTotal: (json['prixTotal'] as num).toDouble(),
      devise: json['devise'] as String? ?? 'USD',
      notesSpeciales: json['notesSpeciales'] as String?,
      statut: json['statut'] as String? ?? 'EN_ATTENTE',
      archived: json['archived'] is int
          ? (json['archived'] == 1)
          : (json['archived'] ?? false),
      userId: json['userId'] as String?,
      dateCreation: json['dateCreation'] != null
          ? DateTime.parse(json['dateCreation'])
          : null,
      dateModification: json['dateModification'] != null
          ? DateTime.parse(json['dateModification'])
          : null,

      // --- GP mapping (nouveau) ---
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
      'archived': archived,
      'userId': userId,

      // --- GP (optionnel) ---
      'gpId': gpId,
      'gpPrenom': gpPrenom,
      'gpNom': gpNom,
      'gpPhoneNumber': gpPhoneNumber,

      // Dates exclues du POST : backend gère la création/MAJ
    };
  }
}
