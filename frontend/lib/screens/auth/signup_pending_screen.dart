import 'package:flutter/material.dart';
import '../../ui/app_brand.dart';
import 'phone_otp_screen.dart';

class SignupPendingScreen extends StatelessWidget {
  final String identifier; // email ou téléphone (E.164)

  const SignupPendingScreen({
    super.key,
    required this.identifier,
  });

  bool get _isEmail => identifier.contains('@');

  bool get _isPhone =>
      !_isEmail && RegExp(r'^\+[1-9]\d{7,14}$').hasMatch(identifier.trim());

  @override
  Widget build(BuildContext context) {
    final title = "Inscription prise en charge";

    final message = _isEmail
        ? "Nous avons envoyé un email de confirmation à :\n\n$identifier\n\n"
            "Cliquez sur le lien dans l’email pour activer votre compte.\n\n"
            "Ensuite, revenez ici pour vous connecter."
        : "Nous avons envoyé un code de validation par SMS au :\n\n$identifier\n\n"
            "Entrez ce code pour activer votre compte.";

    return Scaffold(
      appBar: AppBar(title: Text(AppBrand.appName)),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),
                Text(message, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context)
                        .pushNamedAndRemoveUntil('/login', (_) => false),
                    child: const Text("Aller à la connexion"),
                  ),
                ),
                if (_isPhone) ...[
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                PhoneOtpScreen(phoneE164: identifier.trim()),
                          ),
                        );
                      },
                      child: const Text("Saisir le code SMS"),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Text(
                  "Besoin d'aide ? ${AppBrand.supportEmail}",
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
