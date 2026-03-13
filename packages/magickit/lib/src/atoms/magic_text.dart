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

  /// Override style (akan di-merge dengan style token).
  final TextStyle? styleOverride;

  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  const MagicText(
    this.text, {
    super.key,
    this.style = MagicTextStyle.bodyMedium,
    this.color,
    this.styleOverride,
    this.textAlign,
    this.maxLines,
    this.overflow,
  });

  const MagicText.headingH1(
    String text, {
    Key? key,
    Color? color,
    TextStyle? style,
    TextAlign? textAlign,
    int? maxLines,
    TextOverflow? overflow,
  }) : this(
          text,
          key: key,
          style: MagicTextStyle.h1,
          color: color,
          styleOverride: style,
          textAlign: textAlign,
          maxLines: maxLines,
          overflow: overflow,
        );

  const MagicText.headingH2(
    String text, {
    Key? key,
    Color? color,
    TextStyle? style,
    TextAlign? textAlign,
    int? maxLines,
    TextOverflow? overflow,
  }) : this(
          text,
          key: key,
          style: MagicTextStyle.h2,
          color: color,
          styleOverride: style,
          textAlign: textAlign,
          maxLines: maxLines,
          overflow: overflow,
        );

  const MagicText.headingH3(
    String text, {
    Key? key,
    Color? color,
    TextStyle? style,
    TextAlign? textAlign,
    int? maxLines,
    TextOverflow? overflow,
  }) : this(
          text,
          key: key,
          style: MagicTextStyle.h3,
          color: color,
          styleOverride: style,
          textAlign: textAlign,
          maxLines: maxLines,
          overflow: overflow,
        );

  const MagicText.headingH4(
    String text, {
    Key? key,
    Color? color,
    TextStyle? style,
    TextAlign? textAlign,
    int? maxLines,
    TextOverflow? overflow,
  }) : this(
          text,
          key: key,
          style: MagicTextStyle.h4,
          color: color,
          styleOverride: style,
          textAlign: textAlign,
          maxLines: maxLines,
          overflow: overflow,
        );

  const MagicText.headingH5(
    String text, {
    Key? key,
    Color? color,
    TextStyle? style,
    TextAlign? textAlign,
    int? maxLines,
    TextOverflow? overflow,
  }) : this(
          text,
          key: key,
          style: MagicTextStyle.h5,
          color: color,
          styleOverride: style,
          textAlign: textAlign,
          maxLines: maxLines,
          overflow: overflow,
        );

  const MagicText.headingH6(
    String text, {
    Key? key,
    Color? color,
    TextStyle? style,
    TextAlign? textAlign,
    int? maxLines,
    TextOverflow? overflow,
  }) : this(
          text,
          key: key,
          style: MagicTextStyle.h6,
          color: color,
          styleOverride: style,
          textAlign: textAlign,
          maxLines: maxLines,
          overflow: overflow,
        );

  const MagicText.bodyLarge(
    String text, {
    Key? key,
    Color? color,
    TextStyle? style,
    TextAlign? textAlign,
    int? maxLines,
    TextOverflow? overflow,
  }) : this(
          text,
          key: key,
          style: MagicTextStyle.bodyLarge,
          color: color,
          styleOverride: style,
          textAlign: textAlign,
          maxLines: maxLines,
          overflow: overflow,
        );

  const MagicText.bodyMedium(
    String text, {
    Key? key,
    Color? color,
    TextStyle? style,
    TextAlign? textAlign,
    int? maxLines,
    TextOverflow? overflow,
  }) : this(
          text,
          key: key,
          style: MagicTextStyle.bodyMedium,
          color: color,
          styleOverride: style,
          textAlign: textAlign,
          maxLines: maxLines,
          overflow: overflow,
        );

  const MagicText.bodySmall(
    String text, {
    Key? key,
    Color? color,
    TextStyle? style,
    TextAlign? textAlign,
    int? maxLines,
    TextOverflow? overflow,
  }) : this(
          text,
          key: key,
          style: MagicTextStyle.bodySmall,
          color: color,
          styleOverride: style,
          textAlign: textAlign,
          maxLines: maxLines,
          overflow: overflow,
        );

  const MagicText.caption(
    String text, {
    Key? key,
    Color? color,
    TextStyle? style,
    TextAlign? textAlign,
    int? maxLines,
    TextOverflow? overflow,
  }) : this(
          text,
          key: key,
          style: MagicTextStyle.caption,
          color: color,
          styleOverride: style,
          textAlign: textAlign,
          maxLines: maxLines,
          overflow: overflow,
        );

  const MagicText.label(
    String text, {
    Key? key,
    Color? color,
    TextStyle? style,
    TextAlign? textAlign,
    int? maxLines,
    TextOverflow? overflow,
  }) : this(
          text,
          key: key,
          style: MagicTextStyle.label,
          color: color,
          styleOverride: style,
          textAlign: textAlign,
          maxLines: maxLines,
          overflow: overflow,
        );

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
    final baseStyle = _resolveStyle(theme.typography);
    final mergedStyle =
        styleOverride == null ? baseStyle : baseStyle.merge(styleOverride);
    final resolvedColor =
        color ?? mergedStyle.color ?? theme.colors.onBackground;
    return Text(
      text,
      style: mergedStyle.copyWith(color: resolvedColor),
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}
