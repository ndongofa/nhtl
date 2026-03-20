import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../../services/auth_service.dart';
import '../../ui/app_brand.dart';
import '../../widgets/phone_input_field.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // ✅ Numéro E.164 retourné par PhoneInputField
  String? _phoneE164;

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _usePhone = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

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

      await AuthService.login(identifier, _passwordController.text);

      if (mounted) {
        Fluttertoast.showToast(
          msg: 'Connexion réussie !',
          backgroundColor: Colors.green,
          toastLength: Toast.LENGTH_LONG,
        );
        Navigator.of(context).pushReplacementNamed('/home');
      }
    } catch (e) {
      if (mounted) {
        Fluttertoast.showToast(
          msg: e.toString().replaceFirst('Exception: ', ''),
          backgroundColor: Colors.red,
          toastLength: Toast.LENGTH_LONG,
        );
      }
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
              Text("Connexion", style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 6),
              Text("Sama Services International",
                  style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 28),

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
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleLogin,
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Se connecter'),
                ),
              ),
              TextButton(
                onPressed: () =>
                    Navigator.of(context).pushNamed('/forgot-password'),
                child: const Text('Mot de passe oublié ?'),
              ),
              TextButton(
                onPressed: () =>
                    Navigator.of(context).pushReplacementNamed('/signup'),
                child: const Text('Créer un compte'),
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
