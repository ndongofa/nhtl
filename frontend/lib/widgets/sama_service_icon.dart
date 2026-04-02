// lib/widgets/sama_service_icon.dart
//
// Reusable badge widget for service icons across hub and service screens.
// Shows an emoji centred inside a rounded container with a tinted background
// and a subtle border in the service's brand colour.

import 'package:flutter/material.dart';
import 'emoji_icon.dart';

class SamaServiceIcon extends StatelessWidget {
  /// The emoji character(s) to display.
  final String emoji;

  /// The brand colour of the service, used to tint the background and border.
  final Color color;

  /// Overall width/height of the square badge. Defaults to 52.
  final double size;

  /// When true the background uses a white-alpha tint suitable for dark
  /// top-bar backgrounds (e.g. AppBar). Defaults to false (uses [color] tint).
  final bool onDark;

  const SamaServiceIcon({
    super.key,
    required this.emoji,
    required this.color,
    this.size = 52,
    this.onDark = false,
  });

  @override
  Widget build(BuildContext context) {
    final bg = onDark
        ? Colors.white.withValues(alpha: 0.14)
        : color.withValues(alpha: 0.12);
    final border = onDark
        ? Colors.white.withValues(alpha: 0.22)
        : color.withValues(alpha: 0.28);
    final radius = size * 0.27; // ~14 for size=52, ~9 for size=32

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: border, width: 1),
      ),
      child: Center(
        child: EmojiIcon(emoji, size: size * 0.5),
      ),
    );
  }
}
