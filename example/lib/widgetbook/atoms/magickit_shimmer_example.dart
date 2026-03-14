import 'package:flutter/material.dart';
import 'package:magickit/magickit.dart';

class MagicKitShimmerExample extends StatelessWidget {
  const MagicKitShimmerExample({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = MagicTheme.of(context);

    return Wrap(
      spacing: theme.spacing.md,
      runSpacing: theme.spacing.md,
      children: [
        const MagicShimmer(width: 140, height: 16),
        const MagicShimmer(width: 96, height: 96),
        MagicShimmer(
          width: 160,
          height: 40,
          borderRadius: BorderRadius.circular(theme.radius.full),
        ),
      ],
    );
  }
}
