import 'package:flutter/material.dart';
import '../tokens/magic_theme.dart';

/// Variant tampilan slider.
enum MagicSliderVariant {
  /// Standard slider
  standard,

  /// Discrete dengan tick marks
  discrete,
}

/// {@magickit}
/// name: MagicSlider
/// category: atom
/// use_case: Slider untuk input range angka seperti volume, harga, rating, filter
/// visual_keywords: slider, range, input, volume, price, filter, drag, thumb
/// {@end}
class MagicSlider extends StatelessWidget {
  /// Nilai slider saat ini.
  final double value;

  /// Nilai minimum.
  final double min;

  /// Nilai maksimum.
  final double max;

  /// Langkah increment untuk discrete slider.
  final double? step;

  /// Callback saat value berubah.
  final ValueChanged<double>? onChanged;

  /// Callback saat user selesai drag.
  final ValueChanged<double>? onChangeEnd;

  /// Variant tampilan.
  final MagicSliderVariant variant;

  /// Tampilkan label value di atas thumb.
  final bool showValue;

  /// Format custom untuk label value.
  final String Function(double value)? valueFormatter;

  /// Label di kiri slider.
  final String? label;

  /// Label di bawah min.
  final String? minLabel;

  /// Label di bawah max.
  final String? maxLabel;

  /// Warna aktif (filled track).
  final Color? activeColor;

  /// Warna inaktif (unfilled track).
  final Color? inactiveColor;

  /// Ukuran thumb.
  final double thumbRadius;

  /// Tinggi track.
  final double trackHeight;

  /// Enabled/disabled state.
  final bool enabled;

  /// Divisions untuk discrete slider.
  final int? divisions;

  const MagicSlider({
    super.key,
    required this.value,
    this.min = 0.0,
    this.max = 1.0,
    this.step,
    this.onChanged,
    this.onChangeEnd,
    this.variant = MagicSliderVariant.standard,
    this.showValue = false,
    this.valueFormatter,
    this.label,
    this.minLabel,
    this.maxLabel,
    this.activeColor,
    this.inactiveColor,
    this.thumbRadius = 10.0,
    this.trackHeight = 4.0,
    this.enabled = true,
    this.divisions,
  });

  @override
  Widget build(BuildContext context) {
    final theme = MagicTheme.of(context);
    final resolvedActiveColor = activeColor ?? theme.colors.primary;
    final resolvedInactiveColor = inactiveColor ?? theme.colors.disabled;
    final resolvedDivisions =
        divisions ?? (step != null ? ((max - min) / step!).round() : null);

    final slider = SliderTheme(
      data: SliderThemeData(
        trackHeight: trackHeight,
        activeTrackColor: resolvedActiveColor,
        inactiveTrackColor: resolvedInactiveColor,
        thumbColor: resolvedActiveColor,
        overlayColor: resolvedActiveColor.withValues(alpha: 0.12),
        thumbShape: RoundSliderThumbShape(enabledThumbRadius: thumbRadius),
        trackShape: const RoundedRectSliderTrackShape(),
        valueIndicatorColor: resolvedActiveColor,
        valueIndicatorTextStyle: theme.typography.label.copyWith(
          color: Colors.white,
        ),
        showValueIndicator:
            showValue ? ShowValueIndicator.onDrag : ShowValueIndicator.never,
      ),
      child: Slider(
        value: value.clamp(min, max),
        min: min,
        max: max,
        divisions: resolvedDivisions,
        onChanged: enabled ? onChanged : null,
        onChangeEnd: onChangeEnd,
        label: showValue
            ? (valueFormatter?.call(value) ?? value.toStringAsFixed(1))
            : null,
      ),
    );

    final children = <Widget>[];

    if (label != null) {
      children.add(
        Text(
          label!,
          style: theme.typography.bodyMedium.copyWith(
            color: theme.colors.onSurface,
          ),
        ),
      );
      children.add(SizedBox(height: theme.spacing.xs));
    }

    children.add(slider);

    if (minLabel != null || maxLabel != null) {
      children.add(SizedBox(height: theme.spacing.xs));
      children.add(
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              minLabel ?? '',
              style: theme.typography.caption.copyWith(
                color: theme.colors.disabledForeground,
              ),
            ),
            Text(
              maxLabel ?? '',
              style: theme.typography.caption.copyWith(
                color: theme.colors.disabledForeground,
              ),
            ),
          ],
        ),
      );
    }

    if (children.length == 1) return slider;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    );
  }
}

/// {@magickit}
/// name: MagicRangeSlider
/// category: atom
/// use_case: Slider range untuk memilih minimum dan maksimum, cocok untuk filter harga
/// visual_keywords: range, slider, min, max, filter, price range, dual thumb
/// {@end}
class MagicRangeSlider extends StatelessWidget {
  /// Nilai range saat ini.
  final RangeValues values;

  /// Nilai minimum.
  final double min;

  /// Nilai maksimum.
  final double max;

  /// Callback saat value berubah.
  final ValueChanged<RangeValues>? onChanged;

  /// Callback saat user selesai drag.
  final ValueChanged<RangeValues>? onChangeEnd;

  /// Tampilkan label di atas thumbs.
  final bool showLabels;

  /// Format custom untuk labels.
  final String Function(double value)? labelFormatter;

  /// Label di atas slider.
  final String? label;

  /// Warna aktif (filled track).
  final Color? activeColor;

  /// Warna inaktif (unfilled track).
  final Color? inactiveColor;

  /// Enabled/disabled state.
  final bool enabled;

  /// Divisions untuk discrete slider.
  final int? divisions;

  const MagicRangeSlider({
    super.key,
    required this.values,
    this.min = 0.0,
    this.max = 1.0,
    this.onChanged,
    this.onChangeEnd,
    this.showLabels = false,
    this.labelFormatter,
    this.label,
    this.activeColor,
    this.inactiveColor,
    this.enabled = true,
    this.divisions,
  });

  @override
  Widget build(BuildContext context) {
    final theme = MagicTheme.of(context);
    final resolvedActiveColor = activeColor ?? theme.colors.primary;
    final resolvedInactiveColor = inactiveColor ?? theme.colors.disabled;

    final slider = SliderTheme(
      data: SliderThemeData(
        trackHeight: 4.0,
        activeTrackColor: resolvedActiveColor,
        inactiveTrackColor: resolvedInactiveColor,
        thumbColor: resolvedActiveColor,
        overlayColor: resolvedActiveColor.withValues(alpha: 0.12),
        rangeThumbShape: const RoundRangeSliderThumbShape(),
        showValueIndicator:
            showLabels ? ShowValueIndicator.onDrag : ShowValueIndicator.never,
      ),
      child: RangeSlider(
        values: RangeValues(
          values.start.clamp(min, max),
          values.end.clamp(min, max),
        ),
        min: min,
        max: max,
        divisions: divisions,
        onChanged: enabled ? onChanged : null,
        onChangeEnd: onChangeEnd,
        labels: showLabels
            ? RangeLabels(
                labelFormatter?.call(values.start) ??
                    values.start.toStringAsFixed(1),
                labelFormatter?.call(values.end) ??
                    values.end.toStringAsFixed(1),
              )
            : null,
      ),
    );

    if (label == null) return slider;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label!,
          style: theme.typography.bodyMedium.copyWith(
            color: theme.colors.onSurface,
          ),
        ),
        SizedBox(height: theme.spacing.xs),
        slider,
      ],
    );
  }
}
