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

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
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
    setState(() {
      _loading = true;
      _msg = null;
    });

    try {
      await AuthService.sendPhoneOtp(widget.phoneE164);
      setState(() => _msg = "Code renvoyé par SMS.");
    } catch (e) {
      setState(() => _msg = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
                TextButton(
                  onPressed: _loading ? null : _resend,
                  child: const Text("Renvoyer le code"),
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
