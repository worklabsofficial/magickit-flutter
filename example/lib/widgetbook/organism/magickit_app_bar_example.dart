import 'package:flutter/material.dart';
import 'package:magickit/magickit.dart';

class MagicKitAppBarExample extends StatelessWidget {
  const MagicKitAppBarExample({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = MagicTheme.of(context);

    return ClipRRect(
      borderRadius: BorderRadius.circular(theme.radius.md),
      child: Material(
        color: theme.colors.surface,
        child: SizedBox(
          height: kToolbarHeight,
          child: MagicAppBar(
            title: 'Preview AppBar',
            showBorder: false,
            actions: [
              IconButton(
                onPressed: () {},
                icon: const MagicIcon(Icons.search),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
