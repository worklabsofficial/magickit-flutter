import 'package:flutter/material.dart';
import 'package:magickit/magickit.dart';

class MagicKitCarouselExample extends StatefulWidget {
  const MagicKitCarouselExample({super.key});

  @override
  State<MagicKitCarouselExample> createState() =>
      _MagicKitCarouselExampleState();
}

class _MagicKitCarouselExampleState extends State<MagicKitCarouselExample> {
  int _currentPage = 0;

  static const _colors = [
    Color(0xFF2D4AF5),
    Color(0xFF10B981),
    Color(0xFFF59E0B),
    Color(0xFFEF4444),
    Color(0xFF8B5CF6),
  ];

  static const _labels = [
    'Welcome',
    'Features',
    'Design',
    'Fast',
    'Ready!',
  ];

  List<Widget> _buildItems() {
    return List.generate(5, (index) {
      return Container(
        decoration: BoxDecoration(
          color: _colors[index],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.star_rounded, size: 48, color: Colors.white),
              const SizedBox(height: 8),
              Text(
                _labels[index],
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = MagicTheme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const MagicText('Default Carousel', style: MagicTextStyle.label),
        SizedBox(height: theme.spacing.sm),
        MagicCarousel(
          items: _buildItems(),
          height: 160,
          onPageChanged: (index) => setState(() => _currentPage = index),
        ),
        SizedBox(height: theme.spacing.sm),
        MagicText('Current page: ${_currentPage + 1}/5',
            style: MagicTextStyle.caption),
        SizedBox(height: theme.spacing.md),
        const MagicText('Banner (Auto-play, Infinite)',
            style: MagicTextStyle.label),
        SizedBox(height: theme.spacing.sm),
        MagicCarousel.banner(items: _buildItems()),
        SizedBox(height: theme.spacing.md),
        const MagicText('Gallery (Viewport Preview)',
            style: MagicTextStyle.label),
        SizedBox(height: theme.spacing.sm),
        MagicCarousel.gallery(items: _buildItems()),
        SizedBox(height: theme.spacing.md),
        const MagicText('With Arrows', style: MagicTextStyle.label),
        SizedBox(height: theme.spacing.sm),
        MagicCarousel(
          items: _buildItems(),
          height: 160,
          showArrows: true,
          indicatorType: MagicCarouselIndicatorType.numbers,
        ),
        SizedBox(height: theme.spacing.md),
        const MagicText('Line Indicators', style: MagicTextStyle.label),
        SizedBox(height: theme.spacing.sm),
        MagicCarousel(
          items: _buildItems(),
          height: 160,
          indicatorType: MagicCarouselIndicatorType.lines,
        ),
      ],
    );
  }
}
