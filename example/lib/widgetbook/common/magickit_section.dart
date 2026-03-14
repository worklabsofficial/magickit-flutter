import 'package:flutter/material.dart';
import 'package:magickit/magickit.dart';

class MagicKitSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const MagicKitSection({
    super.key,
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final theme = MagicTheme.of(context);
    return Container(
      margin: EdgeInsets.only(bottom: theme.spacing.lg),
      padding: EdgeInsets.all(theme.spacing.md),
      decoration: BoxDecoration(
        color: theme.colors.surface,
        borderRadius: BorderRadius.circular(theme.radius.md),
        boxShadow: theme.shadows.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MagicText(title, style: MagicTextStyle.h6),
          Divider(height: theme.spacing.lg, color: theme.colors.outline),
          ...children,
        ],
      ),
    );
  }
}
