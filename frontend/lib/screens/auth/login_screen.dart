import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  // Ancien _emailController -> devient "identifier" (email OU téléphone)
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;

  bool _looksLikeEmail(String v) => v.contains('@');
  bool _looksLikeE164Phone(String v) =>
      RegExp(r'^\+[1-9]\d{7,14}$').hasMatch(v);

  String? _validateIdentifier(String? v) {
    final value = (v ?? '').trim();
    if (value.isEmpty) return 'Email ou téléphone requis';

    if (_looksLikeEmail(value)) {
      // validation légère email
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

  String _normalizeIdentifier(String v) {
    final value = v.trim();
    if (_looksLikeEmail(value)) return value.toLowerCase();
    return value; // phone: garder tel quel
  }

  void _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final identifier = _normalizeIdentifier(_identifierController.text);

      await AuthService.login(
        identifier,
        _passwordController.text,
      );

      if (mounted) {
        Fluttertoast.showToast(
          msg: 'Connexion réussie!',
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
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Connexion')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const SizedBox(height: 40),
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
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Mot de passe',
                  border: const OutlineInputBorder(),
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
              ElevatedButton(
                onPressed: _isLoading ? null : _handleLogin,
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Se connecter'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pushNamed('/forgot-password');
                },
                child: const Text('Mot de passe oublié ?'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pushReplacementNamed('/signup');
                },
                child: const Text('Créer un compte'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
