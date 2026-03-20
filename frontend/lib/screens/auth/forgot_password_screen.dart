import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../../services/auth_service.dart';
import '../../ui/app_brand.dart';
import '../../widgets/phone_input_field.dart';
import 'password_reset_sent_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({Key? key}) : super(key: key);

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  // ✅ Numéro E.164 retourné par PhoneInputField
  String? _phoneE164;

  bool _isLoading = false;
  bool _usePhone = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleResetPassword() async {
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

    final identifier =
        _usePhone ? _phoneE164! : _emailController.text.trim().toLowerCase();

    try {
      if (!_usePhone) {
        await AuthService.resetPasswordForEmail(identifier);
      } else {
        // Flux SMS/OTP reset (en cours d'activation)
        Fluttertoast.showToast(
          msg:
              "Réinitialisation par téléphone: vous recevrez un SMS (en cours d'activation).",
          backgroundColor: Colors.orange,
          toastLength: Toast.LENGTH_LONG,
        );
      }

      if (!mounted) return;

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
              Text("Mot de passe oublié",
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              const Text(
                "Entrez votre email ou votre numéro de téléphone.\n"
                "Si un compte existe, vous recevrez un lien (email) ou un message (SMS) "
                "pour réinitialiser votre mot de passe.",
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

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
              Text("Support: ${AppBrand.supportEmail}",
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}
