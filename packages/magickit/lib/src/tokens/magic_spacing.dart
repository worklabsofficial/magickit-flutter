import 'package:flutter/material.dart';

class MagicSpacing {
  /// 4px
  final double xs;

  /// 8px
  final double sm;

  /// 16px
  final double md;

  /// 24px
  final double lg;

  /// 32px
  final double xl;

  /// 48px
  final double xxl;

  const MagicSpacing({
    this.xs = 4,
    this.sm = 8,
    this.md = 16,
    this.lg = 24,
    this.xl = 32,
    this.xxl = 48,
  });

  /// Spacer otomatis mengikuti konteks (Row/Column).
  static Widget auto(
    double size, {
    Key? key,
    Axis? axis,
  }) {
    return _MagicSpacingBox(
      key: key,
      size: size,
      axis: axis,
    );
  }

  /// Spacer adaptif: ukuran berbeda untuk vertical vs horizontal.
  static Widget adaptive({
    Key? key,
    Axis? axis,
    required double vertical,
    required double horizontal,
  }) {
    return _MagicSpacingBox(
      key: key,
      axis: axis,
      vertical: vertical,
      horizontal: horizontal,
    );
  }
}

class _MagicSpacingBox extends StatelessWidget {
  final double? size;
  final double? vertical;
  final double? horizontal;
  final Axis? axis;

  const _MagicSpacingBox({
    this.size,
    this.vertical,
    this.horizontal,
    this.axis,
    super.key,
  }) : assert(
          size != null || (vertical != null && horizontal != null),
          'Provide either size or both vertical & horizontal.',
        );

  Axis _resolveAxis(BuildContext context) {
    if (axis != null) return axis!;
    final flex = context.findAncestorWidgetOfExactType<Flex>();
    return flex?.direction ?? Axis.vertical;
  }

  @override
  Widget build(BuildContext context) {
    final resolvedAxis = _resolveAxis(context);
    final resolvedSize = size ??
        (resolvedAxis == Axis.vertical ? vertical! : horizontal!);

    return SizedBox(
      width: resolvedAxis == Axis.horizontal ? resolvedSize : null,
      height: resolvedAxis == Axis.vertical ? resolvedSize : null,
    );
  }
}
