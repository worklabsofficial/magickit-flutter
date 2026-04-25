import 'package:flutter/material.dart';
import 'package:magickit/magickit.dart';

class MagicKitRatingExample extends StatefulWidget {
  const MagicKitRatingExample({super.key});

  @override
  State<MagicKitRatingExample> createState() => _MagicKitRatingExampleState();
}

class _MagicKitRatingExampleState extends State<MagicKitRatingExample> {
  double _rating = 3.5;
  double _hearts = 4.0;

  @override
  Widget build(BuildContext context) {
    final theme = MagicTheme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const MagicText('Interactive Rating', style: MagicTextStyle.label),
        SizedBox(height: theme.spacing.sm),
        MagicRating(
          value: _rating,
          onChanged: (value) => setState(() => _rating = value),
          allowHalfRating: true,
          showValue: true,
        ),
        SizedBox(height: theme.spacing.sm),
        MagicText(
          'Rating: $_rating',
          style: MagicTextStyle.caption,
        ),
        SizedBox(height: theme.spacing.md),
        const MagicText('Read Only', style: MagicTextStyle.label),
        SizedBox(height: theme.spacing.sm),
        const MagicRating(
          value: 4.5,
          readOnly: true,
          showValue: true,
          itemCount: 128,
        ),
        SizedBox(height: theme.spacing.md),
        const MagicText('Display (compact)', style: MagicTextStyle.label),
        SizedBox(height: theme.spacing.sm),
        const MagicRating.display(
          value: 4.2,
          itemCount: 1024,
          itemLabel: 'reviews',
        ),
        SizedBox(height: theme.spacing.md),
        const MagicText('Hearts', style: MagicTextStyle.label),
        SizedBox(height: theme.spacing.sm),
        MagicRating(
          value: _hearts,
          type: MagicRatingType.hearts,
          onChanged: (value) => setState(() => _hearts = value),
          activeColor: Colors.redAccent,
        ),
        SizedBox(height: theme.spacing.md),
        const MagicText('Thumbs', style: MagicTextStyle.label),
        SizedBox(height: theme.spacing.sm),
        MagicRating(
          value: 3.0,
          type: MagicRatingType.thumbs,
          readOnly: true,
          activeColor: theme.colors.primary,
        ),
        SizedBox(height: theme.spacing.md),
        const MagicText('Custom Size', style: MagicTextStyle.label),
        SizedBox(height: theme.spacing.sm),
        const MagicRating(
          value: 4.0,
          readOnly: true,
          iconSize: 32,
          spacing: 8,
        ),
      ],
    );
  }
}
