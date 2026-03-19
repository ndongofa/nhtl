import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Page appelée après clic sur le lien "Reset password" Supabase.
/// L'utilisateur saisit un nouveau mot de passe, puis on appelle updateUser().
class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _pw1 = TextEditingController();
  final _pw2 = TextEditingController();
  bool _loading = false;
  String? _msg;

  @override
  void dispose() {
    _pw1.dispose();
    _pw2.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final p1 = _pw1.text.trim();
    final p2 = _pw2.text.trim();

    if (p1.length < 8) {
      setState(() => _msg = "Mot de passe: 8 caractères minimum.");
      return;
    }
    if (p1 != p2) {
      setState(() => _msg = "Les mots de passe ne correspondent pas.");
      return;
    }

    setState(() {
      _loading = true;
      _msg = null;
    });

    try {
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: p1),
      );

      setState(() => _msg =
          "Mot de passe mis à jour. Vous pouvez maintenant vous connecter.");
    } on AuthException catch (e) {
      setState(() => _msg = "Erreur: ${e.message}");
    } catch (e) {
      setState(() => _msg = "Erreur: $e");
    } finally {
      setState(() => _loading = false);
    }
  }

  void _goLogin() {
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Réinitialiser le mot de passe")),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _pw1,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: "Nouveau mot de passe",
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _pw2,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: "Confirmer le mot de passe",
                  ),
                ),
                const SizedBox(height: 16),
                if (_msg != null) Text(_msg!, textAlign: TextAlign.center),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: _loading ? null : _submit,
                      child:
                          Text(_loading ? "Veuillez patienter..." : "Valider"),
                    ),
                    const SizedBox(width: 12),
                    TextButton(
                      onPressed: _loading ? null : _goLogin,
                      child: const Text("Connexion"),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
