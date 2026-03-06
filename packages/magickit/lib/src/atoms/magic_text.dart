import 'package:flutter/material.dart';
import '../tokens/magic_theme.dart';
import '../tokens/magic_typography.dart';

enum MagicTextStyle { h1, h2, h3, h4, h5, h6, bodyLarge, bodyMedium, bodySmall, caption, label }

/// {@magickit}
/// name: MagicText
/// category: atom
/// use_case: Menampilkan teks dengan design token typography
/// visual_keywords: text, teks, typography, heading, body, caption, label
/// {@end}
class MagicText extends StatelessWidget {
  final String text;

  /// Style token dari MagicTypography. Default: bodyMedium.
  final MagicTextStyle style;

  /// Override warna teks. Default: theme.colors.onBackground.
  final Color? color;

  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  const MagicText(
    this.text, {
    super.key,
    this.style = MagicTextStyle.bodyMedium,
    this.color,
    this.textAlign,
    this.maxLines,
    this.overflow,
  });

  TextStyle _resolveStyle(MagicTypography typography) => switch (style) {
        MagicTextStyle.h1 => typography.heading1,
        MagicTextStyle.h2 => typography.heading2,
        MagicTextStyle.h3 => typography.heading3,
        MagicTextStyle.h4 => typography.heading4,
        MagicTextStyle.h5 => typography.heading5,
        MagicTextStyle.h6 => typography.heading6,
        MagicTextStyle.bodyLarge => typography.bodyLarge,
        MagicTextStyle.bodyMedium => typography.bodyMedium,
        MagicTextStyle.bodySmall => typography.bodySmall,
        MagicTextStyle.caption => typography.caption,
        MagicTextStyle.label => typography.label,
      };

  @override
  Widget build(BuildContext context) {
    final theme = MagicTheme.of(context);
    return Text(
      text,
      style: _resolveStyle(theme.typography).copyWith(
        color: color ?? theme.colors.onBackground,
      ),
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}
