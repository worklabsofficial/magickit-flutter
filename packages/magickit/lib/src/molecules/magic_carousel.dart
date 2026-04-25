import 'dart:async';
import 'package:flutter/material.dart';
import '../tokens/magic_theme.dart';

/// Tipe indicator untuk carousel.
enum MagicCarouselIndicatorType {
  /// Dot kecil
  dots,

  /// Garis horizontal
  lines,

  /// Angka (1/5)
  numbers,

  /// Tanpa indicator
  none,
}

/// {@magickit}
/// name: MagicCarousel
/// category: molecule
/// use_case: Image slider, content carousel, banner rotator, onboarding screens
/// visual_keywords: carousel, slider, swiper, banner, gallery, image slider, page view
/// {@end}
class MagicCarousel extends StatefulWidget {
  /// Daftar item yang ditampilkan.
  final List<Widget> items;

  /// Controller opsional untuk mengontrol page.
  final PageController? controller;

  /// Callback saat page berubah.
  final ValueChanged<int>? onPageChanged;

  /// Auto-play interval. Null = tidak auto-play.
  final Duration? autoPlayInterval;

  /// Animation duration untuk transition.
  final Duration animationDuration;

  /// Tinggi carousel.
  final double height;

  /// Aspect ratio (jika height tidak diset).
  final double? aspectRatio;

  /// Viewport fraction (berapa banyak item terlihat).
  final double viewportFraction;

  /// Enable infinite loop.
  final bool infiniteScroll;

  /// Padding di kiri-kanan.
  final EdgeInsetsGeometry? padding;

  /// Tipe indicator.
  final MagicCarouselIndicatorType indicatorType;

  /// Posisi indicator.
  final AlignmentGeometry indicatorAlignment;

  /// Warna indicator aktif.
  final Color? activeIndicatorColor;

  /// Warna indicator inaktif.
  final Color? inactiveIndicatorColor;

  /// Jarak antar indicator dots.
  final double indicatorSpacing;

  /// Tampilkan arrow navigation (kiri/kanan).
  final bool showArrows;

  /// Widget yang ditampilkan saat di-tap.
  final ValueChanged<int>? onTap;

  /// Clip behavior.
  final Clip clipBehavior;

  const MagicCarousel({
    super.key,
    required this.items,
    this.controller,
    this.onPageChanged,
    this.autoPlayInterval,
    this.animationDuration = const Duration(milliseconds: 300),
    this.height = 200,
    this.aspectRatio,
    this.viewportFraction = 1.0,
    this.infiniteScroll = false,
    this.padding,
    this.indicatorType = MagicCarouselIndicatorType.dots,
    this.indicatorAlignment = Alignment.bottomCenter,
    this.activeIndicatorColor,
    this.inactiveIndicatorColor,
    this.indicatorSpacing = 8.0,
    this.showArrows = false,
    this.onTap,
    this.clipBehavior = Clip.hardEdge,
  });

  /// Banner carousel dengan aspect ratio 16:9.
  const MagicCarousel.banner({
    super.key,
    required this.items,
    this.controller,
    this.onPageChanged,
    this.autoPlayInterval = const Duration(seconds: 5),
    this.animationDuration = const Duration(milliseconds: 300),
    this.infiniteScroll = true,
    this.padding,
    this.activeIndicatorColor,
    this.inactiveIndicatorColor,
    this.onTap,
    this.clipBehavior = Clip.hardEdge,
  })  : height = 0,
        aspectRatio = 16 / 9,
        viewportFraction = 1.0,
        indicatorType = MagicCarouselIndicatorType.dots,
        indicatorAlignment = Alignment.bottomCenter,
        indicatorSpacing = 8.0,
        showArrows = false;

  /// Product gallery carousel dengan viewport preview.
  const MagicCarousel.gallery({
    super.key,
    required this.items,
    this.controller,
    this.onPageChanged,
    this.autoPlayInterval,
    this.animationDuration = const Duration(milliseconds: 300),
    this.height = 280,
    this.padding,
    this.activeIndicatorColor,
    this.inactiveIndicatorColor,
    this.onTap,
    this.clipBehavior = Clip.hardEdge,
  })  : aspectRatio = null,
        viewportFraction = 0.85,
        infiniteScroll = false,
        indicatorType = MagicCarouselIndicatorType.numbers,
        indicatorAlignment = Alignment.bottomRight,
        indicatorSpacing = 8.0,
        showArrows = false;

  @override
  State<MagicCarousel> createState() => _MagicCarouselState();
}

class _MagicCarouselState extends State<MagicCarousel> {
  late PageController _pageController;
  late int _currentPage;
  Timer? _autoPlayTimer;

  int get _itemCount => widget.items.length;

  @override
  void initState() {
    super.initState();
    _currentPage = 0;
    _pageController = widget.controller ??
        PageController(
          viewportFraction: widget.viewportFraction,
          initialPage: widget.infiniteScroll ? _itemCount * 100 : 0,
        );

    if (widget.autoPlayInterval != null) {
      _startAutoPlay();
    }
  }

