// lib/models/achat.dart
//
// Modèle Dart pour le service Sama Achat (achats sur mesure)
// Structurellement similaire à Commande mais avec marche/typeProduit
// à la place de plateforme/lienProduit.

class Achat {
  final int? id;
  final String nom;
  final String prenom;
  final String numeroTelephone;
  final String? email;
  final String paysLivraison;
  final String villeLivraison;
  final String adresseLivraison;
  final String marche;         // marché ou boutique cible
  final String typeProduit;    // catégorie / type de produit
  final String descriptionAchat;
  final List<String> liensProduits;
  final List<String> photosProduits;
  final String? articlesJson;
  final int quantite;
  final double prixEstime;
  final double prixTotal;
  final String devise;
  final String? notesSpeciales;

  // Statut ADMINISTRATIF
  // Valeurs : EN_ATTENTE, EN_COURS, LIVRE, ANNULE
  final String statut;

  // Statut LOGISTIQUE (suivi physique)
  // Valeurs : EN_ATTENTE, ACHAT_CONFIRME, ACHAT_EFFECTUE, EN_TRANSIT,
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

  // Suivi postal
  final String? photoColisUrl;
  final String? photoBordereauUrl;
  final String? numeroBordereau;
  final DateTime? deposePosteAt;

  bool get isDeposePoste => deposePosteAt != null;

  Achat({
    this.id,
    required this.nom,
    required this.prenom,
    required this.numeroTelephone,
    this.email,
    required this.paysLivraison,
    required this.villeLivraison,
    required this.adresseLivraison,
    required this.marche,
    required this.typeProduit,
    required this.descriptionAchat,
    this.liensProduits = const [],
    this.photosProduits = const [],
    this.articlesJson,
    required this.quantite,
    required this.prixEstime,
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
    this.photoColisUrl,
    this.photoBordereauUrl,
    this.numeroBordereau,
    this.deposePosteAt,
  });

  Achat copyWith({
    int? id,
    String? nom,
    String? prenom,
    String? numeroTelephone,
    String? email,
    String? paysLivraison,
    String? villeLivraison,
    String? adresseLivraison,
    String? marche,
    String? typeProduit,
    String? descriptionAchat,
    List<String>? liensProduits,
    List<String>? photosProduits,
    String? articlesJson,
    int? quantite,
    double? prixEstime,
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
    String? photoColisUrl,
    String? photoBordereauUrl,
    String? numeroBordereau,
    DateTime? deposePosteAt,
  }) {
    return Achat(
      id: id ?? this.id,
      nom: nom ?? this.nom,
      prenom: prenom ?? this.prenom,
      numeroTelephone: numeroTelephone ?? this.numeroTelephone,
      email: email ?? this.email,
      paysLivraison: paysLivraison ?? this.paysLivraison,
      villeLivraison: villeLivraison ?? this.villeLivraison,
      adresseLivraison: adresseLivraison ?? this.adresseLivraison,
      marche: marche ?? this.marche,
      typeProduit: typeProduit ?? this.typeProduit,
      descriptionAchat: descriptionAchat ?? this.descriptionAchat,
      liensProduits: liensProduits ?? this.liensProduits,
      photosProduits: photosProduits ?? this.photosProduits,
      articlesJson: articlesJson ?? this.articlesJson,
      quantite: quantite ?? this.quantite,
      prixEstime: prixEstime ?? this.prixEstime,
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
      photoColisUrl: photoColisUrl ?? this.photoColisUrl,
      photoBordereauUrl: photoBordereauUrl ?? this.photoBordereauUrl,
      numeroBordereau: numeroBordereau ?? this.numeroBordereau,
      deposePosteAt: deposePosteAt ?? this.deposePosteAt,
    );
  }

  factory Achat.fromJson(Map<String, dynamic> json) {
    return Achat(
      id: (json['id'] as num?)?.toInt(),
      nom: json['nom'] as String? ?? '',
      prenom: json['prenom'] as String? ?? '',
      numeroTelephone: json['numeroTelephone'] as String? ?? '',
      email: json['email'] as String?,
      paysLivraison: json['paysLivraison'] as String? ?? '',
      villeLivraison: json['villeLivraison'] as String? ?? '',
      adresseLivraison: json['adresseLivraison'] as String? ?? '',
      marche: json['marche'] as String? ?? '',
      typeProduit: json['typeProduit'] as String? ?? '',
      descriptionAchat: json['descriptionAchat'] as String? ?? '',
      liensProduits: (json['liensProduits'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      photosProduits: (json['photosProduits'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      articlesJson: json['articlesJson'] as String?,
      quantite: (json['quantite'] as num?)?.toInt() ?? 1,
      prixEstime: (json['prixEstime'] is int)
          ? (json['prixEstime'] as int).toDouble()
          : (json['prixEstime'] as double? ?? 0.0),
      prixTotal: (json['prixTotal'] is int)
          ? (json['prixTotal'] as int).toDouble()
          : (json['prixTotal'] as double? ?? 0.0),
      devise: json['devise'] as String? ?? 'EUR',
      notesSpeciales: json['notesSpeciales'] as String?,
      statut: json['statut'] as String? ?? 'EN_ATTENTE',
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
      photoColisUrl: json['photoColisUrl'] as String?,
      photoBordereauUrl: json['photoBordereauUrl'] as String?,
      numeroBordereau: json['numeroBordereau'] as String?,
      deposePosteAt: json['deposePosteAt'] != null
          ? DateTime.tryParse(json['deposePosteAt'].toString())
          : null,
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
      'marche': marche,
      'typeProduit': typeProduit,
      'descriptionAchat': descriptionAchat,
      'liensProduits': liensProduits,
      'photosProduits': photosProduits,
      'articlesJson': articlesJson,
      'quantite': quantite,
      'prixEstime': prixEstime,
      'prixTotal': prixTotal,
      'devise': devise,
      'notesSpeciales': notesSpeciales,
      'statut': statut,
      'gpId': gpId,
      'gpPrenom': gpPrenom,
      'gpNom': gpNom,
      'gpPhoneNumber': gpPhoneNumber,
    };
  }
}
