import 'package:flutter/material.dart';
import 'package:magickit/magickit.dart';

class MagicKitAvatarExample extends StatelessWidget {
  const MagicKitAvatarExample({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = MagicTheme.of(context);

    return Wrap(
      spacing: theme.spacing.md,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: const [
        MagicAvatar(fallbackInitial: 'Y', size: MagicAvatarSize.sm),
        MagicAvatar(fallbackInitial: 'U'),
        MagicAvatar(fallbackInitial: 'D', size: MagicAvatarSize.lg),
        MagicAvatar(
          imageUrl: 'https://i.pravatar.cc/150?img=3',
          size: MagicAvatarSize.md,
        ),
        MagicAvatar(
          imageUrl: 'https://invalid-url.xyz/broken.png',
          fallbackInitial: 'E',
        ),
      ],
    );
  }
}
