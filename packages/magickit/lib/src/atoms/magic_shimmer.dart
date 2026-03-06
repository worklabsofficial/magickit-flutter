import 'package:flutter/material.dart';
import '../tokens/magic_theme.dart';

/// {@magickit}
/// name: MagicShimmer
/// category: atom
/// use_case: Loading placeholder dengan animasi shimmer untuk skeleton screen
/// visual_keywords: shimmer, skeleton, loading, placeholder, loading state
/// {@end}
class MagicShimmer extends StatefulWidget {
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;

  const MagicShimmer({
    super.key,
    this.width,
    this.height,
    this.borderRadius,
  });

  @override
  State<MagicShimmer> createState() => _MagicShimmerState();
}

class _MagicShimmerState extends State<MagicShimmer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = MagicTheme.of(context);
    final base = theme.colors.disabled;
    final highlight = theme.colors.surface;

    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius:
                widget.borderRadius ?? BorderRadius.circular(theme.radius.sm),
            gradient: LinearGradient(
              colors: [base, highlight, base],
              stops: const [0.0, 0.5, 1.0],
              transform: _SlidingGradientTransform(_controller.value),
            ),
          ),
        );
      },
    );
  }
}

class _SlidingGradientTransform extends GradientTransform {
  final double value;

  const _SlidingGradientTransform(this.value);

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    // Slide the gradient from -width to +width
    final dx = bounds.width * 2 * (value - 0.5);
    return Matrix4.translationValues(dx, 0, 0);
  }
}
