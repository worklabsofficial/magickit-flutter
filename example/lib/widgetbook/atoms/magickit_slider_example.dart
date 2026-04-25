import 'package:flutter/material.dart';
import 'package:magickit/magickit.dart';

class MagicKitSliderExample extends StatefulWidget {
  const MagicKitSliderExample({super.key});

  @override
  State<MagicKitSliderExample> createState() => _MagicKitSliderExampleState();
}

class _MagicKitSliderExampleState extends State<MagicKitSliderExample> {
  double _value = 0.5;
  double _volume = 70;
  RangeValues _priceRange = const RangeValues(20, 80);

  @override
  Widget build(BuildContext context) {
    final theme = MagicTheme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const MagicText('Standard Slider', style: MagicTextStyle.label),
        SizedBox(height: theme.spacing.sm),
        MagicSlider(
          value: _value,
          onChanged: (value) => setState(() => _value = value),
          showValue: true,
        ),
        SizedBox(height: theme.spacing.md),
        const MagicText('With Label', style: MagicTextStyle.label),
        SizedBox(height: theme.spacing.sm),
        MagicSlider(
          value: _volume,
          min: 0,
          max: 100,
          onChanged: (value) => setState(() => _volume = value),
          label: 'Volume',
          minLabel: '0',
          maxLabel: '100',
          valueFormatter: (v) => '${v.round()}%',
          showValue: true,
        ),
        SizedBox(height: theme.spacing.md),
        const MagicText('Discrete (step=10)', style: MagicTextStyle.label),
        SizedBox(height: theme.spacing.sm),
        MagicSlider(
          value: _value,
          onChanged: (value) => setState(() => _value = value),
          divisions: 10,
          showValue: true,
        ),
        SizedBox(height: theme.spacing.md),
        const MagicText('Disabled', style: MagicTextStyle.label),
        SizedBox(height: theme.spacing.sm),
        const MagicSlider(value: 0.3, enabled: false),
        SizedBox(height: theme.spacing.md),
        const MagicText('Range Slider', style: MagicTextStyle.label),
        SizedBox(height: theme.spacing.sm),
        MagicRangeSlider(
          values: _priceRange,
          min: 0,
          max: 100,
          onChanged: (value) => setState(() => _priceRange = value),
          label: 'Price Range',
          showLabels: true,
          labelFormatter: (v) => '\$${v.round()}',
        ),
        SizedBox(height: theme.spacing.sm),
        MagicText(
          'Selected: \$${_priceRange.start.round()} - \$${_priceRange.end.round()}',
          style: MagicTextStyle.caption,
        ),
      ],
    );
  }
}
