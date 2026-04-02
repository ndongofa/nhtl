import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'providers/app_theme_provider.dart';
import 'screens/admin/admin_user_screen.dart';
import 'screens/auth/auth_callback_screen.dart';
import 'screens/auth/forgot_password_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/profile_screen.dart';
import 'screens/auth/reset_password_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/commande_hub_screen.dart';
import 'screens/landing_commande_screen.dart';
import 'screens/landing_transport_screen.dart';
import 'screens/services_hub_screen.dart';
import 'screens/transport_hub_screen.dart';
import 'services/departure_countdown_service.dart';
import 'ui/app_brand.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://ouswlpkxsszpxrfyvlde.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im91c3dscGt4c3N6cHhyZnl2bGRlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzEzMzYwMTEsImV4cCI6MjA4NjkxMjAxMX0.r43EKDGLX4iahz3cRliwBAQkV4Tgtsu80rTRGpSYP_w',
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppThemeProvider()),
        ChangeNotifierProvider(
          create: (_) => DepartureCountdownService()..start(),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final primary = Color(AppBrand.primaryColorValue);

    return MaterialApp(
      title: AppBrand.appName,
      theme: ThemeData(
        useMaterial3: true,
        primaryColor: primary,
        appBarTheme: AppBarTheme(
          backgroundColor: primary,
          foregroundColor: Colors.white,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(foregroundColor: primary),
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const ServicesHubScreen(),
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignupScreen(),
        '/forgot-password': (context) => const ForgotPasswordScreen(),
        '/admin': (context) => AdminUserScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/auth/callback': (context) => const AuthCallbackScreen(),
        '/reset-password': (context) => const ResetPasswordScreen(),
        '/transport': (context) => const LandingTransportScreen(),
        '/commande': (context) => const LandingCommandeScreen(),
        '/transport/hub': (context) => const TransportHubScreen(),
        '/commande/hub': (context) => const CommandeHubScreen(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}
