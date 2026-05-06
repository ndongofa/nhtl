import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;

import '../../config/api_config.dart';
import '../../services/auth_service.dart';
import '../../ui/app_brand.dart';
import 'login_screen.dart';
import 'reset_password_screen.dart';

class PhoneOtpScreen extends StatefulWidget {
  final String phoneE164;
  final Widget? redirectTo;

  /// Quand true, après vérification OTP on navigue vers ResetPasswordScreen
  /// au lieu d'afficher "Compte activé!" (flux reset password par téléphone).
  final bool isPasswordReset;

  /// Quand true, le SMS était indisponible au moment du signup (ex: crédit Twilio
  /// épuisé). On affiche directement un message explicatif et le bouton d'activation
  /// sans code SMS, sans tenter d'envoyer un nouveau code.
  final bool smsUnavailable;

  const PhoneOtpScreen({
    Key? key,
    required this.phoneE164,
    this.redirectTo,
    this.isPasswordReset = false,
    this.smsUnavailable = false,
  }) : super(key: key);

  @override
  State<PhoneOtpScreen> createState() => _PhoneOtpScreenState();
}

class _PhoneOtpScreenState extends State<PhoneOtpScreen> {
  final _codeController = TextEditingController();
  bool _loading = false;
  String? _errorMsg;

  // Countdown before the user can ask for a new code.
  // Starts only after a successful OTP send to give honest feedback.
  static const int _resendCooldownSeconds = 60;
  int _resendCountdown = 0; // 0 = not started yet
  Timer? _resendTimer;

  // Whether to show the "activate without SMS code" bypass button.
  // Shown immediately when smsUnavailable, when the initial OTP send fails, or
  // after a resend failure.
  bool _showSkipButton = false;

  // True once the initial OTP has been confirmed as delivered.
  // The OTP form is only shown after this is true, so the message
  // "Entrez le code envoyé via WhatsApp ou SMS" is never displayed
  // before the code is actually on its way to the user.
  bool _otpSent = false;

