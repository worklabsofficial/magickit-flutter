import 'package:flutter/material.dart';
import 'package:magickit/magickit.dart';

class MagicKitDividerExample extends StatelessWidget {
  const MagicKitDividerExample({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = MagicTheme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MagicText('Horizontal divider', style: MagicTextStyle.caption),
        const MagicDivider(),
        SizedBox(height: theme.spacing.sm),
        MagicText('Vertical divider', style: MagicTextStyle.caption),
        SizedBox(height: theme.spacing.xs),
        Row(
          children: [
            Container(
              padding: EdgeInsets.all(theme.spacing.sm),
              color: theme.colors.surface,
              child: MagicText('Left', style: MagicTextStyle.bodySmall),
            ),
            const MagicDivider(),
            Container(
              padding: EdgeInsets.all(theme.spacing.sm),
              color: theme.colors.surface,
              child: MagicText('Right', style: MagicTextStyle.bodySmall),
            ),
          ],
        ),
      ],
    );
  }
}
