import 'package:flutter/material.dart';

class EmojiIcon extends StatelessWidget {
  final String emoji;
  final double size;

  const EmojiIcon(this.emoji, {super.key, this.size = 26});

  @override
  Widget build(BuildContext context) {
    return Text(
      emoji,
      style: TextStyle(
        fontSize: size,
        height: 1.0,
        fontFamilyFallback: const [
          'Noto Color Emoji',
          'Apple Color Emoji',
          'Segoe UI Emoji',
        ],
      ),
    );
  }
}
