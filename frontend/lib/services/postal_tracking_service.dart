// lib/services/postal_tracking_service.dart
//
// Upload photos vers Supabase Storage (bucket: sama-postal)
// puis PATCH /api/admin/transports/{id}/postal ou commandes/{id}/postal

import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:logger/logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sama/config/api_config.dart';
import 'dart:convert';
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

  Future<String?> uploadPhoto({
    required XFile file,
    required String folder, // 'transports' ou 'commandes'
    required int entityId,
    required String label, // 'colis' ou 'bordereau'
  }) async {
    try {
      final ext = file.path.split('.').last.toLowerCase();
      final path =
          '$folder/$entityId/${label}_${DateTime.now().millisecondsSinceEpoch}.$ext';

      if (kIsWeb) {
        final bytes = await file.readAsBytes();
        await _supa.storage.from(_bucket).uploadBinary(
              path,
              bytes,
              fileOptions: FileOptions(contentType: 'image/$ext', upsert: true),
            );
      } else {
        await _supa.storage.from(_bucket).upload(
              path,
              File(file.path),
              fileOptions: FileOptions(contentType: 'image/$ext', upsert: true),
            );
      }

      final url = _supa.storage.from(_bucket).getPublicUrl(path);
      _log.i('✅ Photo uploadée : $url');
      return url;
    } catch (e) {
      _log.e('❌ Upload photo $label : $e');
      return null;
    }
  }

  // ── Enregistrer le dépôt postal (transport) ───────────────────────────────

  Future<bool> savePostalTransport({
    required int id,
    required String photoColisUrl,
    required String photoBordereauUrl,
    required String numeroBordereau,
  }) async {
    return _patch(
      '/api/admin/transports/$id/postal',
      {
        'photoColisUrl': photoColisUrl,
        'photoBordereauUrl': photoBordereauUrl,
        'numeroBordereau': numeroBordereau,
      },
    );
  }

  // ── Enregistrer le dépôt postal (commande) ────────────────────────────────

  Future<bool> savePostalCommande({
    required int id,
    required String photoColisUrl,
    required String photoBordereauUrl,
    required String numeroBordereau,
  }) async {
    return _patch(
      '/api/admin/commandes/$id/postal',
      {
        'photoColisUrl': photoColisUrl,
        'photoBordereauUrl': photoBordereauUrl,
        'numeroBordereau': numeroBordereau,
      },
    );
  }

  // ── Helper PATCH ──────────────────────────────────────────────────────────

  Future<bool> _patch(String endpoint, Map<String, String> body) async {
    try {
      final jwt = await AuthService.getJwt();
      if (jwt == null) return false;

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
          '❌ Postal PATCH $endpoint : ${response.statusCode} ${response.body}');
      return false;
    } catch (e) {
      _log.e('❌ Exception postal PATCH $endpoint : $e');
      return false;
    }
  }
}
