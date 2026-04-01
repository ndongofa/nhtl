import 'dart:async';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../../services/auth_service.dart';
import '../../ui/app_brand.dart';

class PhoneOtpScreen extends StatefulWidget {
  final String phoneE164;
  final Widget? redirectTo;

  const PhoneOtpScreen({
    Key? key,
    required this.phoneE164,
    this.redirectTo,
  }) : super(key: key);

  @override
  State<PhoneOtpScreen> createState() => _PhoneOtpScreenState();
}

class _PhoneOtpScreenState extends State<PhoneOtpScreen> {
  final _codeController = TextEditingController();
  bool _loading = false;
  String? _errorMsg;

  // ✅ Cooldown — démarre dès l'arrivée sur l'écran car Supabase
  // a déjà envoyé un OTP lors du signUp.
  static const int _resendCooldownSeconds = 60;
  int _resendCountdown = _resendCooldownSeconds;
  Timer? _resendTimer;

  @override
  void initState() {
    super.initState();
    _startResendCooldown();
  }

  @override
  void dispose() {
    _codeController.dispose();
    _resendTimer?.cancel();
    super.dispose();
  }

  void _startResendCooldown() {
    _resendTimer?.cancel();
    setState(() => _resendCountdown = _resendCooldownSeconds);
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_resendCountdown > 0) {
          _resendCountdown--;
        } else {
          timer.cancel();
        }
      });
    });
  }

  Future<void> _verify() async {
    final code = _codeController.text.trim();

    if (code.isEmpty) {
      setState(() => _errorMsg = "Veuillez entrer le code reçu par SMS.");
      return;
    }

    setState(() {
      _loading = true;
      _errorMsg = null;
    });

    try {
      await AuthService.verifyPhoneOtp(
        phoneE164: widget.phoneE164,
        token: code,
      );

      if (!mounted) return;

      // ✅ Modale de succès — bloque jusqu'à confirmation de l'utilisateur
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle_outline,
                  color: Colors.green.shade600,
                  size: 56,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                "Compte activé !",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                "Votre numéro ${widget.phoneE164} a bien été confirmé.\n"
                "Vous pouvez maintenant vous connecter.",
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: Colors.black54),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.login),
                  label: const Text(
                    "Se connecter",
                    style: TextStyle(fontSize: 16),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(ctx).pop();
                  },
                ),
              ),
            ],
          ),
        ),
      );

      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMsg = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resend() async {
    if (_resendCountdown > 0 || _loading) return;

    setState(() {
      _loading = true;
      _errorMsg = null;
    });

    try {
      await AuthService.sendPhoneOtp(widget.phoneE164);
      if (!mounted) return;
      _startResendCooldown();
      Fluttertoast.showToast(
        msg: "Code renvoyé par SMS.",
        backgroundColor: Colors.green,
        toastLength: Toast.LENGTH_SHORT,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMsg = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final canResend = _resendCountdown == 0 && !_loading;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(AppBrand.appName)),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Icon(Icons.sms_outlined, size: 48, color: Colors.blue),
                const SizedBox(height: 16),
                Text(
                  "Validation du téléphone",
                  style: theme.textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  "Entrez le code envoyé au :",
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  widget.phoneE164,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _codeController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  maxLength: 6,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    letterSpacing: 8,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: const InputDecoration(
                    labelText: "Code SMS",
                    border: OutlineInputBorder(),
                    counterText: '',
                  ),
                ),
                const SizedBox(height: 16),

                // Message d'erreur
                if (_errorMsg != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Text(
                      _errorMsg!,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.red.shade700),
                    ),
                  ),

                const SizedBox(height: 16),

                // Bouton valider
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _verify,
                    child: _loading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            "Valider le code",
                            style: TextStyle(fontSize: 16),
                          ),
                  ),
                ),

                const SizedBox(height: 16),

                // ✅ Minuteur visible + bouton renvoyer
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _resendCountdown > 0
                      ? Row(
                          key: const ValueKey('countdown'),
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.timer_outlined,
                                size: 16, color: Colors.grey),
                            const SizedBox(width: 6),
                            Text(
                              "Renvoyer le code dans ${_resendCountdown}s",
                              style: theme.textTheme.bodySmall
                                  ?.copyWith(color: Colors.grey),
                            ),
                          ],
                        )
                      : TextButton.icon(
                          key: const ValueKey('resend'),
                          onPressed: canResend ? _resend : null,
                          icon: const Icon(Icons.refresh, size: 16),
                          label: const Text("Renvoyer le code"),
                        ),
                ),

                const SizedBox(height: 24),
                Text(
                  "Support: ${AppBrand.supportEmail}",
                  textAlign: TextAlign.center,
                  style:
                      theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
