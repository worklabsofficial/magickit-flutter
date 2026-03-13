import 'package:flutter/material.dart';
import '../tokens/magic_theme.dart';

/// {@magickit}
/// name: MagicDivider
/// category: atom
/// use_case: Garis pemisah antar section
/// visual_keywords: divider, garis, separator, pemisah, hr
/// {@end}
class MagicDivider extends StatelessWidget {
  /// Override axis. Null = auto mengikuti konteks (Row/Column).
  final Axis? axis;

  /// Ketebalan garis. Default: 1.
  final double? thickness;

  /// Warna garis. Default: theme.colors.outline.
  final Color? color;

  final double indent;
  final double endIndent;

  const MagicDivider({
    super.key,
    this.axis,
    this.thickness,
    this.color,
    this.indent = 0,
    this.endIndent = 0,
  });

  Axis _resolveAxis(BuildContext context) {
    if (axis != null) return axis!;
    final flex = context.findAncestorWidgetOfExactType<Flex>();
    if (flex == null) return Axis.horizontal;
    return flex.direction == Axis.vertical ? Axis.horizontal : Axis.vertical;
  }

  @override
  Widget build(BuildContext context) {
    final theme = MagicTheme.of(context);
    final resolvedColor = color ?? theme.colors.outline;
    final resolvedThickness = thickness ?? 1.0;
    final resolvedAxis = _resolveAxis(context);

    if (resolvedAxis == Axis.vertical) {
      return VerticalDivider(
        thickness: resolvedThickness,
        color: resolvedColor,
        indent: indent,
        endIndent: endIndent,
      );
    }

    return Divider(
      thickness: resolvedThickness,
      color: resolvedColor,
      indent: indent,
      endIndent: endIndent,
    );
  }
}
