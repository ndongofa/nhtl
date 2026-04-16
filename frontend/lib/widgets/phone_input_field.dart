import 'package:flutter/material.dart';
import 'package:intl_phone_field/countries.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:intl_phone_field/phone_number.dart';

/// Widget réutilisable de saisie de numéro de téléphone.
/// Retourne toujours un numéro au format E.164 (ex: +221783042838)
/// via [onChanged], quelle que soit la saisie de l'utilisateur.
///
/// Comportements appliqués :
/// - Accepte la saisie débutant par '+' ou '0'.
/// - Détection automatique du pays à partir de l'indicatif saisi
///   (formats +XXX… ou 00XXX…, avec ou sans séparateurs) et mise à jour
///   automatique du drapeau.
/// - Le zéro initial du numéro local est conservé pendant la saisie
///   et supprimé automatiquement lorsque le champ perd le focus.
/// - Affichage groupé par paires de chiffres (ex: 78 30 42 83 8).
/// - Numéro soumis au format E.164 standard (ex: +221783042838) sans espaces.
/// - Bouton d'effacement rapide lorsque le champ contient du texte.
/// - Correction automatique du clavier désactivée.
/// - Prise en charge correcte du copier/coller d'un numéro E.164 complet.
///
/// Utilisation :
/// ```dart
/// String? _phoneE164;
///
/// PhoneInputField(
///   initialCountryCode: 'SN',
///   onChanged: (e164) => _phoneE164 = e164,
/// )
/// ```
class PhoneInputField extends StatefulWidget {
  /// Callback appelé à chaque changement — reçoit le numéro E.164 complet
  /// (ex: +221783042838) ou null si le numéro est invalide / vide.
  final void Function(String? e164) onChanged;

  /// Code pays ISO 3166-1 alpha-2 par défaut (ex: 'SN' pour Sénégal)
  final String initialCountryCode;

  /// Valeur initiale du numéro (sans indicatif, juste la partie locale)
  final String? initialValue;

  /// Label du champ
  final String label;

  /// Si true, le champ est obligatoire
  final bool required;

  const PhoneInputField({
    super.key,
    required this.onChanged,
    this.initialCountryCode = 'SN',
    this.initialValue,
    this.label = 'Téléphone',
    this.required = true,
  });

  @override
  State<PhoneInputField> createState() => _PhoneInputFieldState();
}

class _PhoneInputFieldState extends State<PhoneInputField> {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  late String _countryCode;

  /// Incrémenté pour forcer la reconstruction d'[IntlPhoneField]
  /// lors d'un changement de pays automatique.
  int _fieldKey = 0;

  /// Compteur de génération pour éviter les conflits entre microtasks
  /// successifs lors d'une détection internationale rapide.
  int _generation = 0;

  /// Garde contre la récursion lors de la mise à jour du contrôleur.
  bool _isSanitizing = false;

  /// Indique si le champ contient du texte (pour le bouton d'effacement).
  bool _hasContent = false;

  /// Liste des pays triée du plus long au plus court indicatif,
  /// calculée une seule fois.
  static final List<Country> _sortedCountries = List<Country>.of(countries)
    ..sort((a, b) => b.dialCode.length.compareTo(a.dialCode.length));

  // -----------------------------------------------------------------------
  // Lifecycle
  // -----------------------------------------------------------------------

  @override
  void initState() {
    super.initState();
    _countryCode = widget.initialCountryCode;
    final initialText = _formatForDisplay(widget.initialValue ?? '');
    _controller = TextEditingController(text: initialText);
    _hasContent = initialText.isNotEmpty;
    _controller.addListener(_onTextChanged);
    _focusNode = FocusNode()..addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _focusNode
      ..removeListener(_onFocusChanged)
      ..dispose();
    super.dispose();
  }

  // -----------------------------------------------------------------------
  // Helpers
  // -----------------------------------------------------------------------

  /// Supprime les caractères non-numériques (espaces, tirets, points,
  /// parenthèses…) et retourne les chiffres bruts avec l'offset de curseur
  /// ajusté. Conserve au maximum un zéro initial pendant la saisie
  /// (plusieurs zéros initiaux consécutifs sont réduits à un seul).
  static ({String text, int cursorOffset}) _sanitizeLocal(
      String text, int cursorPos) {
    // Conserver uniquement les chiffres et ajuster la position du curseur
    final buf = StringBuffer();
    int newCursor = cursorPos;
    for (int i = 0; i < text.length; i++) {
      if (RegExp(r'\d').hasMatch(text[i])) {
        buf.write(text[i]);
      } else {
        if (i < cursorPos) newCursor--;
      }
    }
    final digitsOnly = buf.toString();

    // Autoriser au maximum un zéro initial pendant la saisie.
    // Plusieurs zéros consécutifs en tête (ex: "003") → réduits à un seul.
    final leadingZeros =
        RegExp(r'^(0+)').firstMatch(digitsOnly)?.group(1)?.length ?? 0;
    if (leadingZeros > 1) {
      final stripped = '0${digitsOnly.substring(leadingZeros)}';
      final removed = leadingZeros - 1;
      newCursor = (newCursor - removed).clamp(0, stripped.length);
      return (text: stripped, cursorOffset: newCursor);
    }

    return (text: digitsOnly, cursorOffset: newCursor.clamp(0, digitsOnly.length));
  }

