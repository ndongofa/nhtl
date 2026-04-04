// lib/services/ad_service.dart

import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/ad_model.dart';
import 'ad_api_service.dart';

class AdService extends ChangeNotifier {
  final _api = AdApiService();
  Timer? _refreshTimer;

  List<AdModel> _ads = [];
  bool _loaded = false;

  // Publicités par défaut (utilisées si l'API est indisponible)
  static final List<AdModel> _fallback = [
    const AdModel(
      emoji: '✈️',
      title: 'Prochain départ Paris → Dakar',
      subtitle: 'Envoyez vos colis en 5 à 10 jours · Tarifs compétitifs',
      colorHex: '#004EDA',
      colorEndHex: '#0D5BBF',
      position: 0,
      adType: AdModel.typeText,
    ),
    const AdModel(
      emoji: '🛒',
      title: 'Commandez depuis Amazon, Temu & Shein',
      subtitle: 'Livraison directe chez vous — Paris · Casablanca · Dakar',
      colorHex: '#FBBF24',
      colorEndHex: '#E65100',
      position: 1,
      adType: AdModel.typeText,
    ),
    const AdModel(
      emoji: '🌿',
      title: 'Sama Maad — Fraîcheur du Sénégal',
      subtitle: 'Maad de qualité directement depuis le terroir sénégalais',
      colorHex: '#16A34A',
      colorEndHex: '#14532D',
      position: 2,
      adType: AdModel.typeText,
    ),
  ];

  List<AdModel> get ads => _ads.isNotEmpty ? _ads : _fallback;

  bool get isLoaded => _loaded;

  Future<void> load() async {
    final result = await _api.getPublicAds();
    // null means the request failed — keep the current list intact
    _applyResult(result);
    _loaded = true;
    notifyListeners();
    // ??= ensures only one timer is ever created even if load() is called again
    _refreshTimer ??= Timer.periodic(const Duration(minutes: 5), (_) => _silentRefresh());
  }

  // Updates _ads and notifies listeners when result is non-null (success).
  void _applyResult(List<AdModel>? result) {
    if (result != null) {
      _ads = result;
    }
  }

  Future<void> _silentRefresh() async {
    final result = await _api.getPublicAds();
    if (result != null) {
      _applyResult(result);
      notifyListeners();
    }
  }

  Future<void> reload() async {
    _loaded = false;
    await load();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }
}
