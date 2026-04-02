// lib/models/article_item.dart
//
// Représente un article dans le formulaire multi-articles (commande ou achat).
// Deux types :
//   - 'lien'  : article avec URL + quantité + prix unitaire + total
//   - 'photo' : article avec photo + titre + description

class ArticleItem {
  final String type; // 'lien' ou 'photo'

  // Champs spécifiques aux articles avec lien
  final String lien;
  final int quantite;
  final double prixUnitaire;
  final double prixTotal;

  // Champs spécifiques aux articles avec photo
  final String photoUrl;
  final String titre;
  final String description;

  const ArticleItem({
    required this.type,
    this.lien = '',
    this.quantite = 1,
    this.prixUnitaire = 0.0,
    this.prixTotal = 0.0,
    this.photoUrl = '',
    this.titre = '',
    this.description = '',
  });

  bool get isLien => type == 'lien';
  bool get isPhoto => type == 'photo';

  ArticleItem copyWith({
    String? type,
    String? lien,
    int? quantite,
    double? prixUnitaire,
    double? prixTotal,
    String? photoUrl,
    String? titre,
    String? description,
  }) {
    return ArticleItem(
      type: type ?? this.type,
      lien: lien ?? this.lien,
      quantite: quantite ?? this.quantite,
      prixUnitaire: prixUnitaire ?? this.prixUnitaire,
      prixTotal: prixTotal ?? this.prixTotal,
      photoUrl: photoUrl ?? this.photoUrl,
      titre: titre ?? this.titre,
      description: description ?? this.description,
    );
  }

  factory ArticleItem.fromJson(Map<String, dynamic> json) {
    return ArticleItem(
      type: json['type'] as String? ?? 'lien',
      lien: json['lien'] as String? ?? '',
      quantite: (json['quantite'] as num?)?.toInt() ?? 1,
      prixUnitaire: (json['prixUnitaire'] as num?)?.toDouble() ?? 0.0,
      prixTotal: (json['prixTotal'] as num?)?.toDouble() ?? 0.0,
      photoUrl: json['photoUrl'] as String? ?? '',
      titre: json['titre'] as String? ?? '',
      description: json['description'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'lien': lien,
      'quantite': quantite,
      'prixUnitaire': prixUnitaire,
      'prixTotal': prixTotal,
      'photoUrl': photoUrl,
      'titre': titre,
      'description': description,
    };
  }
}
