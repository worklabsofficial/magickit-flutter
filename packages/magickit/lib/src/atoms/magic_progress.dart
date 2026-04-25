import 'package:flutter/material.dart';
import '../tokens/magic_theme.dart';

/// Tipe progress indicator.
enum MagicProgressType {
  /// Linear progress bar
  linear,

  /// Circular progress indicator
  circular,
}

/// Variant tampilan progress.
enum MagicProgressVariant {
  /// Solid bar dengan primary color
  solid,

  /// Outlined/track style
  outlined,

  /// Gradient effect
  gradient,
}

/// {@magickit}
/// name: MagicProgress
/// category: atom
/// use_case: Loading indicator linear/circular dengan percentage, determinate/indeterminate mode
/// visual_keywords: progress, loading, indicator, bar, spinner, circular, linear, percentage
/// {@end}
class MagicProgress extends StatelessWidget {
  /// Nilai progress 0.0 - 1.0. Null = indeterminate mode.
  final double? value;

  /// Tipe progress: linear atau circular.
  final MagicProgressType type;

  /// Variant tampilan.
  final MagicProgressVariant variant;

  /// Tinggi untuk linear progress (default: 6).
  final double? height;

  /// Ukuran untuk circular progress (default: 40).
  final double? size;

  /// Ketebalan stroke untuk circular progress.
  final double strokeWidth;

  /// Warna track/background.
  final Color? backgroundColor;

  /// Warna progress indicator.
  final Color? color;

  /// Tampilkan label percentage.
  final bool showLabel;

  /// Custom label. Jika null dan showLabel=true, tampilkan percentage.
  final String? label;

  /// Style untuk label text.
  final TextStyle? labelStyle;

  /// Border radius untuk linear progress.
  final BorderRadius? borderRadius;

  /// Animasi duration untuk perubahan value.
  final Duration animationDuration;

  /// Animation curve.
  final Curve animationCurve;

  const MagicProgress({
    super.key,
    this.value,
    this.type = MagicProgressType.linear,
    this.variant = MagicProgressVariant.solid,
    this.height,
    this.size,
    this.strokeWidth = 4.0,
    this.backgroundColor,
    this.color,
    this.showLabel = false,
    this.label,
    this.labelStyle,
    this.borderRadius,
    this.animationDuration = const Duration(milliseconds: 300),
    this.animationCurve = Curves.easeInOut,
  });

  /// Indeterminate linear progress (tanpa value).
  const MagicProgress.indeterminate({
    super.key,
    this.type = MagicProgressType.linear,
    this.variant = MagicProgressVariant.solid,
    this.height,
    this.size,
    this.strokeWidth = 4.0,
    this.backgroundColor,
    this.color,
    this.borderRadius,
    this.animationDuration = const Duration(milliseconds: 300),
    this.animationCurve = Curves.easeInOut,
  })  : value = null,
        showLabel = false,
        label = null,
        labelStyle = null;

  @override
  Widget build(BuildContext context) {
    final theme = MagicTheme.of(context);
    final resolvedColor = color ?? theme.colors.primary;
    final resolvedBgColor = backgroundColor ?? theme.colors.disabled;
    final resolvedRadius =
        borderRadius ?? BorderRadius.circular(theme.radius.full);

    if (type == MagicProgressType.circular) {
      return _buildCircular(theme, resolvedColor, resolvedBgColor);
    }

    return _buildLinear(theme, resolvedColor, resolvedBgColor, resolvedRadius);
  }

  Widget _buildLinear(
    MagicTheme theme,
    Color resolvedColor,
    Color resolvedBgColor,
    BorderRadius resolvedRadius,
  ) {
    final resolvedHeight = height ?? 6.0;
    final effectiveValue = value?.clamp(0.0, 1.0);

    Widget progressBar;

    if (variant == MagicProgressVariant.gradient) {
      progressBar = ClipRRect(
        borderRadius: resolvedRadius,
        child: LinearProgressIndicator(
          value: effectiveValue,
          minHeight: resolvedHeight,
          backgroundColor: resolvedBgColor,
          valueColor: AlwaysStoppedAnimation(resolvedColor),
        ),
      );
    } else {
      progressBar = ClipRRect(
        borderRadius: resolvedRadius,
        child: LinearProgressIndicator(
          value: effectiveValue,
          minHeight: resolvedHeight,
          backgroundColor: variant == MagicProgressVariant.outlined
              ? Colors.transparent
              : resolvedBgColor,
          valueColor: AlwaysStoppedAnimation(resolvedColor),
        ),
      );

      if (variant == MagicProgressVariant.outlined) {
        progressBar = Container(
          height: resolvedHeight,
          decoration: BoxDecoration(
            border: Border.all(color: resolvedBgColor, width: 1),
            borderRadius: resolvedRadius,
          ),
          child: progressBar,
        );
      }
    }

    if (!showLabel) return progressBar;

    final percentage = ((effectiveValue ?? 0) * 100).round();
    final displayLabel = label ?? '$percentage%';

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        progressBar,
        SizedBox(height: theme.spacing.xs),
        Text(
          displayLabel,
          style: labelStyle ??
              theme.typography.caption.copyWith(
                color: theme.colors.onSurface,
              ),
          textAlign: TextAlign.end,
        ),
      ],
    );
  }

  Widget _buildCircular(
    MagicTheme theme,
    Color resolvedColor,
    Color resolvedBgColor,
  ) {
    final resolvedSize = size ?? 40.0;
    final effectiveValue = value?.clamp(0.0, 1.0);

    final indicator = SizedBox(
      width: resolvedSize,
      height: resolvedSize,
      child: CircularProgressIndicator(
        value: effectiveValue,
        strokeWidth: strokeWidth,
        backgroundColor: resolvedBgColor,
        valueColor: AlwaysStoppedAnimation(resolvedColor),
      ),
    );

    if (!showLabel) return indicator;

    final percentage = ((effectiveValue ?? 0) * 100).round();
    final displayLabel = label ?? '$percentage%';

    return SizedBox(
      width: resolvedSize,
      height: resolvedSize,
      child: Stack(
        alignment: Alignment.center,
        children: [
          indicator,
          Text(
            displayLabel,
            style: labelStyle ??
                theme.typography.label.copyWith(
                  color: theme.colors.onSurface,
                ),
          ),
        ],
      ),
    );
  }
}
