// lib/widgets/sama_logo_widget.dart
//
// Logo SAMA Services International
// Globe vectoriel inspiré du logo officiel — entièrement en SVG Flutter
// Utilisable dans n'importe quel widget : SamaLogoWidget(size: 80)

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SamaLogoWidget extends StatelessWidget {
  final double size;
  final bool showText;

  const SamaLogoWidget({
    Key? key,
    this.size = 60,
    this.showText = true,
  }) : super(key: key);

  static const String _svgGlobe = '''
<svg viewBox="0 0 100 100" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <linearGradient id="ring" x1="0%" y1="0%" x2="100%" y2="0%">
      <stop offset="0%" style="stop-color:#7EC8F7;stop-opacity:0.6"/>
      <stop offset="50%" style="stop-color:#42AAFE;stop-opacity:1"/>
      <stop offset="100%" style="stop-color:#7EC8F7;stop-opacity:0.4"/>
    </linearGradient>
  </defs>

  <!-- Anneau orbital arrière -->
  <ellipse cx="50" cy="62" rx="46" ry="14"
    fill="none" stroke="url(#ring)" stroke-width="5"
    stroke-dasharray="72 72" stroke-dashoffset="36"/>

  <!-- Globe -->
  <circle cx="50" cy="50" r="36" fill="#0D2B6B" stroke="#1A4A9F" stroke-width="1"/>

  <!-- Lignes de latitude -->
  <ellipse cx="50" cy="50" rx="36" ry="10" fill="none" stroke="#2A5BAD" stroke-width="0.8"/>
  <ellipse cx="50" cy="50" rx="36" ry="21" fill="none" stroke="#2A5BAD" stroke-width="0.8"/>
  <line x1="14" y1="50" x2="86" y2="50" stroke="#2A5BAD" stroke-width="0.8"/>

  <!-- Lignes de longitude -->
  <ellipse cx="50" cy="50" rx="12" ry="36" fill="none" stroke="#2A5BAD" stroke-width="0.8"/>
  <ellipse cx="50" cy="50" rx="24" ry="36" fill="none" stroke="#2A5BAD" stroke-width="0.8"/>
  <line x1="50" y1="14" x2="50" y2="86" stroke="#2A5BAD" stroke-width="0.8"/>

  <!-- Continents simplifiés (Europe/Afrique) -->
  <path d="M 46 28 Q 52 26 56 30 Q 58 35 54 38 Q 50 36 46 38 Q 43 33 46 28 Z"
    fill="#1A5BB5" opacity="0.9"/>
  <path d="M 44 40 Q 50 38 56 42 Q 60 50 58 60 Q 54 68 48 66 Q 42 62 40 52 Q 38 45 44 40 Z"
    fill="#1A5BB5" opacity="0.9"/>

  <!-- Anneau orbital avant -->
  <ellipse cx="50" cy="62" rx="46" ry="14"
    fill="none" stroke="url(#ring)" stroke-width="5"
    stroke-dasharray="72 72"/>

  <!-- Étoile / étincelle dorée -->
  <path d="M 72 22 L 74 28 L 80 30 L 74 32 L 72 38 L 70 32 L 64 30 L 70 28 Z"
    fill="#FFD700"/>
  <circle cx="72" cy="30" r="3" fill="#FFF176" opacity="0.7"/>
</svg>
''';

  @override
  Widget build(BuildContext context) {
    if (!showText) {
      return SvgPicture.string(_svgGlobe, width: size, height: size);
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SvgPicture.string(_svgGlobe, width: size, height: size),
        const SizedBox(height: 6),
        Text(
          'SAMA',
          style: TextStyle(
            color: const Color(0xFF0D2B6B),
            fontWeight: FontWeight.w900,
            fontSize: size * 0.25,
            letterSpacing: 3,
          ),
        ),
        Text(
          'Services International',
          style: TextStyle(
            color: const Color(0xFF6B7A99),
            fontWeight: FontWeight.w500,
            fontSize: size * 0.12,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}

// ── Version compacte pour top bar ─────────────────────────────────────────────

class SamaTopBarLogo extends StatelessWidget {
  const SamaTopBarLogo({Key? key}) : super(key: key);

  static const String _svgGlobe = SamaLogoWidget._svgGlobe;

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(9),
          gradient: const LinearGradient(
            colors: [Color(0xFF0D2B6B), Color(0xFF1A7ED4)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: SvgPicture.string(_svgGlobe),
        ),
      ),
      const SizedBox(width: 8),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: const [
          Text('SAMA',
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                  letterSpacing: 2.2,
                  height: 1.0)),
          Text('SERVICES INTERNATIONAL',
              style: TextStyle(
                  color: Colors.white54,
                  fontWeight: FontWeight.w600,
                  fontSize: 8,
                  letterSpacing: 0.8,
                  height: 1.0)),
        ],
      ),
    ]);
  }
}
