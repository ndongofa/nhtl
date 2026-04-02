// lib/models/panier_item.dart

class PanierItem {
  final int? id;
  final String userId;
  final int produitId;
  final String serviceType;
  int quantite;
  final double prixUnitaire;
  final String devise;
  final DateTime? dateAjout;

  // Enrichissement côté client
  final String? produitNom;
  final String? produitImageUrl;

  double get sousTotal => prixUnitaire * quantite;

  PanierItem({
    this.id,
    required this.userId,
    required this.produitId,
    required this.serviceType,
    required this.quantite,
    required this.prixUnitaire,
    this.devise = 'EUR',
    this.dateAjout,
    this.produitNom,
    this.produitImageUrl,
  });

  factory PanierItem.fromJson(Map<String, dynamic> json) {
    return PanierItem(
      id: (json['id'] as num?)?.toInt(),
      userId: json['userId'] as String? ?? '',
      produitId: (json['produitId'] as num?)?.toInt() ?? 0,
      serviceType: json['serviceType'] as String? ?? '',
      quantite: (json['quantite'] as num?)?.toInt() ?? 1,
      prixUnitaire: (json['prixUnitaire'] is int)
          ? (json['prixUnitaire'] as int).toDouble()
          : (json['prixUnitaire'] as double? ?? 0.0),
      devise: json['devise'] as String? ?? 'EUR',
      dateAjout: json['dateAjout'] != null
          ? DateTime.tryParse(json['dateAjout'].toString())
          : null,
      produitNom: json['produitNom'] as String?,
      produitImageUrl: json['produitImageUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'produitId': produitId,
        'quantite': quantite,
      };

  PanierItem copyWith({int? quantite}) => PanierItem(
        id: id,
        userId: userId,
        produitId: produitId,
        serviceType: serviceType,
        quantite: quantite ?? this.quantite,
        prixUnitaire: prixUnitaire,
        devise: devise,
        dateAjout: dateAjout,
        produitNom: produitNom,
        produitImageUrl: produitImageUrl,
      );
}
