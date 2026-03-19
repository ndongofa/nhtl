import 'dart:async';

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
  bool _success = false;

  bool _obscure1 = true;
  bool _obscure2 = true;

  Timer? _redirectTimer;

  @override
  void dispose() {
    _redirectTimer?.cancel();
    _pw1.dispose();
    _pw2.dispose();
    super.dispose();
  }

  void _scheduleRedirectToLogin() {
    _redirectTimer?.cancel();
    _redirectTimer = Timer(const Duration(seconds: 2), () {
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
    });
  }

  Future<void> _submit() async {
    final p1 = _pw1.text.trim();
    final p2 = _pw2.text.trim();

    if (p1.length < 8) {
      setState(() {
        _success = false;
        _msg = "Mot de passe: 8 caractères minimum.";
      });
      return;
    }
    if (p1 != p2) {
      setState(() {
        _success = false;
        _msg = "Les mots de passe ne correspondent pas.";
      });
      return;
    }

    setState(() {
      _loading = true;
      _msg = null;
      _success = false;
    });

    try {
      final client = Supabase.instance.client;

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
        _success = true;
        _msg = "Mot de passe mis à jour.\nRedirection vers la connexion...";
      });

      _scheduleRedirectToLogin();
    } on AuthException catch (e) {
      // ignore: avoid_print
      print(
          "[ResetPasswordScreen] AuthException status=${e.statusCode} message=${e.message}");
      setState(() {
        _success = false;
        _msg = "Erreur: ${e.message}";
      });
    } catch (e) {
      // ignore: avoid_print
      print("[ResetPasswordScreen] Unknown error: $e");
      setState(() {
        _success = false;
        _msg = "Erreur: $e";
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bannerColor = _success ? Colors.green : Colors.red;

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
                if (_msg != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: bannerColor.withOpacity(0.12),
                      border: Border.all(color: bannerColor.withOpacity(0.35)),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      _msg!,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: bannerColor),
                    ),
                  ),
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
                  onPressed: _loading
                      ? null
                      : () => Navigator.of(context)
                          .pushNamedAndRemoveUntil('/login', (_) => false),
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
