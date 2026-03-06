import 'package:flutter/material.dart';
import '../atoms/magic_badge.dart';
import '../atoms/magic_text.dart';
import '../tokens/magic_theme.dart';

class MagicDrawerItem {
  final String label;
  final IconData icon;
  final IconData? activeIcon;

  /// Badge text (e.g. "3" untuk notifikasi count).
  final String? badge;

  final bool selected;
  final VoidCallback? onTap;

  /// Tampilkan divider di atas item ini.
  final bool showDividerAbove;

  const MagicDrawerItem({
    required this.label,
    required this.icon,
    this.activeIcon,
    this.badge,
    this.selected = false,
    this.onTap,
    this.showDividerAbove = false,
  });
}

/// {@magickit}
/// name: MagicDrawer
/// category: organism
/// use_case: Side drawer untuk navigasi samping dengan header dan daftar menu
/// visual_keywords: drawer, sidebar, menu samping, navigation drawer, side menu
/// {@end}
class MagicDrawer extends StatelessWidget {
  /// Widget header di atas daftar menu (avatar, nama user, dll).
  final Widget? header;

  final List<MagicDrawerItem> items;

  /// Widget footer di bawah daftar menu (logout, settings, dll).
  final Widget? footer;

  /// Lebar drawer. Default: 280.
  final double width;

  const MagicDrawer({
    super.key,
    this.header,
    required this.items,
    this.footer,
    this.width = 280,
  });

  @override
  Widget build(BuildContext context) {
    final theme = MagicTheme.of(context);

    return Drawer(
      width: width,
      backgroundColor: theme.colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(0),
          bottomRight: Radius.circular(0),
        ),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            if (header != null) ...[
              Padding(
                padding: EdgeInsets.all(theme.spacing.md),
                child: header!,
              ),
              Divider(color: theme.colors.outline, height: 1),
            ],

            // Items
            Expanded(
              child: ListView(
                padding: EdgeInsets.symmetric(
                  vertical: theme.spacing.sm,
                  horizontal: theme.spacing.sm,
                ),
                children: items.map((item) => _buildItem(context, item, theme)).toList(),
              ),
            ),

            // Footer
            if (footer != null) ...[
              Divider(color: theme.colors.outline, height: 1),
              Padding(
                padding: EdgeInsets.all(theme.spacing.md),
                child: footer!,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildItem(
    BuildContext context,
    MagicDrawerItem item,
    MagicTheme theme,
  ) {
    final icon =
        item.selected ? (item.activeIcon ?? item.icon) : item.icon;
    final color = item.selected
        ? theme.colors.primary
        : theme.colors.onSurface.withValues(alpha: 0.7);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (item.showDividerAbove)
          Padding(
            padding: EdgeInsets.symmetric(vertical: theme.spacing.xs),
            child: Divider(color: theme.colors.outline, height: 1),
          ),
        InkWell(
          onTap: () {
            Navigator.of(context).pop();
            item.onTap?.call();
          },
          borderRadius: BorderRadius.circular(theme.radius.sm),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: theme.spacing.md,
              vertical: theme.spacing.sm + 2,
            ),
            decoration: BoxDecoration(
              color: item.selected
                  ? theme.colors.primary.withValues(alpha: 0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(theme.radius.sm),
            ),
            child: Row(
              children: [
                Icon(icon, size: 20, color: color),
                SizedBox(width: theme.spacing.md),
                Expanded(
                  child: MagicText(
                    item.label,
                    style: MagicTextStyle.bodyMedium,
                    color: item.selected
                        ? theme.colors.primary
                        : theme.colors.onSurface,
                  ),
                ),
                if (item.badge != null)
                  MagicBadge(
                    label: item.badge!,
                    variant: MagicBadgeVariant.solid,
                    color: theme.colors.primary,
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
