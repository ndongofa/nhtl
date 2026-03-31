// lib/services/postal_tracking_service.dart
//
// ✅ savePostalTransport / savePostalCommande retournent Map<String,dynamic>?
//    avec les données confirmées par le backend (deposePosteAt, statutSuivi…)
//    → les écrans utilisent ces données directement, sans cache local ni second GET

import 'dart:convert';
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

  Future<XFile?> pickImage({bool fromCamera = false}) async {
    return _picker.pickImage(
      source: fromCamera ? ImageSource.camera : ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1920,
    );
  }

  Future<String?> uploadPhoto({
    required XFile file,
    required String folder,
    required int entityId,
    required String label,
  }) async {
    try {
      final bytes = await file.readAsBytes();
      final ext = _resolveExtension(file);
      final path = '$folder/$entityId/${label}_'
          '${DateTime.now().millisecondsSinceEpoch}.$ext';

      await _supa.storage.from(_bucket).uploadBinary(
            path,
            bytes,
            fileOptions: FileOptions(contentType: 'image/$ext', upsert: true),
          );

      final url = _supa.storage.from(_bucket).getPublicUrl(path);
      _log.i('✅ Photo uploadée : $url');
      return url;
    } catch (e, st) {
      _log.e('❌ Upload photo $label : $e', error: e, stackTrace: st);
      return null;
    }
  }

  String _resolveExtension(XFile file) {
    final name = file.name;
    if (name.contains('.')) {
      final ext = name.split('.').last.toLowerCase();
      if (['jpg', 'jpeg', 'png', 'webp', 'heic'].contains(ext))
        return ext == 'jpeg' ? 'jpg' : ext;
    }
    final mime = file.mimeType ?? '';
    if (mime.contains('jpeg') || mime.contains('jpg')) return 'jpg';
    if (mime.contains('png')) return 'png';
    if (mime.contains('webp')) return 'webp';
    return 'jpg';
  }

  // ── Dépôt postal Transport ────────────────────────────────────────────────
  // Retourne le JSON du backend : { success, id, statutSuivi, deposePosteAt… }
  // null si erreur

  Future<Map<String, dynamic>?> savePostalTransport({
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

  // ── Dépôt postal Commande ─────────────────────────────────────────────────

  Future<Map<String, dynamic>?> savePostalCommande({
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

  // ── Helper ────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>?> _patch(
      String endpoint, Map<String, String> body) async {
    try {
      final jwt = await AuthService.getJwt();
      if (jwt == null) {
        _log.e('❌ JWT absent');
        return null;
      }

      final response = await http
          .patch(
            Uri.parse('${ApiConfig.baseUrl}$endpoint'),
            headers: {
              'Authorization': 'Bearer $jwt',
              'Content-Type': 'application/json'
            },
            body: jsonEncode(body),
          )
          .timeout(ApiConfig.connectTimeout);

      if (response.statusCode == 200) {
        _log.i('✅ Postal PATCH $endpoint OK');
        final decoded = jsonDecode(response.body);
        return decoded is Map<String, dynamic> ? decoded : {'success': true};
      }
      _log.e('❌ Postal PATCH ${response.statusCode} — ${response.body}');
      return null;
    } catch (e, st) {
      _log.e('❌ Exception postal PATCH : $e', error: e, stackTrace: st);
      return null;
    }
  }
}
