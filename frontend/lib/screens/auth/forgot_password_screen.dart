import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../../services/auth_service.dart';
import '../../ui/app_brand.dart';
import 'password_reset_sent_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({Key? key}) : super(key: key);

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();
  bool _isLoading = false;

  bool _looksLikeEmail(String v) => v.contains('@');
  bool _looksLikeE164Phone(String v) =>
      RegExp(r'^\+[1-9]\d{7,14}$').hasMatch(v);

  String? _validateIdentifier(String? v) {
    final value = (v ?? '').trim();
    if (value.isEmpty) return 'Email ou téléphone requis';

    if (_looksLikeEmail(value)) {
      if (!value.contains('.') ||
          value.startsWith('@') ||
          value.endsWith('@')) {
        return 'Email invalide';
      }
      return null;
    }

    if (_looksLikeE164Phone(value)) {
      return null;
    }

    return 'Email ou téléphone invalide (téléphone au format +221...)';
  }

  @override
  void dispose() {
    _identifierController.dispose();
    super.dispose();
  }

  Future<void> _handleResetPassword() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final identifier = _identifierController.text.trim();
    final isEmail = _looksLikeEmail(identifier);
    final isPhone = !isEmail && _looksLikeE164Phone(identifier);

    try {
      if (isEmail) {
        await AuthService.resetPasswordForEmail(identifier);
      } else if (isPhone) {
        // Pour l’instant on informe l’utilisateur (le flux SMS/OTP sera ajouté au step OTP)
        // IMPORTANT: ne pas casser le flow email existant.
        Fluttertoast.showToast(
          msg:
              "Réinitialisation par téléphone: vous recevrez un SMS (en cours d’activation).",
          backgroundColor: Colors.orange,
          toastLength: Toast.LENGTH_LONG,
        );
      }

      if (!mounted) return;

      // UX: écran clair sur la suite (email OU téléphone)
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => PasswordResetSentScreen(identifier: identifier),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Fluttertoast.showToast(
        msg: e.toString().replaceFirst('Exception: ', ''),
        backgroundColor: Colors.red,
        toastLength: Toast.LENGTH_LONG,
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppBrand.appName)),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const SizedBox(height: 28),
              Text(
                "Mot de passe oublié",
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              const Text(
                "Entrez votre email ou votre numéro de téléphone.\n"
                "Si un compte existe, vous recevrez un lien (email) ou un message (SMS) pour réinitialiser votre mot de passe.",
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _identifierController,
                decoration: const InputDecoration(
                  labelText: 'Email ou téléphone',
                  hintText: 'ex: nom@domaine.com ou +221783042838',
                  border: OutlineInputBorder(),
                ),
                validator: _validateIdentifier,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleResetPassword,
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Continuer'),
                ),
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
    );
  }
}
