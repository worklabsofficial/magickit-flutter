import 'package:flutter/material.dart';
import 'package:magickit/magickit.dart';

class MagicKitBadgeExample extends StatelessWidget {
  const MagicKitBadgeExample({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = MagicTheme.of(context);

    return Wrap(
      spacing: theme.spacing.sm,
      runSpacing: theme.spacing.sm,
      children: [
        const MagicBadge(label: 'New'),
        const MagicBadge(
          label: 'Outlined',
          variant: MagicBadgeVariant.outlined,
        ),
        const MagicBadge(
          label: 'Solid',
          variant: MagicBadgeVariant.solid,
        ),
        MagicBadge(
          label: 'Info',
          icon: Icons.info_outline,
          color: theme.colors.secondary,
        ),
      ],
    );
  }
}
