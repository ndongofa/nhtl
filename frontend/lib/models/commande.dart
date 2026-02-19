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
  final DateTime? dateCreation;
  final DateTime? dateModification;

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
    this.dateCreation,
    this.dateModification,
  });

  // JSON vers objet
  factory Commande.fromJson(Map<String, dynamic> json) {
    return Commande(
      id: json['id'] as int?,
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
      quantite: json['quantite'] as int,
      prixUnitaire: (json['prixUnitaire'] as num).toDouble(),
      prixTotal: (json['prixTotal'] as num).toDouble(),
      devise: json['devise'] as String? ?? 'USD',
      notesSpeciales: json['notesSpeciales'] as String?,
      statut: json['statut'] as String? ?? 'EN_ATTENTE',
      dateCreation: json['dateCreation'] != null
          ? DateTime.parse(json['dateCreation'] as String)
          : null,
      dateModification: json['dateModification'] != null
          ? DateTime.parse(json['dateModification'] as String)
          : null,
    );
  }

  // Objet vers JSON
  Map<String, dynamic> toJson() {
    return {
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
    };
  }
}
