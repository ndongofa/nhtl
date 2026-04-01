// lib/screens/auth/login_screen.dart

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:sama/screens/auth/signup_screen.dart';
import '../../services/auth_service.dart';
import '../../ui/app_brand.dart';
import '../../widgets/phone_input_field.dart';

class LoginScreen extends StatefulWidget {
  /// Si fourni, redirige vers ce widget après connexion réussie
  /// au lieu de '/home'. Utilisé par les landings Transport/Commande.
  final Widget? redirectTo;

  const LoginScreen({Key? key, this.redirectTo}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  String? _phoneE164;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _usePhone = true;

  static const Color _appBlue = Color(0xFF2296F3);
  static const Color _bgLight = Color(0xFFF4F8FF);
  static const Color _textMain = Color(0xFF0F2040);
  static const Color _textMuted = Color(0xFF6B7A99);
  static const Color _borderColor = Color(0xFFDDE3EF);

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

        // ✅ Si un redirectTo est fourni (depuis une landing spécifique),
        //    on remplace la stack par ce widget.
        //    Sinon comportement par défaut → /home.
        if (widget.redirectTo != null) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => widget.redirectTo!),
            (route) => false,
          );
        } else {
          Navigator.of(context).pushReplacementNamed('/home');
        }
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
      backgroundColor: _bgLight,
      appBar: AppBar(
        backgroundColor: _appBlue,
        elevation: 0,
        title: Text(AppBrand.appName,
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.3)),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                      color: _appBlue.withValues(alpha: 0.07),
                      blurRadius: 32,
                      offset: const Offset(0, 8))
                ],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                            color: _appBlue.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(12)),
                        child:
                            const Icon(Icons.login, color: _appBlue, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Connexion",
                                style: TextStyle(
                                    color: _textMain,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 18)),
                            Text(AppBrand.appName,
                                style: const TextStyle(
                                    color: _textMuted,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 12)),
                          ]),
                    ]),

                    // ✅ Bandeau contextuel si redirection spécifique
                    if (widget.redirectTo != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                            color: _appBlue.withValues(alpha: 0.07),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: _appBlue.withValues(alpha: 0.20))),
                        child: Row(children: [
                          const Icon(Icons.info_outline,
                              color: _appBlue, size: 16),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              "Connectez-vous pour accéder à votre espace.",
                              style: TextStyle(
                                  color: _appBlue,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                        ]),
                      ),
                    ],

                    const SizedBox(height: 24),

                    // Toggle téléphone / email
                    Container(
                      decoration: BoxDecoration(
                        color: _bgLight,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _borderColor),
                      ),
                      child: Row(children: [
                        _toggleTab("Téléphone", Icons.phone, true, _appBlue),
                        _toggleTab(
                            "Email", Icons.alternate_email, false, _appBlue),
                      ]),
                    ),
                    const SizedBox(height: 20),

                    if (_usePhone)
                      PhoneInputField(
                        label: 'Téléphone',
                        initialCountryCode: 'SN',
                        onChanged: (e164) => setState(() => _phoneE164 = e164),
                      )
                    else
                      _inputField(
                        controller: _emailController,
                        label: 'Email',
                        icon: Icons.alternate_email,
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) {
                          final value = (v ?? '').trim();
                          if (value.isEmpty) return 'Email requis';
                          if (!value.contains('@') ||
                              !value.contains('.') ||
                              value.startsWith('@') ||
                              value.endsWith('@')) return 'Email invalide';
                          return null;
                        },
                      ),

                    const SizedBox(height: 14),

                    _inputField(
                      controller: _passwordController,
                      label: 'Mot de passe',
                      icon: Icons.lock_outline,
                      obscure: _obscurePassword,
                      toggleObscure: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                      validator: (v) => (v == null || v.isEmpty)
                          ? 'Mot de passe requis'
                          : v.length < 8
                              ? 'Minimum 8 caractères'
                              : null,
                    ),

                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () =>
                            Navigator.of(context).pushNamed('/forgot-password'),
                        style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                        child: const Text("Mot de passe oublié ?",
                            style: TextStyle(
                                color: _appBlue,
                                fontWeight: FontWeight.w600,
                                fontSize: 13)),
                      ),
                    ),

                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _appBlue,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2))
                            : const Text("Se connecter",
                                style: TextStyle(
                                    fontWeight: FontWeight.w800, fontSize: 15)),
                      ),
                    ),

                    const SizedBox(height: 16),

                    Center(
                      child: TextButton(
                        // ✅ Transmet redirectTo au signup pour conserver le contexte
                        onPressed: () => Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (_) => SignupScreenWithRedirect(
                                redirectTo: widget.redirectTo),
                          ),
                        ),
                        child: const Text(
                            "Pas encore inscrit ? Créer un compte",
                            style: TextStyle(
                                color: _appBlue,
                                fontWeight: FontWeight.w600,
                                fontSize: 13)),
                      ),
                    ),

                    const SizedBox(height: 8),
                    Center(
                      child: Text("Support : ${AppBrand.supportEmail}",
                          style:
                              const TextStyle(color: _textMuted, fontSize: 11)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _toggleTab(String label, IconData icon, bool isPhone, Color appBlue) {
    final isSelected = _usePhone == isPhone;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() {
          _usePhone = isPhone;
          _phoneE164 = null;
        }),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.all(4),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? appBlue : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon,
                size: 15,
                color: isSelected ? Colors.white : const Color(0xFF6B7A99)),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                    color: isSelected ? Colors.white : const Color(0xFF6B7A99),
                    fontWeight: FontWeight.w700,
                    fontSize: 13)),
          ]),
        ),
      ),
    );
  }

  Widget _inputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool obscure = false,
    VoidCallback? toggleObscure,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      style: const TextStyle(
          color: Color(0xFF0F2040), fontWeight: FontWeight.w500, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
            color: Color(0xFF6B7A99),
            fontWeight: FontWeight.w500,
            fontSize: 14),
        prefixIcon: Icon(icon, color: const Color(0xFF2296F3), size: 18),
        suffixIcon: toggleObscure != null
            ? IconButton(
                icon: Icon(obscure ? Icons.visibility_off : Icons.visibility,
                    color: const Color(0xFF6B7A99), size: 18),
                onPressed: toggleObscure)
            : null,
        filled: true,
        fillColor: const Color(0xFFF4F8FF),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFDDE3EF))),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFDDE3EF))),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF2296F3), width: 1.8)),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.red)),
      ),
      validator: validator,
    );
  }
}

/// Alias pour passer redirectTo depuis login → signup
/// sans modifier le constructeur de SignupScreen existant
class SignupScreenWithRedirect extends SignupScreen {
  const SignupScreenWithRedirect({Key? key, Widget? redirectTo})
      : super(key: key, redirectTo: redirectTo);
}
