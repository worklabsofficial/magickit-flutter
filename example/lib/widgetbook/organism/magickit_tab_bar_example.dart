import 'package:flutter/material.dart';
import 'package:magickit/magickit.dart';

class MagicKitTabBarExample extends StatelessWidget {
  const MagicKitTabBarExample({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = MagicTheme.of(context);

    return ClipRRect(
      borderRadius: BorderRadius.circular(theme.radius.md),
      child: Material(
        color: theme.colors.surface,
        child: DefaultTabController(
          length: 3,
          child: Builder(
            builder: (context) {
              final controller = DefaultTabController.of(context)!;
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  MagicTabBar(
                    controller: controller,
                    isScrollable: true,
                    tabs: const [
                      MagicTab(label: 'Overview', icon: Icons.grid_view_outlined),
                      MagicTab(label: 'Tokens', icon: Icons.color_lens_outlined),
                      MagicTab(label: 'Docs', icon: Icons.article_outlined),
                    ],
                  ),
                  SizedBox(
                    height: 84,
                    child: TabBarView(
                      controller: controller,
                      children: const [
                        Center(
                          child: MagicText(
                            'Overview content',
                            style: MagicTextStyle.bodySmall,
                          ),
                        ),
                        Center(
                          child: MagicText(
                            'Tokens content',
                            style: MagicTextStyle.bodySmall,
                          ),
                        ),
                        Center(
                          child: MagicText(
                            'Docs content',
                            style: MagicTextStyle.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
