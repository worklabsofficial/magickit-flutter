import 'package:flutter/material.dart';
import '../tokens/magic_theme.dart';

/// {@magickit}
/// name: MagicIcon
/// category: atom
/// use_case: Menampilkan icon dengan warna dari theme tokens
/// visual_keywords: icon, ikon, symbol, glyph
/// {@end}
class MagicIcon extends StatelessWidget {
  final IconData icon;

  /// Ukuran icon dalam logical pixels. Default: 24.
  final double? size;

  /// Override warna icon. Default: theme.colors.onSurface.
  final Color? color;

  const MagicIcon(
    this.icon, {
    super.key,
    this.size,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = MagicTheme.of(context);
    return Icon(
      icon,
      size: size ?? 24,
      color: color ?? theme.colors.onSurface,
    );
  }
}
