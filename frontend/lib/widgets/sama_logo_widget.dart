import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SamaLogoWidget extends StatelessWidget {
  final double size;
  final bool showText;

  const SamaLogoWidget({
    super.key,
    this.size = 78,
    this.showText = true,
  });

  static const String _svgFull = r'''
<svg viewBox="0 0 140 140" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <radialGradient id="g" cx="35%" cy="30%" r="75%">
      <stop offset="0%" stop-color="#1A7ED4" stop-opacity="0.85"/>
      <stop offset="55%" stop-color="#0D2B6B" stop-opacity="1"/>
      <stop offset="100%" stop-color="#0A2040" stop-opacity="1"/>
    </radialGradient>

    <linearGradient id="ring" x1="0%" y1="0%" x2="100%" y2="0%">
      <stop offset="0%" stop-color="#7EC8F7" stop-opacity="0.35"/>
      <stop offset="45%" stop-color="#42AAFE" stop-opacity="1"/>
      <stop offset="100%" stop-color="#7EC8F7" stop-opacity="0.30"/>
    </linearGradient>
  </defs>

  <ellipse cx="70" cy="86" rx="64" ry="20"
    fill="none" stroke="url(#ring)" stroke-width="8"
    stroke-dasharray="96 96" stroke-dashoffset="48"/>

  <circle cx="70" cy="62" r="48" fill="url(#g)"/>

  <ellipse cx="70" cy="62" rx="48" ry="14" fill="none" stroke="#BFE6FF" stroke-opacity="0.22" stroke-width="2"/>
  <ellipse cx="70" cy="62" rx="48" ry="28" fill="none" stroke="#BFE6FF" stroke-opacity="0.18" stroke-width="2"/>
  <line x1="22" y1="62" x2="118" y2="62" stroke="#BFE6FF" stroke-opacity="0.18" stroke-width="2"/>

  <ellipse cx="70" cy="62" rx="16" ry="48" fill="none" stroke="#BFE6FF" stroke-opacity="0.18" stroke-width="2"/>
  <ellipse cx="70" cy="62" rx="32" ry="48" fill="none" stroke="#BFE6FF" stroke-opacity="0.14" stroke-width="2"/>
  <line x1="70" y1="14" x2="70" y2="110" stroke="#BFE6FF" stroke-opacity="0.14" stroke-width="2"/>

  <ellipse cx="70" cy="86" rx="64" ry="20"
    fill="none" stroke="url(#ring)" stroke-width="8"
    stroke-dasharray="96 96"/>

  <path d="M 103 16 L 107 28 L 120 32 L 107 36 L 103 48 L 99 36 L 86 32 L 99 28 Z"
    fill="#FFD700"/>
  <circle cx="103" cy="32" r="5" fill="#FFF4A8" opacity="0.65"/>
</svg>
''';

  @override
  Widget build(BuildContext context) {
    if (!showText) {
      return SvgPicture.string(_svgFull, width: size, height: size);
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SvgPicture.string(_svgFull, width: size, height: size),
        const SizedBox(height: 8),
        Text(
          'SAMA',
          style: TextStyle(
            color: const Color(0xFF0D2B6B),
            fontWeight: FontWeight.w900,
            fontSize: size * 0.28,
            letterSpacing: 2.6,
            height: 1.0,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'Services International',
          style: TextStyle(
            color: const Color(0xFF6B7A99),
            fontWeight: FontWeight.w600,
            fontSize: size * 0.12,
            letterSpacing: 0.6,
            height: 1.0,
          ),
        ),
      ],
    );
  }
}

class SamaTopBarLogo extends StatelessWidget {
  const SamaTopBarLogo({super.key});

  // Reference screen width (iPhone 14 Pro, 390 logical pixels) used as the
  // baseline for proportional font scaling across different screen sizes.
  static const double _kBaseScreenWidth = 390;

  static const String _svgMark = r'''
<svg viewBox="0 0 64 64" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <radialGradient id="g" cx="35%" cy="30%" r="70%">
      <stop offset="0%" stop-color="#1A7ED4" stop-opacity="0.9"/>
      <stop offset="60%" stop-color="#0D2B6B" stop-opacity="1"/>
      <stop offset="100%" stop-color="#0A2040" stop-opacity="1"/>
    </radialGradient>

    <linearGradient id="ring" x1="0%" y1="0%" x2="100%" y2="0%">
      <stop offset="0%" stop-color="#7EC8F7" stop-opacity="0.28"/>
      <stop offset="55%" stop-color="#42AAFE" stop-opacity="1"/>
      <stop offset="100%" stop-color="#7EC8F7" stop-opacity="0.22"/>
    </linearGradient>
  </defs>

  <ellipse cx="32" cy="38" rx="26" ry="9" fill="none" stroke="url(#ring)" stroke-width="4"/>
  <circle cx="32" cy="28" r="18" fill="url(#g)"/>
  <path d="M 45 10 L 47 16 L 53 18 L 47 20 L 45 26 L 43 20 L 37 18 L 43 16 Z" fill="#FFD700"/>
</svg>
''';

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    // Scale grows gradually from small phones (360px) up to desktop (1440px),
    // capped so the top bar never gets oversized.
    final scale = (screenWidth / _kBaseScreenWidth).clamp(0.9, 1.5);

    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          gradient: const LinearGradient(
            colors: [Color(0xFF2296F3), Color(0xFF00D4C8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SvgPicture.string(
            _svgMark,
            width: 26,
            height: 26,
          ),
        ),
      ),
      const SizedBox(width: 10),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'SAMA',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 15 * scale,
              letterSpacing: 2.2,
              height: 1.0,
            ),
          ),
          Text(
            'SERVICES INTERNATIONAL',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontWeight: FontWeight.w800,
              fontSize: 10 * scale,
              letterSpacing: 1.2,
              height: 1.0,
            ),
          ),
        ],
      ),
    ]);
  }
}
