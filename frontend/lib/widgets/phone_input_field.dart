import 'package:flutter/material.dart';
import 'package:intl_phone_field/countries.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:intl_phone_field/phone_number.dart';

/// Widget réutilisable de saisie de numéro de téléphone.
/// Retourne toujours un numéro au format E.164 (ex: +221783042838)
/// via [onChanged], quelle que soit la saisie de l'utilisateur.
///
/// Corrections automatiques appliquées en temps réel :
/// - La correction automatique du clavier est désactivée (autocorrect: false).
/// - Suppression des caractères non-numériques (tirets, points, parenthèses…).
/// - Suppression du zéro initial du numéro local.
/// - Détection automatique du pays à partir de l'indicatif saisi
///   (formats +XXX… ou 00XXX…, avec ou sans séparateurs).
/// - Prise en charge correcte du copier/coller d'un numéro E.164 complet.
/// - Affichage groupé par paires de chiffres (ex: 78 30 42 83 8) pour la lisibilité.
/// - Numéro soumis au format E.164 standard (ex: +221783042838) sans espaces.
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
  /// (ex: +221783042838) ou null si le numéro est invalide.
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
  late String _countryCode;

  /// Incrémenté pour forcer la reconstruction d'[IntlPhoneField]
  /// lors d'un changement de pays automatique.
  int _fieldKey = 0;

  /// Compteur de génération pour éviter les conflits entre microtasks
  /// successifs lors d'une détection internationale rapide.
  int _generation = 0;

  /// Garde contre la récursion lors de la mise à jour du contrôleur.
  bool _isSanitizing = false;

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
    // Apply visual formatting to the initial value if provided
    _controller = TextEditingController(
        text: _formatForDisplay(widget.initialValue ?? ''));
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    super.dispose();
  }

  // -----------------------------------------------------------------------
  // Helpers
  // -----------------------------------------------------------------------

  /// Supprime les caractères non-numériques (espaces, tirets, points,
  /// parenthèses…) et le(s) zéro(s) initial(aux) d'un numéro local.
  /// Retourne les chiffres bruts (sans espaces) et l'offset de curseur ajusté.
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

    // Supprimer les zéros initiaux
    final stripped = digitsOnly.replaceFirst(RegExp(r'^0+'), '');
    final zerosRemoved = digitsOnly.length - stripped.length;
    newCursor = (newCursor - zerosRemoved).clamp(0, stripped.length);

    return (text: stripped, cursorOffset: newCursor);
  }

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
  // Listener
  // -----------------------------------------------------------------------

  void _onTextChanged() {
    if (_isSanitizing) return;

    final text = _controller.text;
    final cursorPos = _controller.selection.isValid
        ? _controller.selection.baseOffset
        : text.length;

    // --- Cas 1 : format international (+XXX ou 00XXX) ---
    // Vérifier après suppression d'éventuels séparateurs en tête
    final trimmedText = text.trimLeft();
    if (trimmedText.startsWith('+') || trimmedText.startsWith('00')) {
      final detected = _detectInternational(text);
      if (detected != null) {
        // Capturer la génération courante pour éviter les conflits
        final gen = ++_generation;
        // Planifier le changement après que le listener soit retourné
        Future.microtask(() {
          if (!mounted || gen != _generation) return;
          final formatted = _formatForDisplay(detected.localNumber);
          final newController = TextEditingController(text: formatted);
          _controller.removeListener(_onTextChanged);
          _controller.dispose();
          _controller = newController;
          _controller.addListener(_onTextChanged);
          setState(() {
            _countryCode = detected.countryCode;
            _fieldKey++;
          });
        });
        return;
      }
    }

    // --- Cas 2 : numéro local — supprimer espaces et zéro initial, puis formater ---
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
  /// Les espaces visuels sont ignorés lors de la validation.
  String? _validatePhone(PhoneNumber? phone) {
    final number = (phone?.number ?? '').replaceAll(' ', '').trim();
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
      autocorrect: false,
      decoration: InputDecoration(
        labelText: widget.label,
        border: const OutlineInputBorder(),
        counterText: '',
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
          // Supprimer les espaces visuels insérés pour l'affichage
          // avant de retourner le numéro au format E.164 standard.
          final e164 = phone.completeNumber.replaceAll(' ', '');
          widget.onChanged(e164.isNotEmpty ? e164 : null);
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