  @override
  void initState() {
    super.initState();
    if (widget.isPasswordReset) {
      // Password-reset flow: OTP was already sent by ForgotPasswordScreen via Supabase.
      _otpSent = true;
      _startResendCooldown();
    } else if (widget.smsUnavailable) {
      // SMS indisponible lors du signup (crédit épuisé, panne provider…).
      // Le compte est créé dans Supabase. On affiche directement le bypass.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _errorMsg =
                "Le service SMS est temporairement indisponible. "
                "Votre compte a bien été créé.\n\n"
                "Activez-le directement sans code SMS grâce au bouton ci-dessous.";
            _showSkipButton = true;
          });
        }
      });
    } else {
      // Signup flow: Supabase already sent the OTP via SMS during signUp().
      // Show the entry form immediately; do NOT call the backend custom OTP
      // endpoint, which would generate a different code and cause a 400 when
      // the user enters the Supabase-issued code.
      _otpSent = true;
      _startResendCooldown();
    }
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

  /// Envoie le premier code OTP via le backend (WhatsApp → SMS).
  /// Appelé dès l'ouverture de l'écran dans le flux signup.
  /// En cas d'échec immédiat des deux canaux, affiche le bouton bypass.
  Future<void> _sendInitialOtp() async {
    setState(() {
      _loading = true;
      _errorMsg = null;
      _showSkipButton = false;
      _otpSent = false;
    });
    try {
      await AuthService.sendSignupPhoneOtp(widget.phoneE164);
      if (!mounted) return;
      setState(() => _otpSent = true);
      _startResendCooldown();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMsg =
            "L'envoi du code de vérification a échoué "
            "(${e.toString().replaceFirst('Exception: ', '')}).\n\n"
            "Vous pouvez activer votre compte directement sans code SMS.";
        _showSkipButton = true;
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _verify() async {
    final code = _codeController.text.trim();

    if (code.isEmpty) {
      setState(() => _errorMsg = "Veuillez entrer le code reçu par WhatsApp ou SMS.");
      return;
    }

    setState(() {
      _loading = true;
      _errorMsg = null;
    });

    try {
      if (widget.isPasswordReset) {
        // Password-reset flow: verify via Supabase (session required for password update).
        await AuthService.verifyPhoneOtp(
          phoneE164: widget.phoneE164,
          token: code,
        );
        if (!mounted) return;
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const ResetPasswordScreen()),
          (_) => false,
        );
        return;
      }

      // Signup flow: verify via Supabase (same issuer that sent the OTP during
      // signUp()). Using the backend custom endpoint would fail because it
      // tracks a different OTP code generated independently.
      await AuthService.verifyPhoneOtp(
        phoneE164: widget.phoneE164,
        token: code,
      );

      if (!mounted) return;

      // ✅ Flux signup — modale de succès
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
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => LoginScreen(redirectTo: widget.redirectTo),
        ),
        (_) => false,
      );
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
      // Both flows use Supabase to resend: password-reset uses signInWithOtp
      // and signup re-triggers the same Supabase OTP channel that was used
      // during signUp(), keeping a single OTP source of truth.
      await AuthService.sendPhoneOtp(widget.phoneE164);
      if (!mounted) return;
      _startResendCooldown();
      Fluttertoast.showToast(
        msg: "Code renvoyé.",
        backgroundColor: Colors.green,
        toastLength: Toast.LENGTH_SHORT,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMsg = e.toString().replaceFirst('Exception: ', '');
        if (!widget.isPasswordReset) {
          _showSkipButton = true; // Resend also failed → offer bypass
        }
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Confirme le compte sans OTP quand les deux providers SMS sont KO.
  /// Appelle le backend qui utilise la clé service_role Supabase pour forcer
  /// {@code phone_confirmed_at} en base.
  Future<void> _skipOtp() async {
    // Demande confirmation à l'utilisateur
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Activer le compte sans SMS"),
        content: const Text(
          "Vous n'avez toujours pas reçu votre code SMS ?\n\n"
          "Votre compte sera activé directement. "
          "Vous pourrez ensuite vous connecter avec votre mot de passe.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text("Annuler"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text("Confirmer"),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() {
      _loading = true;
      _errorMsg = null;
    });

    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/api/auth/skip-phone-otp');
      final resp = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'phone': widget.phoneE164}),
      );

      if (!mounted) return;

      if (resp.statusCode == 200) {
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                  child: Icon(Icons.check_circle_outline,
                      color: Colors.green.shade600, size: 56),
                ),
                const SizedBox(height: 20),
                const Text(
                  "Compte activé !",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  "Votre compte associé au numéro ${widget.phoneE164} est maintenant actif.\n"
                  "Vous pouvez vous connecter.",
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14, color: Colors.black54),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.login),
                    label: const Text("Se connecter",
                        style: TextStyle(fontSize: 16)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade600,
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
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => LoginScreen(redirectTo: widget.redirectTo),
          ),
          (_) => false,
        );
      } else {
        final decoded = jsonDecode(resp.body) as Map<String, dynamic>?;
        final errMsg = decoded?['error']?.toString() ??
            "Impossible d'activer le compte. Réessayez ou contactez le support.";
        setState(() => _errorMsg = errMsg);
      }
    } catch (e) {
      if (!mounted) return;
      setState(
          () => _errorMsg = "Erreur réseau. Vérifiez votre connexion et réessayez.");
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // ── Determine which view to render ──────────────────────────────────────
    // Signup flow only: while the initial OTP is being sent, show a dedicated
    // loading screen so that the "code envoyé via WhatsApp ou SMS" message is
    // never displayed before delivery is confirmed.
    // True iff: signup, no prior failure, OTP not yet confirmed, and currently loading.
    final bool isSendingInitialOtp =
        !widget.isPasswordReset && !widget.smsUnavailable && !_otpSent && _loading && !_showSkipButton;

    // True iff the initial OTP send (or a retry) definitively failed for a signup
    // user — the code was never delivered so the bypass should be shown up-front,
    // not buried at the bottom of the form.  Never true for password-reset flow.
    final bool isOtpSendFailed =
        !widget.isPasswordReset && _showSkipButton && !_otpSent;

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
                // ── Header icon + title (always visible) ─────────────────────
                Icon(
                  isSendingInitialOtp
                      ? Icons.send_outlined
                      : isOtpSendFailed
                          ? Icons.sms_failed_outlined
                          : Icons.sms_outlined,
                  size: 48,
                  color: isOtpSendFailed ? Colors.orange : Colors.blue,
                ),
                const SizedBox(height: 16),
                Text(
                  widget.isPasswordReset
                      ? "Réinitialisation par SMS"
                      : "Validation du téléphone",
                  style: theme.textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),

                // ── Loading state: initial OTP send in progress ───────────────
                if (isSendingInitialOtp) ...[
                  Text(
                    "Envoi du code de vérification en cours…",
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
                  const SizedBox(height: 32),
                  const CircularProgressIndicator(),
                  const SizedBox(height: 24),
                  Text(
                    "Support: ${AppBrand.supportEmail}",
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: Colors.grey),
                  ),
                ]

                // ── Failure state: OTP never sent, show bypass immediately ────
                else if (isOtpSendFailed) ...[
                  Text(
                    "Le code n'a pas pu être envoyé au :",
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
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Text(
                      _errorMsg ??
                          "Le service SMS est temporairement indisponible. "
                          "Activez votre compte directement sans code.",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.orange.shade800),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _skipOtp,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                      ),
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
                              "Activer le compte sans code SMS",
                              style: TextStyle(fontSize: 16),
                            ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton.icon(
                    onPressed: _loading ? null : _sendInitialOtp,
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text("Réessayer l'envoi du code"),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    "Support: ${AppBrand.supportEmail}",
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: Colors.grey),
                  ),
                ]

                // ── Normal state: OTP confirmed sent (or password-reset / smsUnavailable) ──
                else ...[
                  if (!widget.smsUnavailable) ...[
                    Text(
                      widget.isPasswordReset
                          ? "Entrez le code envoyé au :"
                          : "Entrez le code envoyé via WhatsApp ou SMS au :",
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
                  ],

                  // Message d'erreur ou d'information
                  if (_errorMsg != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: widget.smsUnavailable
                            ? Colors.orange.shade50
                            : Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: widget.smsUnavailable
                              ? Colors.orange.shade200
                              : Colors.red.shade200,
                        ),
                      ),
                      child: Text(
                        _errorMsg!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: widget.smsUnavailable
                              ? Colors.orange.shade800
                              : Colors.red.shade700,
                        ),
                      ),
                    ),

                  const SizedBox(height: 16),

                  // Bouton valider (masqué quand smsUnavailable et pas encore de bypass)
                  if (!widget.smsUnavailable)
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
                            : Text(
                                widget.isPasswordReset
                                    ? "Vérifier le code"
                                    : "Valider le code",
                                style: const TextStyle(fontSize: 16),
                              ),
                      ),
                    ),

                  const SizedBox(height: 16),

                  // Minuteur + bouton renvoyer
                  if (!widget.smsUnavailable) ...[
                    if (_resendCountdown > 0)
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: Row(
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
                        ),
                      )
                    else if (!_loading)
                      TextButton.icon(
                        onPressed: _resend,
                        icon: const Icon(Icons.refresh, size: 16),
                        label: const Text("Renvoyer le code"),
                      ),
                  ],

                  const SizedBox(height: 24),
                  Text(
                    "Support: ${AppBrand.supportEmail}",
                    textAlign: TextAlign.center,
                    style:
                        theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                  ),

                  // ── Bypass OTP (signup uniquement, uniquement après échec de renvoi) ──
                  if (!widget.isPasswordReset && _showSkipButton) ...[
                    const SizedBox(height: 20),
                    const Divider(),
                    const SizedBox(height: 8),
                    Text(
                      "Toujours pas de code SMS après plusieurs tentatives ?",
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: _loading ? null : _skipOtp,
                      child: const Text(
                        "Activer le compte sans code SMS",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.orange,
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
