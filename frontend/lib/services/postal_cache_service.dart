// lib/services/postal_cache_service.dart
//
// Cache local des dépôts postaux par ID transport/commande
// Persisté dans SharedPreferences — survit aux rechargements
// Utilisé en complément du backend pour garantir l'affichage
// même si le GET API ne retourne pas encore les champs postaux

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class PostalCacheService {
  static const _keyPrefix = 'postal_cache_';

  // ── Sauvegarder les infos postales localement ──────────────────────────────

  static Future<void> saveTransport({
    required int id,
    required String photoColisUrl,
    required String photoBordereauUrl,
    required String numeroBordereau,
    required DateTime deposePosteAt,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        '${_keyPrefix}transport_$id',
        jsonEncode({
          'photoColisUrl': photoColisUrl,
          'photoBordereauUrl': photoBordereauUrl,
          'numeroBordereau': numeroBordereau,
          'deposePosteAt': deposePosteAt.toIso8601String(),
        }));
  }

  static Future<void> saveCommande({
    required int id,
    required String photoColisUrl,
    required String photoBordereauUrl,
    required String numeroBordereau,
    required DateTime deposePosteAt,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        '${_keyPrefix}commande_$id',
        jsonEncode({
          'photoColisUrl': photoColisUrl,
          'photoBordereauUrl': photoBordereauUrl,
          'numeroBordereau': numeroBordereau,
          'deposePosteAt': deposePosteAt.toIso8601String(),
        }));
  }

  // ── Lire le cache ──────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>?> getTransport(int id) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('${_keyPrefix}transport_$id');
    if (raw == null) return null;
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>?> getCommande(int id) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('${_keyPrefix}commande_$id');
    if (raw == null) return null;
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  // ── Supprimer le cache (si besoin de reset) ────────────────────────────────

  static Future<void> clearTransport(int id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('${_keyPrefix}transport_$id');
  }

  static Future<void> clearCommande(int id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('${_keyPrefix}commande_$id');
  }
}
