import 'package:flutter/material.dart';
import '../tokens/magic_theme.dart';

/// {@magickit}
/// name: MagicTooltip
/// category: molecule
/// use_case: Tooltip informatif yang muncul saat hover atau long-press
/// visual_keywords: tooltip, hint, info, keterangan, hover
/// {@end}
class MagicTooltip extends StatelessWidget {
  final String message;
  final Widget child;
  final bool preferBelow;
  final Duration waitDuration;

  const MagicTooltip({
    super.key,
    required this.message,
    required this.child,
    this.preferBelow = true,
    this.waitDuration = const Duration(milliseconds: 500),
  });

  @override
  Widget build(BuildContext context) {
    final theme = MagicTheme.of(context);

    return Tooltip(
      message: message,
      preferBelow: preferBelow,
      waitDuration: waitDuration,
      decoration: BoxDecoration(
        color: theme.colors.secondary,
        borderRadius: BorderRadius.circular(theme.radius.xs),
        boxShadow: theme.shadows.sm,
      ),
      textStyle: theme.typography.caption.copyWith(
        color: theme.colors.onSecondary,
      ),
      padding: EdgeInsets.symmetric(
        horizontal: theme.spacing.sm,
        vertical: theme.spacing.xs,
      ),
      child: child,
    );
  }
}
