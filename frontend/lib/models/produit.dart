// lib/models/produit.dart

class Produit {
  final int? id;
  final String serviceType;
  final String nom;
  final String? description;
  final double prix;
  final String devise;
  final String? categorie;
  final String? imageUrl;
  final List<String> imageUrls;
  final int stock;
  final String? unite;
  final bool actif;
  final DateTime? dateAjout;
  final DateTime? dateModification;

  bool get enStock => stock > 0;

  Produit({
    this.id,
    required this.serviceType,
    required this.nom,
    this.description,
    required this.prix,
    this.devise = 'EUR',
    this.categorie,
    this.imageUrl,
    this.imageUrls = const [],
    this.stock = 0,
    this.unite,
    this.actif = true,
    this.dateAjout,
    this.dateModification,
  });

  factory Produit.fromJson(Map<String, dynamic> json) {
    final rawUrls = json['imageUrls'];
    final List<String> imageUrls = rawUrls is List
        ? rawUrls.map((e) => e.toString()).toList()
        : [];
    return Produit(
      id: (json['id'] as num?)?.toInt(),
      serviceType: json['serviceType'] as String? ?? '',
      nom: json['nom'] as String? ?? '',
      description: json['description'] as String?,
      prix: (json['prix'] is int)
          ? (json['prix'] as int).toDouble()
          : (json['prix'] as double? ?? 0.0),
      devise: json['devise'] as String? ?? 'EUR',
      categorie: json['categorie'] as String?,
      imageUrl: json['imageUrl'] as String?,
      imageUrls: imageUrls,
      stock: (json['stock'] as num?)?.toInt() ?? 0,
      unite: json['unite'] as String?,
      actif: json['actif'] as bool? ?? true,
      dateAjout: json['dateAjout'] != null
          ? DateTime.tryParse(json['dateAjout'].toString())
          : null,
      dateModification: json['dateModification'] != null
          ? DateTime.tryParse(json['dateModification'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'serviceType': serviceType,
        'nom': nom,
        'description': description,
        'prix': prix,
        'devise': devise,
        'categorie': categorie,
        'imageUrl': imageUrl,
        'imageUrls': imageUrls,
        'stock': stock,
        'unite': unite,
        'actif': actif,
      };
}
