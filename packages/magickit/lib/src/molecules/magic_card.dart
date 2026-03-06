import 'package:flutter/material.dart';
import '../tokens/magic_theme.dart';

enum MagicCardElevation { none, sm, md, lg }

/// {@magickit}
/// name: MagicCard
/// category: molecule
/// use_case: Container card dengan shadow dan border radius untuk mengelompokkan konten
/// visual_keywords: card, container, box, panel, kotak, grup konten
/// {@end}
class MagicCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final MagicCardElevation elevation;
  final BorderRadius? borderRadius;
  final Color? color;
  final VoidCallback? onTap;
  final Border? border;

  const MagicCard({
    super.key,
    required this.child,
    this.padding,
    this.elevation = MagicCardElevation.sm,
    this.borderRadius,
    this.color,
    this.onTap,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    final theme = MagicTheme.of(context);

    final resolvedShadow = switch (elevation) {
      MagicCardElevation.none => theme.shadows.none,
      MagicCardElevation.sm => theme.shadows.sm,
      MagicCardElevation.md => theme.shadows.md,
      MagicCardElevation.lg => theme.shadows.lg,
    };

    final resolvedRadius =
        borderRadius ?? BorderRadius.circular(theme.radius.md);

    final container = Container(
      padding: padding ?? EdgeInsets.all(theme.spacing.md),
      decoration: BoxDecoration(
        color: color ?? theme.colors.surface,
        borderRadius: resolvedRadius,
        boxShadow: resolvedShadow,
        border: border,
      ),
      child: child,
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: resolvedRadius,
          child: container,
        ),
      );
    }

    return container;
  }
}
