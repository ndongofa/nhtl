import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Page de réception des redirections Supabase (confirmation email, magic link, etc.)
/// Objectif: éviter une page blanche et donner un feedback clair à l’utilisateur.
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
      // Laisse le temps au SDK de traiter l’URL (surtout sur Flutter Web)
      await Future.delayed(const Duration(milliseconds: 600));

      final user = Supabase.instance.client.auth.currentUser;
      final session = Supabase.instance.client.auth.currentSession;

      // Selon config Supabase, la confirmation peut créer une session ou non.
      if (user != null && session != null) {
        setState(() {
          _status = "Email confirmé. Votre compte est maintenant actif.";
          _done = true;
        });
      } else {
        setState(() {
          _status =
              "Lien traité. Si votre email est confirmé, vous pouvez vous connecter.";
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
      appBar: AppBar(title: const Text("Confirmation")),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_status, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                if (_done)
                  ElevatedButton(
                    onPressed: _goLogin,
                    child: const Text("Aller à la connexion"),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
