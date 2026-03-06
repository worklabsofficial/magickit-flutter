import 'package:flutter/material.dart';
import '../tokens/magic_theme.dart';

/// {@magickit}
/// name: MagicChip
/// category: molecule
/// use_case: Tag atau filter chip yang bisa dipilih atau dihapus
/// visual_keywords: chip, tag, filter, label, badge, kategori
/// {@end}
class MagicChip extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool selected;
  final VoidCallback? onDeleted;
  final Widget? avatar;
  final Color? color;
  final bool enabled;

  const MagicChip({
    super.key,
    required this.label,
    this.onTap,
    this.selected = false,
    this.onDeleted,
    this.avatar,
    this.color,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = MagicTheme.of(context);
    final colors = theme.colors;
    final resolvedColor = color ?? colors.primary;

    final Color bg = selected
        ? resolvedColor.withValues(alpha: 0.15)
        : colors.surface;
    final Color borderColor = selected ? resolvedColor : colors.outline;
    final Color labelColor = selected
        ? resolvedColor
        : enabled
            ? colors.onSurface
            : colors.disabledForeground;

    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: EdgeInsets.symmetric(
          horizontal: theme.spacing.sm + 2,
          vertical: theme.spacing.xs,
        ),
        decoration: BoxDecoration(
          color: enabled ? bg : colors.disabled,
          borderRadius: BorderRadius.circular(theme.radius.full),
          border: Border.all(color: enabled ? borderColor : colors.disabled),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (avatar != null) ...[
              SizedBox(
                width: 20,
                height: 20,
                child: avatar!,
              ),
              SizedBox(width: theme.spacing.xs),
            ],
            Text(
              label,
              style: theme.typography.label.copyWith(color: labelColor),
            ),
            if (onDeleted != null) ...[
              SizedBox(width: theme.spacing.xs),
              GestureDetector(
                onTap: enabled ? onDeleted : null,
                child: Icon(
                  Icons.close,
                  size: 14,
                  color: labelColor.withValues(alpha: 0.7),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
