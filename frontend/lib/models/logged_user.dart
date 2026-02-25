import 'package:supabase_flutter/supabase_flutter.dart';

class LoggedUser {
  final String userId;
  final String email;
  final String? username;
  final String? fullName;
  final String? phone;
  final String? jwt;
  final String? role;

  LoggedUser({
    required this.userId,
    required this.email,
    this.username,
    this.fullName,
    this.phone,
    this.jwt,
    this.role,
  });

  factory LoggedUser.fromSupabase() {
    final user = Supabase.instance.client.auth.currentUser;
    final session = Supabase.instance.client.auth.currentSession;
    return LoggedUser(
      userId: user?.id ?? '',
      email: user?.email ?? '',
      username: user?.userMetadata?['username'],
      fullName: user?.userMetadata?['full_name'],
      phone: user?.userMetadata?['phone'],
      jwt: session?.accessToken,
      role: user?.userMetadata?['role'],
    );
  }
}
