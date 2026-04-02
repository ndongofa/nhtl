import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user.dart' as appUser;
import 'package:logger/logger.dart';

/// UserService = lecture du profil applicatif depuis `public.utilisateurs`.
/// IMPORTANT: Les opérations admin (create/update/delete/reset password) doivent
/// passer par le backend Spring (AdminUserApiService), qui modifie `auth.users`,
/// puis les triggers synchronisent `public.utilisateurs`.
class UserService {
  final Logger logger = Logger();
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Liste des utilisateurs (table custom Supabase)
  Future<List<appUser.User>?> getUsers() async {
    try {
      final res = await _supabase.from('utilisateurs').select();
      final list = res as List<dynamic>;
      return list.map((u) => appUser.User.fromJson(u)).toList();
    } catch (e) {
      logger.e('Erreur getUsers : $e');
      return null;
    }
  }
}
