// lib/models/transport.dart

class Transport {
  final int? id;
  final String nom;
  final String prenom;
  final String numeroTelephone;
  final String? email;
  final String paysExpediteur;
  final String villeExpediteur;
  final String adresseExpediteur;
  final String paysDestinataire;
  final String villeDestinataire;
  final String adresseDestinataire;
  final String typesMarchandise;
  final String description;
  final double? poids;
  final double valeurEstimee;
  final String devise;

  // Statut ADMINISTRATIF (gestion du dossier)
  // Valeurs : EN_ATTENTE, EN_COURS, LIVRE, ANNULE
  final String statut;

  // Statut LOGISTIQUE (suivi physique du colis)
  // Valeurs : EN_ATTENTE, DEPART_CONFIRME, EN_TRANSIT, EN_DOUANE,
  //           ARRIVE, PRET_RECUPERATION, LIVRE
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

  Transport({
    this.id,
    required this.nom,
    required this.prenom,
    required this.numeroTelephone,
    this.email,
    required this.paysExpediteur,
    required this.villeExpediteur,
    required this.adresseExpediteur,
    required this.paysDestinataire,
    required this.villeDestinataire,
    required this.adresseDestinataire,
    required this.typesMarchandise,
    required this.description,
    this.poids,
    required this.valeurEstimee,
    required this.devise,
    required this.statut,
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

  Transport copyWith({
    int? id,
    String? nom,
    String? prenom,
    String? numeroTelephone,
    String? email,
    String? paysExpediteur,
    String? villeExpediteur,
    String? adresseExpediteur,
    String? paysDestinataire,
    String? villeDestinataire,
    String? adresseDestinataire,
    String? typesMarchandise,
    String? description,
    double? poids,
    double? valeurEstimee,
    String? devise,
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
    return Transport(
      id: id ?? this.id,
      nom: nom ?? this.nom,
      prenom: prenom ?? this.prenom,
      numeroTelephone: numeroTelephone ?? this.numeroTelephone,
      email: email ?? this.email,
      paysExpediteur: paysExpediteur ?? this.paysExpediteur,
      villeExpediteur: villeExpediteur ?? this.villeExpediteur,
      adresseExpediteur: adresseExpediteur ?? this.adresseExpediteur,
      paysDestinataire: paysDestinataire ?? this.paysDestinataire,
      villeDestinataire: villeDestinataire ?? this.villeDestinataire,
      adresseDestinataire: adresseDestinataire ?? this.adresseDestinataire,
      typesMarchandise: typesMarchandise ?? this.typesMarchandise,
      description: description ?? this.description,
      poids: poids ?? this.poids,
      valeurEstimee: valeurEstimee ?? this.valeurEstimee,
      devise: devise ?? this.devise,
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

  factory Transport.fromJson(Map<String, dynamic> json) {
    return Transport(
      id: (json['id'] as num?)?.toInt(),
      nom: json['nom'] as String? ?? '',
      prenom: json['prenom'] as String? ?? '',
      numeroTelephone: json['numeroTelephone'] as String? ?? '',
      email: json['email'] as String?,
      paysExpediteur: json['paysExpediteur'] as String? ?? '',
      villeExpediteur: json['villeExpediteur'] as String? ?? '',
      adresseExpediteur: json['adresseExpediteur'] as String? ?? '',
      paysDestinataire: json['paysDestinataire'] as String? ?? '',
      villeDestinataire: json['villeDestinataire'] as String? ?? '',
      adresseDestinataire: json['adresseDestinataire'] as String? ?? '',
      typesMarchandise: json['typesMarchandise'] as String? ?? '',
      description: json['description'] as String? ?? '',
      poids: (json['poids'] is int)
          ? (json['poids'] as int).toDouble()
          : (json['poids'] as double?),
      valeurEstimee: (json['valeurEstimee'] is int)
          ? (json['valeurEstimee'] as int).toDouble()
          : (json['valeurEstimee'] as double? ?? 0.0),
      devise: json['devise'] as String? ?? 'EUR',
      statut: json['statut'] as String? ?? 'EN_ATTENTE',
      // ✅ statutSuivi logistique — défaut EN_ATTENTE si absent (old backend)
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
      'paysExpediteur': paysExpediteur,
      'villeExpediteur': villeExpediteur,
      'adresseExpediteur': adresseExpediteur,
      'paysDestinataire': paysDestinataire,
      'villeDestinataire': villeDestinataire,
      'adresseDestinataire': adresseDestinataire,
      'typesMarchandise': typesMarchandise,
      'description': description,
      'poids': poids,
      'valeurEstimee': valeurEstimee,
      'devise': devise,
      'statut': statut,
      // statutSuivi géré par PATCH /status — exclu du POST/PUT
      'gpId': gpId,
      'gpPrenom': gpPrenom,
      'gpNom': gpNom,
      'gpPhoneNumber': gpPhoneNumber,
    };
  }
}
