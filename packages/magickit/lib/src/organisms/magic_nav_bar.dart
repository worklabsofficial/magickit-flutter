import 'package:flutter/material.dart';
import '../tokens/magic_theme.dart';

class MagicNavBarItem {
  final String label;
  final IconData icon;

  /// Icon saat item aktif. Jika null, gunakan [icon].
  final IconData? activeIcon;

  const MagicNavBarItem({
    required this.label,
    required this.icon,
    this.activeIcon,
  });
}

/// {@magickit}
/// name: MagicNavBar
/// category: organism
/// use_case: Bottom navigation bar untuk navigasi antar halaman utama
/// visual_keywords: nav bar, navigation, bottom bar, tab bar, menu bawah
/// {@end}
class MagicNavBar extends StatelessWidget {
  final List<MagicNavBarItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  /// Tampilkan label hanya pada item yang aktif.
  final bool showLabelOnlyActive;

  const MagicNavBar({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
    this.showLabelOnlyActive = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = MagicTheme.of(context);

    return NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: onTap,
      backgroundColor: theme.colors.surface,
      indicatorColor: theme.colors.primary.withValues(alpha: 0.12),
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      labelBehavior: showLabelOnlyActive
          ? NavigationDestinationLabelBehavior.onlyShowSelected
          : NavigationDestinationLabelBehavior.alwaysShow,
      destinations: items
          .map(
            (item) => NavigationDestination(
              icon: Icon(item.icon, color: theme.colors.onSurface.withValues(alpha: 0.5)),
              selectedIcon: Icon(
                item.activeIcon ?? item.icon,
                color: theme.colors.primary,
              ),
              label: item.label,
            ),
          )
          .toList(),
    );
  }
}
