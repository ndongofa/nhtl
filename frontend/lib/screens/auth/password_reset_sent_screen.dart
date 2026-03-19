import 'package:flutter/material.dart';
import '../../ui/app_brand.dart';

class PasswordResetSentScreen extends StatelessWidget {
  final String identifier; // email ou téléphone

  const PasswordResetSentScreen({
    super.key,
    required this.identifier,
  });

  bool get _isEmail => identifier.contains('@');

  @override
  Widget build(BuildContext context) {
    final title = "Demande envoyée";

    final message = _isEmail
        ? "Si un compte existe avec l’adresse :\n\n$identifier\n\n"
            "Vous allez recevoir un lien pour réinitialiser votre mot de passe.\n\n"
            "Pensez à vérifier votre boîte spam."
        : "Si un compte existe avec le numéro :\n\n$identifier\n\n"
            "Vous allez recevoir un message avec les instructions de réinitialisation.";

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
                ElevatedButton(
                  onPressed: () => Navigator.of(context)
                      .pushNamedAndRemoveUntil('/login', (_) => false),
                  child: const Text("Retour à la connexion"),
                ),
                const SizedBox(height: 12),
                Text(
                  "Support: ${AppBrand.supportEmail}",
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
