import 'package:flutter/material.dart';
import 'package:magickit/magickit.dart';

class MagicKitCardExample extends StatelessWidget {
  const MagicKitCardExample({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = MagicTheme.of(context);

    return Wrap(
      spacing: theme.spacing.md,
      runSpacing: theme.spacing.md,
      children: const [
        MagicCard(
          elevation: MagicCardElevation.none,
          child: MagicText('No elevation', style: MagicTextStyle.bodySmall),
        ),
        MagicCard(
          elevation: MagicCardElevation.sm,
          child: MagicText('Small elevation', style: MagicTextStyle.bodySmall),
        ),
        MagicCard(
          elevation: MagicCardElevation.md,
          child: MagicText('Medium elevation', style: MagicTextStyle.bodySmall),
        ),
      ],
    );
  }
}
