import 'package:flutter/material.dart';
import 'package:magickit/magickit.dart';

class MagicKitProgressExample extends StatefulWidget {
  const MagicKitProgressExample({super.key});

  @override
  State<MagicKitProgressExample> createState() =>
      _MagicKitProgressExampleState();
}

class _MagicKitProgressExampleState extends State<MagicKitProgressExample> {
  double _progress = 0.65;

  @override
  Widget build(BuildContext context) {
    final theme = MagicTheme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const MagicText('Linear Progress', style: MagicTextStyle.label),
        SizedBox(height: theme.spacing.sm),
        const MagicProgress(value: 0.4),
        SizedBox(height: theme.spacing.md),
        const MagicText('With Label', style: MagicTextStyle.label),
        SizedBox(height: theme.spacing.sm),
        MagicProgress(
          value: _progress,
          showLabel: true,
          label: '${(_progress * 100).round()}% loaded',
        ),
        SizedBox(height: theme.spacing.sm),
        Slider(
          value: _progress,
          onChanged: (value) => setState(() => _progress = value),
        ),
        SizedBox(height: theme.spacing.md),
        const MagicText('Variants', style: MagicTextStyle.label),
        SizedBox(height: theme.spacing.sm),
        const MagicText('Solid', style: MagicTextStyle.caption),
        const MagicProgress(value: 0.6, variant: MagicProgressVariant.solid),
        SizedBox(height: theme.spacing.sm),
        const MagicText('Outlined', style: MagicTextStyle.caption),
        const MagicProgress(value: 0.6, variant: MagicProgressVariant.outlined),
        SizedBox(height: theme.spacing.sm),
        const MagicText('Gradient', style: MagicTextStyle.caption),
        const MagicProgress(value: 0.6, variant: MagicProgressVariant.gradient),
        SizedBox(height: theme.spacing.md),
        const MagicText('Indeterminate', style: MagicTextStyle.label),
        SizedBox(height: theme.spacing.sm),
        const MagicProgress.indeterminate(),
        SizedBox(height: theme.spacing.md),
        const MagicText('Circular', style: MagicTextStyle.label),
        SizedBox(height: theme.spacing.sm),
        Row(
          children: [
            const MagicProgress(
              type: MagicProgressType.circular,
              value: null,
            ),
            SizedBox(width: theme.spacing.lg),
            const MagicProgress(
              type: MagicProgressType.circular,
              value: 0.75,
              showLabel: true,
            ),
            SizedBox(width: theme.spacing.lg),
            const MagicProgress(
              type: MagicProgressType.circular,
              value: 0.5,
              size: 60,
              color: Color(0xFF10B981),
              showLabel: true,
            ),
          ],
        ),
      ],
    );
  }
}
