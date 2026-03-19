import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../ui/app_brand.dart';

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

  bool _obscure1 = true;
  bool _obscure2 = true;

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
      final client = Supabase.instance.client;

      // Debug utile si updateUser ne marche pas (session recovery absente)
      // ignore: avoid_print
      print(
          "[ResetPasswordScreen] sessionPresent=${client.auth.currentSession != null} "
          "userPresent=${client.auth.currentUser != null}");

      final res = await client.auth.updateUser(
        UserAttributes(password: p1),
      );

      // ignore: avoid_print
      print("[ResetPasswordScreen] updateUser OK userId=${res.user?.id}");

      setState(() {
        _msg =
            "Mot de passe mis à jour.\nVous pouvez maintenant vous connecter.";
      });
    } on AuthException catch (e) {
      // ignore: avoid_print
      print(
          "[ResetPasswordScreen] AuthException status=${e.statusCode} message=${e.message}");
      setState(() => _msg = "Erreur: ${e.message}");
    } catch (e) {
      // ignore: avoid_print
      print("[ResetPasswordScreen] Unknown error: $e");
      setState(() => _msg = "Erreur: $e");
    } finally {
      if (mounted) setState(() => _loading = false);
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
                  "Réinitialiser le mot de passe",
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _pw1,
                  obscureText: _obscure1,
                  decoration: InputDecoration(
                    labelText: "Nouveau mot de passe",
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      onPressed: () => setState(() => _obscure1 = !_obscure1),
                      icon: Icon(
                        _obscure1 ? Icons.visibility_off : Icons.visibility,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _pw2,
                  obscureText: _obscure2,
                  decoration: InputDecoration(
                    labelText: "Confirmer le mot de passe",
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      onPressed: () => setState(() => _obscure2 = !_obscure2),
                      icon: Icon(
                        _obscure2 ? Icons.visibility_off : Icons.visibility,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                if (_msg != null) Text(_msg!, textAlign: TextAlign.center),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _submit,
                    child: _loading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text("Valider"),
                  ),
                ),
                TextButton(
                  onPressed: _loading ? null : _goLogin,
                  child: const Text("Connexion"),
                ),
                const SizedBox(height: 8),
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
