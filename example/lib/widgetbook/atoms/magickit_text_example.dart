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
        MagicText('Heading 1', style: MagicTextStyle.h1),
        SizedBox(height: theme.spacing.xs),
        MagicText('Heading 2', style: MagicTextStyle.h2),
        SizedBox(height: theme.spacing.xs),
        MagicText('Heading 3', style: MagicTextStyle.h3),
        SizedBox(height: theme.spacing.xs),
        MagicText('Heading 4', style: MagicTextStyle.h4),
        MagicText('Body Large', style: MagicTextStyle.bodyLarge),
        MagicText('Body Medium', style: MagicTextStyle.bodyMedium),
        MagicText('Body Small', style: MagicTextStyle.bodySmall),
        MagicText('Caption text', style: MagicTextStyle.caption),
        MagicText('Label text', style: MagicTextStyle.label),
      ],
    );
  }
}
