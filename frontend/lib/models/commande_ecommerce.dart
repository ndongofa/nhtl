// lib/models/commande_ecommerce.dart

class CommandeEcommerceItem {
  final int? id;
  final int produitId;
  final String? produitNom;
  final int quantite;
  final double prixUnitaire;
  final double sousTotal;
  final String devise;

  CommandeEcommerceItem({
    this.id,
    required this.produitId,
    this.produitNom,
    required this.quantite,
    required this.prixUnitaire,
    required this.sousTotal,
    this.devise = 'EUR',
  });

  factory CommandeEcommerceItem.fromJson(Map<String, dynamic> json) {
    return CommandeEcommerceItem(
      id: (json['id'] as num?)?.toInt(),
      produitId: (json['produitId'] as num?)?.toInt() ?? 0,
      produitNom: json['produitNom'] as String?,
      quantite: (json['quantite'] as num?)?.toInt() ?? 1,
      prixUnitaire: (json['prixUnitaire'] is int)
          ? (json['prixUnitaire'] as int).toDouble()
          : (json['prixUnitaire'] as double? ?? 0.0),
      sousTotal: (json['sousTotal'] is int)
          ? (json['sousTotal'] as int).toDouble()
          : (json['sousTotal'] as double? ?? 0.0),
      devise: json['devise'] as String? ?? 'EUR',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'produitId': produitId,
        'produitNom': produitNom,
        'quantite': quantite,
        'prixUnitaire': prixUnitaire,
        'sousTotal': sousTotal,
        'devise': devise,
      };
}

class CommandeEcommerce {
  final int? id;
  final String? userId;
  final String nom;
  final String prenom;
  final String numeroTelephone;
  final String? email;
  final String paysLivraison;
  final String villeLivraison;
  final String adresseLivraison;
  final String serviceType;
  final double prixTotal;
  final String devise;
  final String statut;
  final bool archived;
  final String? notesSpeciales;
  final DateTime? dateCommande;
  final DateTime? dateModification;
  final List<CommandeEcommerceItem> items;

  CommandeEcommerce({
    this.id,
    this.userId,
    required this.nom,
    required this.prenom,
    required this.numeroTelephone,
    this.email,
    required this.paysLivraison,
    required this.villeLivraison,
    required this.adresseLivraison,
    required this.serviceType,
    required this.prixTotal,
    this.devise = 'EUR',
    this.statut = 'EN_ATTENTE',
    this.archived = false,
    this.notesSpeciales,
    this.dateCommande,
    this.dateModification,
    this.items = const [],
  });

  factory CommandeEcommerce.fromJson(Map<String, dynamic> json) {
    return CommandeEcommerce(
      id: (json['id'] as num?)?.toInt(),
      userId: json['userId'] as String?,
      nom: json['nom'] as String? ?? '',
      prenom: json['prenom'] as String? ?? '',
      numeroTelephone: json['numeroTelephone'] as String? ?? '',
      email: json['email'] as String?,
      paysLivraison: json['paysLivraison'] as String? ?? '',
      villeLivraison: json['villeLivraison'] as String? ?? '',
      adresseLivraison: json['adresseLivraison'] as String? ?? '',
      serviceType: json['serviceType'] as String? ?? '',
      prixTotal: (json['prixTotal'] is int)
          ? (json['prixTotal'] as int).toDouble()
          : (json['prixTotal'] as double? ?? 0.0),
      devise: json['devise'] as String? ?? 'EUR',
      statut: json['statut'] as String? ?? 'EN_ATTENTE',
      archived: json['archived'] as bool? ?? false,
      notesSpeciales: json['notesSpeciales'] as String?,
      dateCommande: json['dateCommande'] != null
          ? DateTime.tryParse(json['dateCommande'].toString())
          : null,
      dateModification: json['dateModification'] != null
          ? DateTime.tryParse(json['dateModification'].toString())
          : null,
      items: (json['items'] as List<dynamic>?)
              ?.map((i) => CommandeEcommerceItem.fromJson(
                  i as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
        'nom': nom,
        'prenom': prenom,
        'numeroTelephone': numeroTelephone,
        'email': email,
        'paysLivraison': paysLivraison,
        'villeLivraison': villeLivraison,
        'adresseLivraison': adresseLivraison,
        'serviceType': serviceType,
        'devise': devise,
        'notesSpeciales': notesSpeciales,
      };
}
