import 'package:flutter/material.dart';

class SamaBrandMark extends StatelessWidget {
  final double size;
  const SamaBrandMark({super.key, this.size = 34});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.28),
        gradient: const LinearGradient(
          colors: [Color(0xFF0D2B6B), Color(0xFF1A7ED4)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Orbite
          Container(
            width: size * 0.72,
            height: size * 0.28,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: const Color(0xFF7EC8F7).withValues(alpha: 0.95),
                width: 2,
              ),
            ),
          ),

          // Globe
          Container(
            width: size * 0.42,
            height: size * 0.42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF0A2040).withValues(alpha: 0.55),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.35),
                width: 1,
              ),
            ),
          ),

          // Étoile
          Positioned(
            right: size * 0.18,
            top: size * 0.18,
            child: Container(
              width: size * 0.16,
              height: size * 0.16,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFFFD700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
