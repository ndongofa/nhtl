import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../../services/auth_service.dart';
import '../../ui/app_brand.dart';
import '../../widgets/phone_input_field.dart';
import 'phone_otp_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({Key? key}) : super(key: key);

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _prenomController = TextEditingController();
  final _nomController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // ✅ Numéro E.164 retourné par PhoneInputField
  String? _phoneE164;

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  // Mode de signup : email ou téléphone
  bool _usePhone = false;

  @override
  void dispose() {
    _emailController.dispose();
    _prenomController.dispose();
    _nomController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  /// ✅ Modale de confirmation email
  Future<void> _showEmailConfirmationDialog(String email) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.mark_email_unread_outlined,
                  color: Colors.blue.shade600, size: 56),
            ),
            const SizedBox(height: 20),
            const Text(
              "Confirmez votre email",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              "Un email de confirmation a été envoyé à :\n\n"
              "$email\n\n"
              "Cliquez sur le lien dans l'email pour activer votre compte, "
              "puis revenez vous connecter.",
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Colors.black54),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.login),
                label: const Text("Aller à la connexion",
                    style: TextStyle(fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade600,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () => Navigator.of(ctx).pop(),
              ),
            ),
          ],
        ),
      ),
    );

    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
  }

  void _handleSignup() async {
    if (_isLoading) return;
    if (!_formKey.currentState!.validate()) return;

    // Vérification du numéro si mode téléphone
    if (_usePhone && (_phoneE164 == null || _phoneE164!.isEmpty)) {
      Fluttertoast.showToast(
        msg: "Veuillez entrer un numéro de téléphone valide.",
        backgroundColor: Colors.red,
        toastLength: Toast.LENGTH_LONG,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final identifier =
          _usePhone ? _phoneE164! : _emailController.text.trim().toLowerCase();

      final outcome = await AuthService.signupWithMetadata(
        identifier: identifier,
        password: _passwordController.text,
        prenom: _prenomController.text.trim(),
        nom: _nomController.text.trim(),
        role: 'user',
      );

      if (!mounted) return;

      // ✅ Cas téléphone : OTP déjà envoyé par Supabase lors du signUp
      if (_usePhone && outcome == SignupOutcome.confirmationRequired) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => PhoneOtpScreen(phoneE164: identifier),
          ),
        );
        return;
      }

      // ✅ Cas email : modale directement ici
      if (outcome == SignupOutcome.confirmationRequired) {
        await _showEmailConfirmationDialog(identifier);
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const SizedBox(height: 12),
              Text("Créer un compte",
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 4),
              Text(AppBrand.appName,
                  style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 20),

              // ✅ Toggle email / téléphone
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(
                    value: false,
                    label: Text('Email'),
                    icon: Icon(Icons.alternate_email),
                  ),
                  ButtonSegment(
                    value: true,
                    label: Text('Téléphone'),
                    icon: Icon(Icons.phone),
                  ),
                ],
                selected: {_usePhone},
                onSelectionChanged: (val) {
                  setState(() {
                    _usePhone = val.first;
                    _phoneE164 = null;
                  });
                },
              ),

              const SizedBox(height: 20),

              // ✅ Champ email OU PhoneInputField selon le mode
              if (!_usePhone)
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    hintText: 'ex: nom@domaine.com',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.alternate_email),
                  ),
                  validator: (v) {
                    final value = (v ?? '').trim();
                    if (value.isEmpty) return 'Email requis';
                    if (!value.contains('@') ||
                        !value.contains('.') ||
                        value.startsWith('@') ||
                        value.endsWith('@')) return 'Email invalide';
                    return null;
                  },
                )
              else
                PhoneInputField(
                  label: 'Téléphone',
                  initialCountryCode: 'SN',
                  onChanged: (e164) => setState(() => _phoneE164 = e164),
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
                    icon: Icon(_obscurePassword
                        ? Icons.visibility_off
                        : Icons.visibility),
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
                    icon: Icon(_obscureConfirm
                        ? Icons.visibility_off
                        : Icons.visibility),
                    onPressed: () =>
                        setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Confirmation requise';
                  if (v != _passwordController.text)
                    return 'Les mots de passe ne correspondent pas';
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
                      : const Text('S\'inscrire',
                          style: TextStyle(fontSize: 16)),
                ),
              ),
              TextButton(
                onPressed: () =>
                    Navigator.of(context).pushReplacementNamed('/login'),
                child: const Text('Déjà inscrit ? Se connecter'),
              ),
              const SizedBox(height: 8),
              Text("Support: ${AppBrand.supportEmail}",
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}
