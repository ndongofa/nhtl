// lib/models/ad_model.dart

import 'package:flutter/material.dart';

/// Type d'une publicité dans le carousel.
/// - `AdModel.typeText`    : emoji + texte sur fond dégradé (comportement actuel)
/// - `AdModel.typeImage`   : image/GIF depuis une URL, texte en overlay
/// - `AdModel.typeYoutube` : lecteur YouTube intégré (muet, autoplay)
class AdModel {
  static const String typeText = 'text';
  static const String typeImage = 'image';
  static const String typeYoutube = 'youtube';

  final int? id;
  final String emoji;
  final String title;
  final String subtitle;
  final String colorHex;
  final String colorEndHex;
  final int position;
  final bool isActive;
  final String adType;
  final String? imageUrl;
  final String? youtubeId;
  final String? serviceType;

  const AdModel({
    this.id,
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.colorHex,
    required this.colorEndHex,
    this.position = 0,
    this.isActive = true,
    this.adType = AdModel.typeText,
    this.imageUrl,
    this.youtubeId,
    this.serviceType,
  });

  Color get color => _hexToColor(colorHex);
  Color get colorEnd => _hexToColor(colorEndHex);

  static Color _hexToColor(String hex) {
    final cleaned = hex.replaceAll('#', '').trim();
    if (cleaned.length == 6) {
      return Color(int.parse('FF$cleaned', radix: 16));
    } else if (cleaned.length == 8) {
      return Color(int.parse(cleaned, radix: 16));
    }
    return const Color(0xFF004EDA);
  }

  factory AdModel.fromJson(Map<String, dynamic> json) => AdModel(
        id: json['id'] as int?,
        emoji: json['emoji'] as String? ?? '📢',
        title: json['title'] as String? ?? '',
        subtitle: json['subtitle'] as String? ?? '',
        colorHex: json['colorHex'] as String? ?? '#004EDA',
        colorEndHex: json['colorEndHex'] as String? ?? '#0D5BBF',
        position: json['position'] as int? ?? 0,
        isActive: json['isActive'] as bool? ?? true,
        adType: json['adType'] as String? ?? AdModel.typeText,
        imageUrl: json['imageUrl'] as String?,
        youtubeId: json['youtubeId'] as String?,
        serviceType: json['serviceType'] as String?,
      );

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'emoji': emoji,
        'title': title,
        'subtitle': subtitle,
        'colorHex': colorHex,
        'colorEndHex': colorEndHex,
        'position': position,
        'isActive': isActive,
        'adType': adType,
        if (imageUrl != null) 'imageUrl': imageUrl,
        if (youtubeId != null) 'youtubeId': youtubeId,
        if (serviceType != null) 'serviceType': serviceType,
      };

  AdModel copyWith({
    int? id,
    String? emoji,
    String? title,
    String? subtitle,
    String? colorHex,
    String? colorEndHex,
    int? position,
    bool? isActive,
    String? adType,
    String? imageUrl,
    String? youtubeId,
    String? serviceType,
  }) =>
      AdModel(
        id: id ?? this.id,
        emoji: emoji ?? this.emoji,
        title: title ?? this.title,
        subtitle: subtitle ?? this.subtitle,
        colorHex: colorHex ?? this.colorHex,
        colorEndHex: colorEndHex ?? this.colorEndHex,
        position: position ?? this.position,
        isActive: isActive ?? this.isActive,
        adType: adType ?? this.adType,
        imageUrl: imageUrl ?? this.imageUrl,
        youtubeId: youtubeId ?? this.youtubeId,
        serviceType: serviceType ?? this.serviceType,
      );
}
