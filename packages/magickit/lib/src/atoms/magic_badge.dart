import 'package:flutter/material.dart';
import '../tokens/magic_theme.dart';

enum MagicBadgeVariant { solid, outlined, soft }

/// {@magickit}
/// name: MagicBadge
/// category: atom
/// use_case: Label kecil untuk status, tag, kategori, notifikasi count
/// visual_keywords: badge, label, tag, chip, status, pill
/// {@end}
class MagicBadge extends StatelessWidget {
  final String label;
  final MagicBadgeVariant variant;

  /// Override warna badge. Default: theme.colors.primary.
  final Color? color;

  /// Icon opsional di sebelah kiri label.
  final IconData? icon;

  const MagicBadge({
    super.key,
    required this.label,
    this.variant = MagicBadgeVariant.soft,
    this.color,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = MagicTheme.of(context);
    final resolvedColor = color ?? theme.colors.primary;

    final (Color bg, Color fg, Color border) = switch (variant) {
      MagicBadgeVariant.solid => (resolvedColor, Colors.white, resolvedColor),
      MagicBadgeVariant.outlined => (
          Colors.transparent,
          resolvedColor,
          resolvedColor,
        ),
      MagicBadgeVariant.soft => (
          resolvedColor.withValues(alpha: 0.12),
          resolvedColor,
          Colors.transparent,
        ),
    };

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: theme.spacing.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(theme.radius.full),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 10, color: fg),
            const SizedBox(width: 3),
          ],
          Text(
            label,
            style: theme.typography.caption.copyWith(
              color: fg,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
