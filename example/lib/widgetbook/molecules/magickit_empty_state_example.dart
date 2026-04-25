import 'package:flutter/material.dart';
import 'package:magickit/magickit.dart';

class MagicKitEmptyStateExample extends StatelessWidget {
  const MagicKitEmptyStateExample({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = MagicTheme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const MagicText('No Data', style: MagicTextStyle.label),
        SizedBox(height: theme.spacing.sm),
        const MagicEmptyState.noData(),
        SizedBox(height: theme.spacing.md),
        const MagicText('No Results', style: MagicTextStyle.label),
        SizedBox(height: theme.spacing.sm),
        const MagicEmptyState.noResults(query: 'flutter magic'),
        SizedBox(height: theme.spacing.md),
        const MagicText('Error', style: MagicTextStyle.label),
        SizedBox(height: theme.spacing.sm),
        MagicEmptyState.error(onAction: () {}),
        SizedBox(height: theme.spacing.md),
        const MagicText('Offline', style: MagicTextStyle.label),
        SizedBox(height: theme.spacing.sm),
        MagicEmptyState.offline(onAction: () {}),
        SizedBox(height: theme.spacing.md),
        const MagicText('Custom', style: MagicTextStyle.label),
        SizedBox(height: theme.spacing.sm),
        MagicEmptyState(
          icon: Icons.rocket_launch_rounded,
          title: 'Mulai Sekarang',
          description: 'Buat project pertama kamu untuk memulai.',
          actionLabel: 'Buat Project',
          onAction: () {},
          secondaryActionLabel: 'Pelajari Dulu',
          onSecondaryAction: () {},
        ),
      ],
    );
  }
}
