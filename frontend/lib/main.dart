import 'package:flutter/material.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/auth/forgot_password_screen.dart';
import 'screens/auth/otp_verification_screen.dart';
import 'screens/auth/reset_password_screen.dart';
import 'screens/home_screen.dart';
import 'screens/admin/admin_page.dart'; // <-- import AdminPage
import 'services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Vérifier si l'utilisateur est connecté
  final isLoggedIn = await AuthService.isLoggedIn();

  runApp(MyApp(isLoggedIn: isLoggedIn));
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;

  const MyApp({
    Key? key,
    required this.isLoggedIn,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NHTL',
      theme: ThemeData(
        useMaterial3: true,
        primarySwatch: Colors.blue,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: Colors.blue,
          ),
        ),
      ),
      home: isLoggedIn ? const HomeScreen() : const LoginScreen(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignupScreen(),
        '/forgot-password': (context) => const ForgotPasswordScreen(),
        '/home': (context) => const HomeScreen(),
        '/admin': (context) => AdminPage(), // <-- nouvelle route
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/otp-verification') {
          final email = settings.arguments as String;
          return MaterialPageRoute(
            builder: (context) => OtpVerificationScreen(email: email),
          );
        } else if (settings.name == '/reset-password') {
          final args = settings.arguments as Map<String, String>;
          return MaterialPageRoute(
            builder: (context) => ResetPasswordScreen(
              email: args['email']!,
              otp: args['otp']!,
            ),
          );
        }
        return null;
      },
      debugShowCheckedModeBanner: false,
    );
  }
}
