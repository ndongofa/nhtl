import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../../services/auth_service.dart';
import '../../ui/app_brand.dart';
import 'signup_pending_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({Key? key}) : super(key: key);

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();

  final _identifierController = TextEditingController();
  final _prenomController = TextEditingController();
  final _nomController = TextEditingController();

  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  // Toggle: téléphone désactivé tant que SMS/OTP Supabase n'est pas configuré
  static const bool _phoneSignupEnabled = false;

  @override
  void dispose() {
    _identifierController.dispose();
    _prenomController.dispose();
    _nomController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  bool _looksLikeEmail(String v) => v.contains('@');
  bool _looksLikeE164Phone(String v) =>
      RegExp(r'^\+[1-9]\d{7,14}$').hasMatch(v);

  String? _validateIdentifier(String? v) {
    final value = (v ?? '').trim();
    if (value.isEmpty) return 'Email requis';

    // Email
    if (_looksLikeEmail(value)) {
      if (!value.contains('.') ||
          value.startsWith('@') ||
          value.endsWith('@')) {
        return 'Email invalide';
      }
      return null;
    }

    // Téléphone (E.164)
    if (_looksLikeE164Phone(value)) {
      if (!_phoneSignupEnabled) {
        return "Inscription par téléphone indisponible pour le moment. Utilisez un email.";
      }
      return null;
    }

    // Ni email ni téléphone valide
    return _phoneSignupEnabled
        ? 'Email ou téléphone invalide'
        : 'Email invalide';
  }

  void _handleSignup() async {
    if (!_formKey.currentState!.validate()) return;

    // Double garde-fou
    final identifier = _identifierController.text.trim();
    final isPhone =
        !_looksLikeEmail(identifier) && _looksLikeE164Phone(identifier);
    if (isPhone && !_phoneSignupEnabled) {
      Fluttertoast.showToast(
        msg: "Inscription par téléphone indisponible. Utilisez un email.",
        backgroundColor: Colors.orange,
        toastLength: Toast.LENGTH_LONG,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final outcome = await AuthService.signupWithMetadata(
        identifier: identifier,
        password: _passwordController.text,
        prenom: _prenomController.text.trim(),
        nom: _nomController.text.trim(),
        role: 'user',
      );

      if (!mounted) return;

      if (outcome == SignupOutcome.confirmationRequired) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => SignupPendingScreen(identifier: identifier),
          ),
        );
        return;
      }

      Fluttertoast.showToast(
        msg: "Inscription réussie. Votre compte est déjà actif.",
        backgroundColor: Colors.green,
        toastLength: Toast.LENGTH_LONG,
      );
      Navigator.of(context).pushReplacementNamed('/login');
    } catch (e) {
      if (!mounted) return;
      Fluttertoast.showToast(
        msg: e.toString().replaceFirst('Exception: ', ''),
        backgroundColor: Colors.red,
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppBrand.appName)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const SizedBox(height: 12),
              Text(
                "Créer un compte",
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 4),
              Text(
                "Sama Services International",
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _identifierController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  hintText: 'ex: nom@domaine.com',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.alternate_email),
                  helperText: _phoneSignupEnabled
                      ? 'Email ou téléphone (E.164)'
                      : 'Téléphone désactivé pour le moment',
                ),
                validator: _validateIdentifier,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _prenomController,
                decoration: const InputDecoration(
                  labelText: 'Prénom',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Prénom requis' : null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _nomController,
                decoration: const InputDecoration(
                  labelText: 'Nom',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.badge),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Nom requis' : null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Mot de passe',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                validator: (v) => (v == null || v.isEmpty)
                    ? 'Mot de passe requis'
                    : (v.length < 8 ? 'Minimum 8 caractères' : null),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: _obscureConfirm,
                decoration: InputDecoration(
                  labelText: 'Confirmer le mot de passe',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.lock_reset),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirm ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () =>
                        setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Confirmation requise';
                  if (v != _passwordController.text) {
                    return 'Les mots de passe ne correspondent pas';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleSignup,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'S\'inscrire',
                          style: TextStyle(fontSize: 16),
                        ),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pushReplacementNamed('/login');
                },
                child: const Text('Déjà inscrit ? Se connecter'),
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
    );
  }
}
