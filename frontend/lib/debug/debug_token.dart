import 'package:supabase_flutter/supabase_flutter.dart';

void printSupabaseTokens() {
  final session = Supabase.instance.client.auth.currentSession;

  if (session == null) {
    print('No session (user not logged in).');
    return;
  }

  print('USER_ID: ${session.user.id}');
  print('ACCESS_TOKEN: ${session.accessToken}');
  print('REFRESH_TOKEN: ${session.refreshToken}');
  print('EXPIRES_AT: ${session.expiresAt}');
}
