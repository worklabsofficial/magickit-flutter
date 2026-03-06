import 'package:flutter/material.dart';
import '../tokens/magic_theme.dart';

/// {@magickit}
/// name: MagicListTile
/// category: molecule
/// use_case: Item dalam daftar dengan leading, title, subtitle, dan trailing
/// visual_keywords: list tile, list item, row, item, daftar
/// {@end}
class MagicListTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool selected;
  final bool enabled;

  /// Tampilkan divider di bawah tile.
  final bool showDivider;

  const MagicListTile({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
    this.selected = false,
    this.enabled = true,
    this.showDivider = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = MagicTheme.of(context);
    final colors = theme.colors;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ListTile(
          title: Text(
            title,
            style: theme.typography.bodyMedium.copyWith(
              color: enabled ? colors.onSurface : colors.disabledForeground,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
          subtitle: subtitle != null
              ? Text(
                  subtitle!,
                  style: theme.typography.bodySmall.copyWith(
                    color: enabled
                        ? colors.onSurface.withValues(alpha: 0.6)
                        : colors.disabledForeground,
                  ),
                )
              : null,
          leading: leading,
          trailing: trailing,
          onTap: enabled ? onTap : null,
          selected: selected,
          selectedColor: colors.primary,
          selectedTileColor: colors.primary.withValues(alpha: 0.08),
          enabled: enabled,
          contentPadding: EdgeInsets.symmetric(
            horizontal: theme.spacing.md,
            vertical: theme.spacing.xs,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(theme.radius.sm),
          ),
          dense: false,
        ),
        if (showDivider)
          Divider(
            height: 1,
            color: colors.outline,
            indent: theme.spacing.md,
            endIndent: theme.spacing.md,
          ),
      ],
    );
  }
}
