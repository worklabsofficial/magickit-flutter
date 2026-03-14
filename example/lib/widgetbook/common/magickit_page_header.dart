import 'package:flutter/material.dart';
import 'package:magickit/magickit.dart';

class MagicKitPageHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const MagicKitPageHeader({
    super.key,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = MagicTheme.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: theme.spacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MagicText(title, style: MagicTextStyle.h4),
          SizedBox(height: theme.spacing.xs),
          MagicText(
            subtitle,
            style: MagicTextStyle.bodySmall,
            color: theme.colors.onSurface.withValues(alpha: 0.65),
          ),
        ],
      ),
    );
  }
}
