import 'package:flutter/material.dart';
import '../tokens/magic_theme.dart';

/// Tipe tampilan rating.
enum MagicRatingType {
  /// Star icons
  stars,

  /// Heart icons
  hearts,

  /// Thumbs up icons
  thumbs,
}

/// {@magickit}
/// name: MagicRating
/// category: molecule
/// use_case: Star rating untuk review, feedback, dan evaluasi produk/layanan
/// visual_keywords: rating, star, review, feedback, score, bintang, nilai
/// {@end}
class MagicRating extends StatelessWidget {
  /// Nilai rating saat ini (0.0 - max).
  final double value;

  /// Nilai rating maksimal (default: 5).
  final double max;

  /// Callback saat rating diubah (null = read-only).
  final ValueChanged<double>? onChanged;

  /// Ukuran icon.
  final double iconSize;

  /// Jarak antar icon.
  final double spacing;

  /// Warna icon saat filled/active.
  final Color? activeColor;

  /// Warna icon saat inactive.
  final Color? inactiveColor;

  /// Tipe icon rating.
  final MagicRatingType type;

  /// Izinkan half rating (0.5 increment).
  final bool allowHalfRating;

  /// Tampilkan label nilai di samping.
  final bool showValue;

  /// Custom formatter untuk label.
  final String Function(double value)? valueFormatter;

  /// Animasi saat rating berubah.
  final bool animate;

  /// Readonly mode (tanpa interaksi).
  final bool readOnly;

  /// Item count untuk tampilan ringkas (e.g., "(128 reviews)").
  final int? itemCount;

  /// Label untuk itemCount.
  final String itemLabel;

  const MagicRating({
    super.key,
    this.value = 0.0,
    this.max = 5.0,
    this.onChanged,
    this.iconSize = 24,
    this.spacing = 4,
    this.activeColor,
    this.inactiveColor,
    this.type = MagicRatingType.stars,
    this.allowHalfRating = false,
    this.showValue = false,
    this.valueFormatter,
    this.animate = true,
    this.readOnly = false,
    this.itemCount,
    this.itemLabel = 'reviews',
  });

  /// Rating display only (tidak bisa diinteraksi).
  const MagicRating.display({
    super.key,
    required this.value,
    this.max = 5.0,
    this.iconSize = 16,
    this.spacing = 2,
    this.activeColor,
    this.inactiveColor,
    this.type = MagicRatingType.stars,
    this.allowHalfRating = false,
    this.showValue = true,
    this.valueFormatter,
    this.itemCount,
    this.itemLabel = 'reviews',
  })  : onChanged = null,
        animate = false,
        readOnly = true;

  IconData get _iconData => switch (type) {
        MagicRatingType.stars => Icons.star_rounded,
        MagicRatingType.hearts => Icons.favorite_rounded,
        MagicRatingType.thumbs => Icons.thumb_up_rounded,
      };

  @override
  Widget build(BuildContext context) {
    final theme = MagicTheme.of(context);
    final resolvedActiveColor = activeColor ?? Colors.amber;
    final resolvedInactiveColor = inactiveColor ?? theme.colors.disabled;
    final isInteractive = onChanged != null && !readOnly;

    final clampedValue = value.clamp(0.0, max);

    final children = <Widget>[
      Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(max.toInt(), (index) {
          final iconValue = index + 1.0;
          final fillAmount = (clampedValue - index).clamp(0.0, 1.0);

          return GestureDetector(
            onTap: isInteractive ? () => onChanged!(iconValue) : null,
            onHorizontalDragUpdate: isInteractive
                ? (details) {
                    final box = context.findRenderObject() as RenderBox;
                    final local = box.globalToLocal(details.globalPosition);
                    final rating = (local.dx / (iconSize + spacing))
                        .clamp(0.0, max)
                        .toDouble();
                    final rounded = allowHalfRating
                        ? (rating * 2).roundToDouble() / 2
                        : rating.roundToDouble();
                    onChanged!(rounded.clamp(0.0, max));
                  }
                : null,
            child: Padding(
              padding: EdgeInsets.only(
                right: index < max.toInt() - 1 ? spacing : 0,
              ),
              child: _buildIcon(
                fillAmount: fillAmount,
                activeColor: resolvedActiveColor,
                inactiveColor: resolvedInactiveColor,
              ),
            ),
          );
        }),
      ),
    ];

    if (showValue) {
      final displayValue =
          valueFormatter?.call(clampedValue) ?? clampedValue.toStringAsFixed(1);
      children.add(SizedBox(width: spacing * 2));
      children.add(
        Text(
          displayValue,
          style: theme.typography.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colors.onSurface,
          ),
        ),
      );
    }

    if (itemCount != null) {
      children.add(SizedBox(width: spacing));
      children.add(
        Text(
          '($itemCount $itemLabel)',
          style: theme.typography.caption.copyWith(
            color: theme.colors.disabledForeground,
          ),
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: children,
    );
  }

  Widget _buildIcon({
    required double fillAmount,
    required Color activeColor,
    required Color inactiveColor,
  }) {
    if (fillAmount >= 1.0) {
      return Icon(
        _iconData,
        size: iconSize,
        color: activeColor,
      );
    }

    if (fillAmount <= 0.0) {
      return Icon(
        _iconData,
        size: iconSize,
        color: inactiveColor,
      );
    }

    // Partial fill
    return ShaderMask(
      shaderCallback: (bounds) {
        return LinearGradient(
          stops: [fillAmount, fillAmount],
          colors: [activeColor, inactiveColor],
        ).createShader(bounds);
      },
      child: Icon(
        _iconData,
        size: iconSize,
        color: Colors.white,
      ),
    );
  }
}
