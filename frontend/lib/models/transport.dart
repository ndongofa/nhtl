class Transport {
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
  final double poids;
  final double valeurEstimee;
  final String typeTransport;
  final String pointDepart;
  final String pointArrivee;
  final String statut;

  Transport({
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
    required this.poids,
    required this.valeurEstimee,
    required this.typeTransport,
    required this.pointDepart,
    required this.pointArrivee,
    required this.statut,
  });

  Map<String, dynamic> toJson() => {
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
        'typeTransport': typeTransport,
        'pointDepart': pointDepart,
        'pointArrivee': pointArrivee,
        'statut': statut,
      };

  factory Transport.fromJson(Map<String, dynamic> json) => Transport(
        nom: json['nom'],
        prenom: json['prenom'],
        numeroTelephone: json['numeroTelephone'],
        paysExpediteur: json['paysExpediteur'],
        villeExpediteur: json['villeExpediteur'],
        adresseExpediteur: json['adresseExpediteur'],
        paysDestinataire: json['paysDestinataire'],
        villeDestinataire: json['villeDestinataire'],
        adresseDestinataire: json['adresseDestinataire'],
        typesMarchandise: json['typesMarchandise'],
        description: json['description'],
        poids: (json['poids'] as num).toDouble(),
        valeurEstimee: (json['valeurEstimee'] as num).toDouble(),
        typeTransport: json['typeTransport'],
        pointDepart: json['pointDepart'],
        pointArrivee: json['pointArrivee'],
        statut: json['statut'],
      );
}
