import 'package:flutter/material.dart';
import 'package:magickit/magickit.dart';

class MagicKitDrawerExample extends StatelessWidget {
  const MagicKitDrawerExample({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = MagicTheme.of(context);

    return MagicDrawer(
      header: Row(
        children: [
          const MagicAvatar(fallbackInitial: 'MK'),
          SizedBox(width: theme.spacing.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MagicText('MagicKit', style: MagicTextStyle.bodyMedium),
              MagicText(
                'Design System',
                style: MagicTextStyle.caption,
                color: theme.colors.onSurface.withValues(alpha: 0.6),
              ),
            ],
          ),
        ],
      ),
      items: [
        MagicDrawerItem(
          label: 'Overview',
          icon: Icons.grid_view_outlined,
          selected: true,
          onTap: () {},
        ),
        MagicDrawerItem(
          label: 'Notifications',
          icon: Icons.notifications_outlined,
          badge: '3',
          onTap: () {},
        ),
        MagicDrawerItem(
          label: 'Settings',
          icon: Icons.settings_outlined,
          showDividerAbove: true,
          onTap: () {},
        ),
      ],
      footer: MagicButton(
        label: 'Sign out',
        variant: MagicButtonVariant.ghost,
        onPressed: () {},
      ),
    );
  }
}

class MagicKitDrawerTriggerExample extends StatelessWidget {
  final VoidCallback onOpenDrawer;

  const MagicKitDrawerTriggerExample({
    super.key,
    required this.onOpenDrawer,
  });

  @override
  Widget build(BuildContext context) {
    return MagicButton(
      label: 'Open drawer',
      onPressed: onOpenDrawer,
      variant: MagicButtonVariant.outlined,
    );
  }
}
