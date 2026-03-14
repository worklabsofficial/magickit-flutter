import 'package:flutter/material.dart';
import 'package:magickit/magickit.dart';

class MagicKitIconExample extends StatelessWidget {
  const MagicKitIconExample({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = MagicTheme.of(context);

    return Wrap(
      spacing: theme.spacing.md,
      children: [
        const MagicIcon(Icons.home_outlined),
        MagicIcon(Icons.search, color: theme.colors.primary),
        const MagicIcon(Icons.favorite_outline, color: Colors.red),
        const MagicIcon(Icons.settings_outlined),
        const MagicIcon(Icons.notifications_outlined, size: 32),
      ],
    );
  }
}
