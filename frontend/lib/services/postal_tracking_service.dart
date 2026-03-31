// lib/services/postal_tracking_service.dart
//
// Upload photos vers Supabase Storage (bucket: sama-postal)
// puis PATCH /api/admin/transports/{id}/postal ou commandes/{id}/postal
//
// ✅ Correction Flutter Web :
//    - Sur Web, file.path est une blob URL → on ne peut pas extraire l'extension
//    - On utilise toujours readAsBytes() + content-type fixe image/jpeg
//    - uploadBinary() utilisé systématiquement (fonctionne web et mobile)

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:logger/logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/api_config.dart';
import 'auth_service.dart';

class PostalTrackingService {
  final _log = Logger();
  final _supa = Supabase.instance.client;
  final _picker = ImagePicker();

  static const _bucket = 'sama-postal';

  // ── Sélection d'image ─────────────────────────────────────────────────────

  Future<XFile?> pickImage({bool fromCamera = false}) async {
    return _picker.pickImage(
      source: fromCamera ? ImageSource.camera : ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1920,
    );
  }

  // ── Upload vers Supabase Storage ──────────────────────────────────────────
  //
  // ✅ Toujours readAsBytes() — fonctionne sur Web ET mobile
  // ✅ Content-type fixé à image/jpeg — évite le problème de blob URL sur Web
  // ✅ Extension fixée à .jpg — idem

  Future<String?> uploadPhoto({
    required XFile file,
    required String folder, // 'transports' ou 'commandes'
    required int entityId,
    required String label, // 'colis' ou 'bordereau'
  }) async {
    try {
      // Lire les bytes — fonctionne sur Web (blob URL) et mobile (vrai chemin)
      final bytes = await file.readAsBytes();

      // ✅ Extension : tenter de l'extraire du mimeType ou du nom,
      //    sinon fallback jpg (safe sur Web où path = blob:...)
      final ext = _resolveExtension(file);
      final path = '$folder/$entityId/${label}_'
          '${DateTime.now().millisecondsSinceEpoch}.$ext';

      await _supa.storage.from(_bucket).uploadBinary(
            path,
            bytes,
            fileOptions: FileOptions(
              contentType: 'image/$ext',
              upsert: true,
            ),
          );

      final url = _supa.storage.from(_bucket).getPublicUrl(path);
      _log.i('✅ Photo uploadée : $url');
      return url;
    } catch (e, st) {
      _log.e('❌ Upload photo $label : $e', error: e, stackTrace: st);
      return null;
    }
  }

  // ── Résolution de l'extension ─────────────────────────────────────────────
  //
  // Sur Flutter Web, file.path = "blob:https://..." → split('.').last inutilisable
  // On essaie dans l'ordre :
  //   1. Extension du nom du fichier (file.name contient souvent "photo.jpg")
  //   2. MimeType (image/jpeg → jpeg → jpg)
  //   3. Fallback : jpg

  String _resolveExtension(XFile file) {
    // 1. Depuis le nom
    final name = file.name;
    if (name.contains('.')) {
      final ext = name.split('.').last.toLowerCase();
      if (['jpg', 'jpeg', 'png', 'webp', 'heic'].contains(ext)) {
        return ext == 'jpeg' ? 'jpg' : ext;
      }
    }
    // 2. Depuis le mimeType
    final mime = file.mimeType ?? '';
    if (mime.contains('jpeg') || mime.contains('jpg')) return 'jpg';
    if (mime.contains('png')) return 'png';
    if (mime.contains('webp')) return 'webp';
    // 3. Fallback
    return 'jpg';
  }

  // ── Enregistrer le dépôt postal — Transport ───────────────────────────────

  Future<bool> savePostalTransport({
    required int id,
    required String photoColisUrl,
    required String photoBordereauUrl,
    required String numeroBordereau,
  }) =>
      _patch('/api/admin/transports/$id/postal', {
        'photoColisUrl': photoColisUrl,
        'photoBordereauUrl': photoBordereauUrl,
        'numeroBordereau': numeroBordereau,
      });

  // ── Enregistrer le dépôt postal — Commande ────────────────────────────────

  Future<bool> savePostalCommande({
    required int id,
    required String photoColisUrl,
    required String photoBordereauUrl,
    required String numeroBordereau,
  }) =>
      _patch('/api/admin/commandes/$id/postal', {
        'photoColisUrl': photoColisUrl,
        'photoBordereauUrl': photoBordereauUrl,
        'numeroBordereau': numeroBordereau,
      });

  // ── Helper PATCH ──────────────────────────────────────────────────────────

  Future<bool> _patch(String endpoint, Map<String, String> body) async {
    try {
      final jwt = await AuthService.getJwt();
      if (jwt == null) {
        _log.e('❌ JWT absent — impossible d\'appeler $endpoint');
        return false;
      }

      final response = await http
          .patch(
            Uri.parse('${ApiConfig.baseUrl}$endpoint'),
            headers: {
              'Authorization': 'Bearer $jwt',
              'Content-Type': 'application/json',
            },
            body: jsonEncode(body),
          )
          .timeout(ApiConfig.connectTimeout);

      if (response.statusCode == 200) {
        _log.i('✅ Postal PATCH $endpoint OK');
        return true;
      }
      _log.e(
          '❌ Postal PATCH $endpoint : ${response.statusCode} — ${response.body}');
      return false;
    } catch (e, st) {
      _log.e('❌ Exception postal PATCH $endpoint : $e',
          error: e, stackTrace: st);
      return false;
    }
  }
}
