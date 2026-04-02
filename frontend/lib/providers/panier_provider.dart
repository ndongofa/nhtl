// lib/providers/panier_provider.dart
//
// Gestion d'état du panier e-commerce avec persistance SharedPreferences.
// Paramétré par serviceType : 'maad' | 'teranga' | 'bestseller'

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/panier_item.dart';
import '../services/ecommerce_service.dart';

class PanierProvider extends ChangeNotifier {
  final String serviceType;
  late EcommerceService _service;

  List<PanierItem> _items = [];
  bool _loading = false;

  PanierProvider({required this.serviceType}) {
    _service = EcommerceService(serviceType: serviceType);
    _loadFromCache();
  }

  List<PanierItem> get items => List.unmodifiable(_items);
  bool get loading => _loading;
  bool get isEmpty => _items.isEmpty;
  int get nbArticles =>
      _items.fold(0, (sum, item) => sum + item.quantite);

  double get total =>
      _items.fold(0.0, (sum, item) => sum + item.sousTotal);

  String get devise => _items.isNotEmpty ? _items.first.devise : 'EUR';

  // ── Chargement depuis le serveur ──────────────────────────────────────────

  Future<void> charger() async {
    _loading = true;
    notifyListeners();
    try {
      final serverItems = await _service.getPanier();
      _items = serverItems;
      _saveToCache();
    } catch (_) {
      // Garder les items en cache si le serveur est inaccessible
    }
    _loading = false;
    notifyListeners();
  }

  // ── Ajouter / modifier ────────────────────────────────────────────────────

  Future<bool> ajouter(int produitId, int quantite,
      {String? nom, String? imageUrl, double? prix, String? devise}) async {
    final item = await _service.ajouterAuPanier(produitId, quantite);
    if (item == null) return false;

    final idx = _items.indexWhere((i) => i.produitId == produitId);
    if (idx >= 0) {
      _items[idx] = item;
    } else {
      _items.add(item);
    }
    _saveToCache();
    notifyListeners();
    return true;
  }

  // ── Retirer ────────────────────────────────────────────────────────────────

  Future<bool> retirer(int produitId) async {
    final ok = await _service.retirerDuPanier(produitId);
    if (ok) {
      _items.removeWhere((i) => i.produitId == produitId);
      _saveToCache();
      notifyListeners();
    }
    return ok;
  }

  // ── Modifier la quantité localement ───────────────────────────────────────

  Future<void> changerQuantite(int produitId, int nouvelleQuantite) async {
    if (nouvelleQuantite <= 0) {
      await retirer(produitId);
      return;
    }
    await ajouter(produitId, nouvelleQuantite);
  }

  // ── Vider ──────────────────────────────────────────────────────────────────

  Future<bool> vider() async {
    final ok = await _service.viderPanier();
    if (ok) {
      _items.clear();
      _clearCache();
      notifyListeners();
    }
    return ok;
  }

  // ── Persistance locale ────────────────────────────────────────────────────

  String get _cacheKey => 'panier_${serviceType.toLowerCase()}';

  Future<void> _saveToCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(_items.map((i) => i.toJson()).toList());
      await prefs.setString(_cacheKey, encoded);
    } catch (e) {
      debugPrint('PanierProvider: cache save failed: $e');
    }
  }

  Future<void> _loadFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_cacheKey);
      if (raw != null) {
        final list = jsonDecode(raw) as List;
        _items = list
            .map((i) => PanierItem.fromJson(i as Map<String, dynamic>))
            .toList();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('PanierProvider: cache load failed: $e');
    }
  }

  Future<void> _clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cacheKey);
    } catch (_) {}
  }
}
