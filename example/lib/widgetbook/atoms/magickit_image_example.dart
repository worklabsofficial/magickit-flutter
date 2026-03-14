import 'package:flutter/material.dart';
import 'package:magickit/magickit.dart';

class MagicKitImageExample extends StatelessWidget {
  const MagicKitImageExample({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = MagicTheme.of(context);

    return Wrap(
      spacing: theme.spacing.md,
      runSpacing: theme.spacing.md,
      children: [
        MagicImage(
          src: 'https://picsum.photos/200/140',
          width: 140,
          height: 96,
          borderRadius: BorderRadius.circular(theme.radius.sm),
        ),
        MagicImage(
          src: 'https://invalid-url.xyz/404.png',
          width: 140,
          height: 96,
          borderRadius: BorderRadius.circular(theme.radius.sm),
        ),
      ],
    );
  }
}
