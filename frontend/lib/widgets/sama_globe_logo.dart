// lib/widgets/sama_globe_logo.dart
// Dépendance : flutter_svg: ^2.0.10 dans pubspec.yaml
//
// Usage :
//   SamaGlobeLogo()                    // globe + SAMA + Services International
//   SamaGlobeLogo(height: 32)          // taille personnalisée
//   SamaGlobeLogo(showText: false)     // icône seule (favicon/app icon)

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SamaGlobeLogo extends StatelessWidget {
  final double height;
  final bool showText;

  const SamaGlobeLogo({
    Key? key,
    this.height = 38,
    this.showText = true,
  }) : super(key: key);

  // ── SVG globe avec axe Dakar→Casablanca→Paris ─────────────────────────────
  static const String _svg = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 44 44">
  <defs>
    <clipPath id="gc"><circle cx="22" cy="22" r="18"/></clipPath>
    <linearGradient id="gold" x1="0" y1="1" x2="0" y2="0"
        gradientUnits="objectBoundingBox">
      <stop offset="0"   stop-color="#B84000"/>
      <stop offset="0.5" stop-color="#FFB300"/>
      <stop offset="1"   stop-color="#FFE066"/>
    </linearGradient>
  </defs>

  <!-- Fond carré arrondi bleu nuit -->
  <rect x="0" y="0" width="44" height="44" rx="10" fill="#061428"/>

  <!-- Halo -->
  <circle cx="22" cy="22" r="22" fill="#0D3A80" opacity="0.12"/>

  <!-- Océan -->
  <circle cx="22" cy="22" r="18" fill="#0C2E60"/>

  <!-- Grille géo -->
  <g clip-path="url(#gc)" opacity="0.18">
    <ellipse cx="22" cy="22" rx="6"  ry="18" fill="none" stroke="#60A8FF" stroke-width="0.6"/>
    <ellipse cx="22" cy="22" rx="12" ry="18" fill="none" stroke="#60A8FF" stroke-width="0.6"/>
    <ellipse cx="22" cy="22" rx="17" ry="18" fill="none" stroke="#60A8FF" stroke-width="0.6"/>
    <ellipse cx="22" cy="14" rx="17" ry="4"  fill="none" stroke="#60A8FF" stroke-width="0.5"/>
    <ellipse cx="22" cy="22" rx="18" ry="4.5" fill="none" stroke="#60A8FF" stroke-width="0.6"/>
    <ellipse cx="22" cy="30" rx="17" ry="4"  fill="none" stroke="#60A8FF" stroke-width="0.5"/>
    <line x1="4" y1="22" x2="40" y2="22" stroke="#60A8FF" stroke-width="0.6"/>
  </g>

  <!-- Continents -->
  <g clip-path="url(#gc)">
    <!-- Europe -->
    <path d="M23 8 Q26 7 28 8 Q30 9.5 29.5 12 Q28.5 13.5 27 13 Q26.5 14 27 15.5
             Q25.5 16 24.5 15 Q23 14 23.5 12 Q22 10 23 8Z"
          fill="#1860B0" opacity="0.82"/>
    <!-- Ibérie -->
    <path d="M21 11 Q22.5 10 23.5 11 Q24 12 23.5 13.5 Q22.5 14 21.5 13.5 Q20.5 13 21 11Z"
          fill="#1860B0" opacity="0.72"/>
    <!-- Afrique Nord / Maroc -->
    <path d="M21.5 15.5 Q23.5 14.5 25 15.5 Q26.5 17 26 19 Q25 20 23 20
             Q21 20 20.5 18.5 Q20 17 21.5 15.5Z"
          fill="#1860B0" opacity="0.80"/>
    <!-- Afrique subsaharienne -->
    <path d="M21 19.5 Q23.5 18.5 26 20 Q27.5 21.5 27.5 24.5 Q27.5 28 25.5 31
             Q23.5 33 22 33.5 Q20.5 33.5 19 32 Q17 29.5 16.5 26.5 Q16 23 17 21
             Q18 19.5 21 19.5Z"
          fill="#1860B0" opacity="0.76"/>
    <!-- Sénégal tip -->
    <path d="M15.5 26 Q17 25 18 26.5 Q18.5 28 17.5 29 Q16 29.5 15 28 Q14.5 27 15.5 26Z"
          fill="#1D74C8" opacity="0.90"/>
    <!-- Amérique Nord -->
    <path d="M6 12 Q8.5 10.5 11 11.5 Q12.5 12.5 12.5 14.5 Q12.5 16.5 11 17.5
             Q9 18.5 7 17.5 Q5 16 5.5 14Z"
          fill="#1860B0" opacity="0.60"/>
    <!-- Amérique Sud -->
    <path d="M7 21 Q9 19.5 11.5 21 Q13 22.5 12.5 25.5 Q12 28.5 10.5 30.5
             Q9 32 7 32 Q5 32 4 30 Q3 27.5 3.5 25 Q3 22.5 5 21.5Z"
          fill="#1860B0" opacity="0.62"/>
  </g>

  <!-- Reflet -->
  <ellipse cx="14" cy="15" rx="5" ry="3" fill="white" opacity="0.05"/>

  <!-- Bordure globe -->
  <circle cx="22" cy="22" r="18" fill="none" stroke="#2870D8"
          stroke-width="1.2" opacity="0.65"/>
  <!-- Anneau or pointillé -->
  <circle cx="22" cy="22" r="20" fill="none" stroke="#FFB300"
          stroke-width="0.5" opacity="0.20" stroke-dasharray="2,6"/>

  <!-- Axe Dakar(14,28) → Casablanca(22,17) → Paris(24,10) -->
  <path d="M14 28 Q17 22 22 17 Q23 13.5 24 10"
        fill="none" stroke="url(#gold)"
        stroke-width="1.8" stroke-linecap="round" stroke-dasharray="2.5,2"/>

  <!-- Points villes — double cercle -->
  <!-- Dakar -->
  <circle cx="14" cy="28" r="2.8" fill="#061428" stroke="#C85000" stroke-width="1.2"/>
  <circle cx="14" cy="28" r="1.4" fill="#C85000"/>
  <!-- Casablanca -->
  <circle cx="22" cy="17" r="2.8" fill="#061428" stroke="#FFB300" stroke-width="1.2"/>
  <circle cx="22" cy="17" r="1.4" fill="#FFB300"/>
  <!-- Paris -->
  <circle cx="24" cy="10" r="2.8" fill="#061428" stroke="#FFE066" stroke-width="1.2"/>
  <circle cx="24" cy="10" r="1.4" fill="#FFE066"/>

  <!-- Flèche vers Paris -->
  <path d="M22 7 L24 4 L26 7"
        fill="none" stroke="#FFE066"
        stroke-width="1.2" stroke-linecap="round" stroke-linejoin="round"/>
</svg>
''';

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SvgPicture.string(_svg, height: height, width: height),
        if (showText) ...[
          SizedBox(width: height * 0.22),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'SAMA',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: height * 0.44,
                  letterSpacing: 2.0,
                  height: 1.0,
                ),
              ),
              Text(
                'Services International',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.65),
                  fontWeight: FontWeight.w600,
                  fontSize: height * 0.30,
                  letterSpacing: 0.4,
                  height: 1.0,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
