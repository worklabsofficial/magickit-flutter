import 'package:flutter/material.dart';
import 'package:magickit/magickit.dart';

class MagicKitTextExample extends StatelessWidget {
  const MagicKitTextExample({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = MagicTheme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const MagicText('Heading 1', style: MagicTextStyle.h1),
        SizedBox(height: theme.spacing.xs),
        const MagicText('Heading 2', style: MagicTextStyle.h2),
        SizedBox(height: theme.spacing.xs),
        const MagicText('Heading 3', style: MagicTextStyle.h3),
        SizedBox(height: theme.spacing.xs),
        const MagicText('Heading 4', style: MagicTextStyle.h4),
        const MagicText('Body Large', style: MagicTextStyle.bodyLarge),
        const MagicText('Body Medium', style: MagicTextStyle.bodyMedium),
        const MagicText('Body Small', style: MagicTextStyle.bodySmall),
        const MagicText('Caption text', style: MagicTextStyle.caption),
        const MagicText('Label text', style: MagicTextStyle.label),
      ],
    );
  }
}
