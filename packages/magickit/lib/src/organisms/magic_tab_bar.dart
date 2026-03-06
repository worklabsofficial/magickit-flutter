import 'package:flutter/material.dart';
import '../tokens/magic_theme.dart';

class MagicTab {
  final String label;
  final IconData? icon;

  const MagicTab({required this.label, this.icon});
}

/// {@magickit}
/// name: MagicTabBar
/// category: organism
/// use_case: Tab bar untuk navigasi antar section konten dalam satu halaman
/// visual_keywords: tab bar, tabs, tab, section, navigasi konten
/// {@end}
class MagicTabBar extends StatelessWidget implements PreferredSizeWidget {
  final List<MagicTab> tabs;
  final TabController controller;
  final bool isScrollable;

  const MagicTabBar({
    super.key,
    required this.tabs,
    required this.controller,
    this.isScrollable = false,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final theme = MagicTheme.of(context);

    return Container(
      color: theme.colors.surface,
      child: TabBar(
        controller: controller,
        isScrollable: isScrollable,
        labelColor: theme.colors.primary,
        unselectedLabelColor: theme.colors.onSurface.withValues(alpha: 0.5),
        labelStyle: theme.typography.label.copyWith(fontWeight: FontWeight.w600),
        unselectedLabelStyle: theme.typography.label,
        indicatorColor: theme.colors.primary,
        indicatorWeight: 2,
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: theme.colors.outline,
        tabs: tabs
            .map(
              (tab) => Tab(
                text: tab.icon == null ? tab.label : null,
                child: tab.icon != null
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(tab.icon, size: 16),
                          const SizedBox(width: 6),
                          Text(tab.label),
                        ],
                      )
                    : null,
              ),
            )
            .toList(),
      ),
    );
  }
}