  @override
  void dispose() {
    _autoPlayTimer?.cancel();
    if (widget.controller == null) {
      _pageController.dispose();
    }
    super.dispose();
  }

  void _startAutoPlay() {
    _autoPlayTimer?.cancel();
    _autoPlayTimer = Timer.periodic(widget.autoPlayInterval!, (_) {
      if (_pageController.hasClients) {
        final nextPage = _pageController.page!.round() + 1;
        _pageController.animateToPage(
          nextPage,
          duration: widget.animationDuration,
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void _onPageChanged(int index) {
    final actualIndex = widget.infiniteScroll ? index % _itemCount : index;
    setState(() {
      _currentPage = actualIndex;
    });
    widget.onPageChanged?.call(actualIndex);
  }

  @override
  Widget build(BuildContext context) {
    final theme = MagicTheme.of(context);
    final resolvedActiveColor =
        widget.activeIndicatorColor ?? theme.colors.primary;
    final resolvedInactiveColor =
        widget.inactiveIndicatorColor ?? theme.colors.disabled;

    final effectiveHeight = widget.aspectRatio != null
        ? MediaQuery.sizeOf(context).width / widget.aspectRatio!
        : widget.height;

    return SizedBox(
      height: effectiveHeight,
      child: Stack(
        alignment: widget.indicatorAlignment,
        children: [
          // PageView
          GestureDetector(
            onTapDown: widget.onTap != null
                ? (details) {
                    final tappedIndex = _currentPage;
                    widget.onTap!(tappedIndex);
                  }
                : null,
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: _onPageChanged,
              itemCount: widget.infiniteScroll ? null : _itemCount,
              itemBuilder: (context, index) {
                final actualIndex = index % _itemCount;
                return Padding(
                  padding: widget.padding ??
                      EdgeInsets.symmetric(
                        horizontal: widget.viewportFraction < 1.0
                            ? theme.spacing.sm
                            : 0,
                      ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(theme.radius.md),
                    child: widget.items[actualIndex],
                  ),
                );
              },
            ),
          ),

          // Arrows
          if (widget.showArrows && _itemCount > 1) ...[
            Positioned(
              left: theme.spacing.sm,
              top: 0,
              bottom: 0,
              child: _ArrowButton(
                icon: Icons.chevron_left_rounded,
                onPressed: () {
                  _pageController.previousPage(
                    duration: widget.animationDuration,
                    curve: Curves.easeInOut,
                  );
                },
                color: resolvedActiveColor,
              ),
            ),
            Positioned(
              right: theme.spacing.sm,
              top: 0,
              bottom: 0,
              child: _ArrowButton(
                icon: Icons.chevron_right_rounded,
                onPressed: () {
                  _pageController.nextPage(
                    duration: widget.animationDuration,
                    curve: Curves.easeInOut,
                  );
                },
                color: resolvedActiveColor,
              ),
            ),
          ],

          // Indicator
          if (widget.indicatorType != MagicCarouselIndicatorType.none &&
              _itemCount > 1)
            Positioned(
              bottom: theme.spacing.sm,
              child: _buildIndicator(
                resolvedActiveColor,
                resolvedInactiveColor,
                theme,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildIndicator(
    Color activeColor,
    Color inactiveColor,
    MagicTheme theme,
  ) {
    switch (widget.indicatorType) {
      case MagicCarouselIndicatorType.dots:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(_itemCount, (index) {
            final isActive = index == _currentPage;
            return AnimatedContainer(
              duration: theme.animations.fast,
              margin:
                  EdgeInsets.symmetric(horizontal: widget.indicatorSpacing / 2),
              width: isActive ? 20 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: isActive ? activeColor : inactiveColor,
                borderRadius: BorderRadius.circular(4),
              ),
            );
          }),
        );

      case MagicCarouselIndicatorType.lines:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(_itemCount, (index) {
            final isActive = index == _currentPage;
            return AnimatedContainer(
              duration: theme.animations.fast,
              margin:
                  EdgeInsets.symmetric(horizontal: widget.indicatorSpacing / 4),
              width: isActive ? 24 : 12,
              height: 3,
              decoration: BoxDecoration(
                color: isActive ? activeColor : inactiveColor,
                borderRadius: BorderRadius.circular(1.5),
              ),
            );
          }),
        );

      case MagicCarouselIndicatorType.numbers:
        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: theme.spacing.sm,
            vertical: theme.spacing.xs,
          ),
          decoration: BoxDecoration(
            color: Colors.black54,
            borderRadius: BorderRadius.circular(theme.radius.full),
          ),
          child: Text(
            '${_currentPage + 1}/$_itemCount',
            style: theme.typography.caption.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        );

      case MagicCarouselIndicatorType.none:
        return const SizedBox.shrink();
    }
  }
}

class _ArrowButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final Color color;

  const _ArrowButton({
    required this.icon,
    required this.onPressed,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.white.withValues(alpha: 0.9),
        shape: const CircleBorder(),
        elevation: 2,
        child: InkWell(
          onTap: onPressed,
          customBorder: const CircleBorder(),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Icon(icon, color: color, size: 20),
          ),
        ),
      ),
    );
  }
}
