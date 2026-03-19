import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../ui/app_brand.dart';

class AuthCallbackScreen extends StatefulWidget {
  const AuthCallbackScreen({super.key});

  @override
  State<AuthCallbackScreen> createState() => _AuthCallbackScreenState();
}

class _AuthCallbackScreenState extends State<AuthCallbackScreen> {
  String _status = "Validation en cours...";
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _run();
  }

  Future<void> _run() async {
    try {
      await Future.delayed(const Duration(milliseconds: 600));

      final user = Supabase.instance.client.auth.currentUser;
      final session = Supabase.instance.client.auth.currentSession;

      if (user != null && session != null) {
        setState(() {
          _status =
              "Votre compte est confirmé.\nVous pouvez maintenant vous connecter.";
          _done = true;
        });
      } else {
        setState(() {
          _status =
              "Lien traité.\nSi votre compte est confirmé, vous pouvez vous connecter.";
          _done = true;
        });
      }
    } catch (e) {
      setState(() {
        _status = "Erreur lors de la confirmation: $e";
        _done = true;
      });
    }
  }

  void _goLogin() {
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
  }

  @override
  Widget build(BuildContext context) {
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
                Text(
                  "Activation du compte",
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                Text(_status, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                if (_done)
                  ElevatedButton(
                    onPressed: _goLogin,
                    child: const Text("Aller à la connexion"),
                  ),
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
