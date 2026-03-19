import 'dart:async';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../../services/auth_service.dart';
import '../../ui/app_brand.dart';

class PhoneOtpScreen extends StatefulWidget {
  final String phoneE164;

  const PhoneOtpScreen({
    super.key,
    required this.phoneE164,
  });

  @override
  State<PhoneOtpScreen> createState() => _PhoneOtpScreenState();
}

class _PhoneOtpScreenState extends State<PhoneOtpScreen> {
  final _codeController = TextEditingController();
  bool _loading = false;
  String? _msg;

  // ✅ Cooldown "Renvoyer le code" — évite les 429 si l'utilisateur clique plusieurs fois
  static const int _resendCooldownSeconds = 60;
  int _resendCountdown = 0;
  Timer? _resendTimer;

  @override
  void dispose() {
    _codeController.dispose();
    _resendTimer?.cancel();
    super.dispose();
  }

  void _startResendCooldown() {
    setState(() => _resendCountdown = _resendCooldownSeconds);
    _resendTimer?.cancel();
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
      setState(() => _msg = "Veuillez entrer le code reçu par SMS.");
      return;
    }

    setState(() {
      _loading = true;
      _msg = null;
    });

    try {
      await AuthService.verifyPhoneOtp(
        phoneE164: widget.phoneE164,
        token: code,
      );

      if (!mounted) return;

      Fluttertoast.showToast(
        msg: "Téléphone confirmé. Vous pouvez maintenant vous connecter.",
        backgroundColor: Colors.green,
        toastLength: Toast.LENGTH_LONG,
      );

      Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
    } catch (e) {
      setState(() => _msg = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resend() async {
    if (_resendCountdown > 0) return;

    setState(() {
      _loading = true;
      _msg = null;
    });

    try {
      await AuthService.sendPhoneOtp(widget.phoneE164);
      _startResendCooldown();
      setState(() => _msg = "Code renvoyé par SMS.");
    } catch (e) {
      setState(() => _msg = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final canResend = _resendCountdown == 0 && !_loading;

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
                  "Validation du téléphone",
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  "Entrez le code envoyé au :\n${widget.phoneE164}",
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _codeController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: "Code SMS",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                if (_msg != null) Text(_msg!, textAlign: TextAlign.center),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _verify,
                    child: _loading
                        ? const Text("Veuillez patienter...")
                        : const Text("Valider"),
                  ),
                ),
                // ✅ Bouton renvoyer avec cooldown affiché
                TextButton(
                  onPressed: canResend ? _resend : null,
                  child: Text(
                    _resendCountdown > 0
                        ? "Renvoyer le code (${_resendCountdown}s)"
                        : "Renvoyer le code",
                  ),
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
