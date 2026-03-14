import 'package:flutter/material.dart';
import 'package:magickit/magickit.dart';

class MagicKitListTileExample extends StatelessWidget {
  const MagicKitListTileExample({super.key});

  @override
  Widget build(BuildContext context) {
    return MagicCard(
      padding: EdgeInsets.zero,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          MagicListTile(
            title: 'Design updates',
            subtitle: '2 files changed',
            leading: const MagicIcon(Icons.design_services_outlined),
            trailing: const MagicBadge(label: 'New'),
            onTap: () {},
            showDivider: true,
          ),
          MagicListTile(
            title: 'Build status',
            subtitle: 'All checks passed',
            leading: const MagicIcon(Icons.check_circle_outline),
            trailing: const MagicBadge(
              label: 'Success',
              variant: MagicBadgeVariant.solid,
            ),
            onTap: () {},
          ),
        ],
      ),
    );
  }
}
