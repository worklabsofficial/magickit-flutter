import 'package:flutter/material.dart';
import 'package:magickit/magickit.dart';

class MagicKitTooltipExample extends StatelessWidget {
  const MagicKitTooltipExample({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = MagicTheme.of(context);

    return Row(
      children: [
        MagicTooltip(
          message: 'Create a new item',
          child: MagicButton(
            label: 'Hover me',
            onPressed: () {},
            variant: MagicButtonVariant.outlined,
          ),
        ),
        SizedBox(width: theme.spacing.md),
        MagicTooltip(
          message: 'Settings',
          child: IconButton(
            onPressed: () {},
            icon: const MagicIcon(Icons.settings_outlined),
          ),
        ),
      ],
    );
  }
}
