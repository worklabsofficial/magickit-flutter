import 'package:flutter/material.dart';
import '../tokens/magic_theme.dart';

/// {@magickit}
/// name: MagicDivider
/// category: atom
/// use_case: Garis pemisah antar section, dengan opsi label di tengah
/// visual_keywords: divider, garis, separator, pemisah, hr
/// {@end}
class MagicDivider extends StatelessWidget {
  /// Ketebalan garis. Default: 1.
  final double? thickness;

  /// Warna garis. Default: theme.colors.outline.
  final Color? color;

  /// Label opsional di tengah garis pemisah.
  final String? label;

  final double indent;
  final double endIndent;

  const MagicDivider({
    super.key,
    this.thickness,
    this.color,
    this.label,
    this.indent = 0,
    this.endIndent = 0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = MagicTheme.of(context);
    final resolvedColor = color ?? theme.colors.outline;
    final resolvedThickness = thickness ?? 1.0;

    if (label == null) {
      return Padding(
        padding: EdgeInsets.symmetric(
          horizontal: indent > 0 || endIndent > 0 ? 0 : 0,
        ),
        child: Divider(
          thickness: resolvedThickness,
          color: resolvedColor,
          indent: indent,
          endIndent: endIndent,
        ),
      );
    }

    return Row(
      children: [
        Expanded(
          child: Divider(
            thickness: resolvedThickness,
            color: resolvedColor,
            indent: indent,
            endIndent: theme.spacing.sm,
          ),
        ),
        Text(
          label!,
          style: theme.typography.caption.copyWith(
            color: resolvedColor,
          ),
        ),
        Expanded(
          child: Divider(
            thickness: resolvedThickness,
            color: resolvedColor,
            indent: theme.spacing.sm,
            endIndent: endIndent,
          ),
        ),
      ],
    );
  }
}