  /// Supprime tous les zéros initiaux d'une chaîne de chiffres.
  static String _stripLeadingZeros(String digits) =>
      digits.replaceFirst(RegExp(r'^0+'), '');

  /// Formate les chiffres bruts pour l'affichage en les groupant par paires
  /// séparées par des espaces (ex: "783042838" → "78 30 42 83 8").
  /// Améliore la lisibilité sans affecter le format E.164 soumis.
  static String _formatForDisplay(String digits) {
    if (digits.isEmpty) return '';
    final buf = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      if (i > 0 && i.isEven) buf.write(' ');
      buf.write(digits[i]);
    }
    return buf.toString();
  }

  /// Convertit un offset de curseur dans la chaîne brute (chiffres seuls)
  /// en offset dans la chaîne formatée (avec espaces tous les 2 chiffres).
  static int _rawCursorToFormatted(int rawCursor) {
    if (rawCursor <= 0) return 0;
    return rawCursor + (rawCursor - 1) ~/ 2;
  }

  /// Essaie de détecter le pays et d'en extraire le numéro local
  /// lorsque la saisie commence par '+' ou '00'.
  ///
  /// Normalise en supprimant tous les caractères non-numériques sauf '+',
  /// puis retourne null si le format n'est pas reconnu.
  static ({String countryCode, String localNumber})? _detectInternational(
      String text) {
    // Supprimer tout sauf chiffres et '+'
    String normalized = text.replaceAll(RegExp(r'[^\d+]'), '');
    if (normalized.startsWith('00')) {
      normalized = '+${normalized.substring(2)}';
    }
    if (!normalized.startsWith('+')) return null;

    final digitsAfterPlus = normalized.substring(1);
    if (digitsAfterPlus.isEmpty) return null;

    for (final country in _sortedCountries) {
      if (digitsAfterPlus.startsWith(country.dialCode)) {
        final local = digitsAfterPlus.substring(country.dialCode.length);
        // Supprimer le zéro initial du numéro local si présent
        final cleanLocal = local.replaceFirst(RegExp(r'^0+'), '');
        return (countryCode: country.code, localNumber: cleanLocal);
      }
    }
    return null;
  }

  // -----------------------------------------------------------------------
  // Focus — suppression du zéro initial à la fin de la saisie
  // -----------------------------------------------------------------------

  void _onFocusChanged() {
    if (_focusNode.hasFocus) return;

    // Quand le champ perd le focus, supprimer le zéro initial résiduel.
    final raw = _controller.text.replaceAll(' ', '');
    final stripped = _stripLeadingZeros(raw);
    if (stripped == raw) return; // rien à faire

    final formatted = _formatForDisplay(stripped);
    _isSanitizing = true;
    _controller.value = TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
    _isSanitizing = false;
    if (mounted) setState(() => _hasContent = formatted.isNotEmpty);
  }

  // -----------------------------------------------------------------------
  // Clear
  // -----------------------------------------------------------------------

  void _clearField() {
    _isSanitizing = true;
    _controller.value = const TextEditingValue(
      text: '',
      selection: TextSelection.collapsed(offset: 0),
    );
    _isSanitizing = false;
    if (mounted) setState(() => _hasContent = false);
    widget.onChanged(null);
  }

  // -----------------------------------------------------------------------
  // Listener
  // -----------------------------------------------------------------------

  void _onTextChanged() {
    if (_isSanitizing) return;

    final text = _controller.text;
    final cursorPos = _controller.selection.isValid
        ? _controller.selection.baseOffset
        : text.length;

    // Mettre à jour le bouton d'effacement
    final hasContent = text.isNotEmpty;
    if (hasContent != _hasContent && mounted) {
      setState(() => _hasContent = hasContent);
    }

    // --- Cas 1 : format international (+XXX ou 00XXX) ---
    final trimmedText = text.trimLeft();
    if (trimmedText.startsWith('+') || trimmedText.startsWith('00')) {
      final detected = _detectInternational(text);
      if (detected != null) {
        // Pays détecté : changer le drapeau et mettre à jour le champ.
        final gen = ++_generation;
        Future.microtask(() {
          if (!mounted || gen != _generation) return;
          final formatted = _formatForDisplay(detected.localNumber);
          _controller.removeListener(_onTextChanged);
          _controller.dispose();
          _controller = TextEditingController(text: formatted);
          _controller.addListener(_onTextChanged);
          setState(() {
            _countryCode = detected.countryCode;
            _fieldKey++;
            _hasContent = formatted.isNotEmpty;
          });
        });
        return;
      }

      // Indicatif en cours de saisie (pays pas encore identifié) :
      // conserver le préfixe '+' ou '00' avec les chiffres suivants
      // sans tomber dans la sanitisation locale.
      if (trimmedText.startsWith('+')) {
        // Garder '+' suivi uniquement de chiffres
        final digits = text.replaceAll(RegExp(r'[^\d]'), '');
        final sanitized = '+$digits';
        if (sanitized != text) {
          _isSanitizing = true;
          _controller.value = TextEditingValue(
            text: sanitized,
            selection: TextSelection.collapsed(offset: sanitized.length),
          );
          _isSanitizing = false;
        }
      } else {
        // Garder '00' suivi uniquement de chiffres
        final digits = text.replaceAll(RegExp(r'[^\d]'), '');
        if (digits != text) {
          _isSanitizing = true;
          _controller.value = TextEditingValue(
            text: digits,
            selection: TextSelection.collapsed(offset: digits.length),
          );
          _isSanitizing = false;
        }
      }
      return;
    }

    // --- Cas 2 : numéro local (peut débuter par un 0) ---
    // Le zéro initial est conservé pendant la saisie et supprimé au blur.
    final result = _sanitizeLocal(text, cursorPos);
    final formatted = _formatForDisplay(result.text);
    final formattedCursor =
        _rawCursorToFormatted(result.cursorOffset).clamp(0, formatted.length);

    if (formatted != text || formattedCursor != cursorPos) {
      _isSanitizing = true;
      _controller.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formattedCursor),
      );
      _isSanitizing = false;
    }
  }

  // -----------------------------------------------------------------------
  // Validation
  // -----------------------------------------------------------------------

  /// Valide le numéro selon la règle "requis" et les longueurs min/max
  /// du pays sélectionné (remplace la validation interne d'IntlPhoneField
  /// désactivée via disableLengthCheck: true).
  /// Les espaces visuels et le zéro initial sont ignorés lors de la validation.
  String? _validatePhone(PhoneNumber? phone) {
    // Supprimer espaces et zéro initial avant validation
    final number =
        _stripLeadingZeros((phone?.number ?? '').replaceAll(' ', '').trim());
    if (number.isEmpty) {
      return widget.required ? 'Téléphone requis' : null;
    }
    final matches =
        _sortedCountries.where((c) => c.code == phone!.countryISOCode);
    if (matches.isEmpty) return null; // pays inconnu : pas de blocage
    final country = matches.first;
    if (number.length < country.minLength || number.length > country.maxLength) {
      return 'Numéro de téléphone invalide';
    }
    return null;
  }

  // -----------------------------------------------------------------------
  // Build
  // -----------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return IntlPhoneField(
      key: ValueKey('$_fieldKey-$_countryCode'),
      controller: _controller,
      focusNode: _focusNode,
      autocorrect: false,
      decoration: InputDecoration(
        labelText: widget.label,
        border: const OutlineInputBorder(),
        counterText: '',
        hintText: '+221 78 … ou 0 78 … ou 00221 78 …',
        hintStyle: const TextStyle(fontSize: 12, color: Colors.grey),
        suffixIcon: _hasContent
            ? IconButton(
                icon: const Icon(Icons.clear, size: 18),
                tooltip: 'Effacer',
                onPressed: _clearField,
              )
            : null,
      ),
      initialCountryCode: _countryCode,
      languageCode: 'fr',
      invalidNumberMessage: 'Numéro de téléphone invalide',
      // disableLengthCheck: true empêche Flutter d'ajouter un
      // LengthLimitingTextInputFormatter qui tronquerait un numéro collé
      // au format E.164 (+XXX…) avant que notre listener puisse le traiter.
      disableLengthCheck: true,
      onChanged: (PhoneNumber phone) {
        try {
          // Supprimer les espaces visuels et le zéro initial du numéro local
          // avant de retourner le numéro au format E.164 standard.
          final localClean =
              _stripLeadingZeros(phone.number.replaceAll(' ', ''));
          if (localClean.isEmpty) {
            widget.onChanged(null);
            return;
          }
          final e164 = '${phone.countryCode}$localClean';
          widget.onChanged(e164);
        } catch (_) {
          widget.onChanged(null);
        }
      },
      onCountryChanged: (_) {
        widget.onChanged(null);
      },
      validator: (phone) => _validatePhone(phone),
    );
  }
}
