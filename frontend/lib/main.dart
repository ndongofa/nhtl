import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sama/screens/auth/profile_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'providers/app_theme_provider.dart';
import 'screens/admin/admin_user_screen.dart';
import 'screens/auth/auth_callback_screen.dart';
import 'screens/auth/forgot_password_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/reset_password_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/home_screen.dart';
import 'screens/landing_screen.dart';
import 'services/auth_service.dart';
import 'services/departure_countdown_service.dart';
import 'ui/app_brand.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://ouswlpkxsszpxrfyvlde.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im91c3dscGt4c3N6cHhyZnl2bGRlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzEzMzYwMTEsImV4cCI6MjA4NjkxMjAxMX0.r43EKDGLX4iahz3cRliwBAQkV4Tgtsu80rTRGpSYP_w',
  );

  final isLoggedIn = AuthService.isLoggedIn();

  runApp(
    MultiProvider(
      providers: [
        // ✅ Thème clair/sombre partagé sur toute l'app
        ChangeNotifierProvider(create: (_) => AppThemeProvider()),
        // ✅ Compte à rebours départs — partagé entre LandingScreen et HomeScreen
        //    start() lance le chargement API + le ticker 1s + le rechargement 5min
        ChangeNotifierProvider(
            create: (_) => DepartureCountdownService()..start()),
      ],
      child: MyApp(isLoggedIn: isLoggedIn),
    ),
  );
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;

  const MyApp({
    Key? key,
    required this.isLoggedIn,
  }) : super(key: key);

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
          style: TextButton.styleFrom(
            foregroundColor: primary,
          ),
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => isLoggedIn
            ? const HomeScreen()
            : LandingScreenSamaServicesInternational(),
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignupScreen(),
        '/forgot-password': (context) => const ForgotPasswordScreen(),
        '/home': (context) => const HomeScreen(),
        '/admin': (context) => AdminUserScreen(),
        '/profile': (context) => ProfileScreen(),
        '/auth/callback': (context) => const AuthCallbackScreen(),
        '/reset-password': (context) => const ResetPasswordScreen(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}
