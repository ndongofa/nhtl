class Transport {
  final int? id;
  final String nom;
  final String prenom;
  final String numeroTelephone;
  final String paysExpediteur;
  final String villeExpediteur;
  final String adresseExpediteur;
  final String paysDestinataire;
  final String villeDestinataire;
  final String adresseDestinataire;
  final String typesMarchandise;
  final String description;
  final double? poids;
  final double? valeurEstimee;
  final String statut;
  final DateTime? dateCreation;
  final DateTime? dateModification;

  Transport({
    this.id,
    required this.nom,
    required this.prenom,
    required this.numeroTelephone,
    required this.paysExpediteur,
    required this.villeExpediteur,
    required this.adresseExpediteur,
    required this.paysDestinataire,
    required this.villeDestinataire,
    required this.adresseDestinataire,
    required this.typesMarchandise,
    required this.description,
    this.poids,
    this.valeurEstimee,
    this.statut = 'EN_ATTENTE',
    this.dateCreation,
    this.dateModification,
  });

  factory Transport.fromJson(Map<String, dynamic> json) {
    return Transport(
      id: json['id'] as int?,
      nom: json['nom'] as String,
      prenom: json['prenom'] as String,
      numeroTelephone: json['numeroTelephone'] as String,
      paysExpediteur: json['paysExpediteur'] as String,
      villeExpediteur: json['villeExpediteur'] as String,
      adresseExpediteur: json['adresseExpediteur'] as String,
      paysDestinataire: json['paysDestinataire'] as String,
      villeDestinataire: json['villeDestinataire'] as String,
      adresseDestinataire: json['adresseDestinataire'] as String,
      typesMarchandise: json['typesMarchandise'] as String,
      description: json['description'] as String,
      poids: json['poids'] == null
          ? null
          : (json['poids'] is int)
              ? (json['poids'] as int).toDouble()
              : (json['poids'] as double),
      valeurEstimee: json['valeurEstimee'] == null
          ? null
          : (json['valeurEstimee'] is int)
              ? (json['valeurEstimee'] as int).toDouble()
              : (json['valeurEstimee'] as double),
      statut: json['statut'] as String? ?? 'EN_ATTENTE',
      dateCreation: json['dateCreation'] != null
          ? DateTime.parse(json['dateCreation'])
          : null,
      dateModification: json['dateModification'] != null
          ? DateTime.parse(json['dateModification'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nom': nom,
      'prenom': prenom,
      'numeroTelephone': numeroTelephone,
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
      'statut': statut,
      // On n'encode pas les dates ici pour un POST (le backend gère)
    };
  }
}
