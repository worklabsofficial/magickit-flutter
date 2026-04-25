import 'package:flutter/material.dart';

/// Design token untuk responsive breakpoints.
///
/// Memberikan konsistensi breakpoint across semua layout decisions.
///
/// ```dart
/// final breakpoint = MagicBreakpoints.of(context);
/// if (breakpoint.isMobile) {
///   return MobileLayout();
/// } else if (breakpoint.isTablet) {
///   return TabletLayout();
/// }
/// return DesktopLayout();
/// ```
class MagicBreakpoints {
  /// Maximum width untuk mobile layout (default: 480px)
  final double mobile;

  /// Maximum width untuk tablet layout (default: 768px)
  final double tablet;

  /// Maximum width untuk desktop layout (default: 1024px)
  final double desktop;

  /// Maximum width untuk wide desktop (default: 1440px)
  final double wide;

  const MagicBreakpoints({
    this.mobile = 480,
    this.tablet = 768,
    this.desktop = 1024,
    this.wide = 1440,
  });

  factory MagicBreakpoints.defaults() => const MagicBreakpoints();

  /// Resolve breakpoint type from screen width.
  MagicBreakpointType resolve(double width) {
    if (width <= mobile) return MagicBreakpointType.mobile;
    if (width <= tablet) return MagicBreakpointType.tablet;
    if (width <= desktop) return MagicBreakpointType.desktop;
    return MagicBreakpointType.wide;
  }

  /// Get current breakpoint type from context.
  static MagicBreakpointType typeOf(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return const MagicBreakpoints().resolve(width);
  }

  /// Check if current screen is mobile.
  static bool isMobile(BuildContext context) {
    return typeOf(context) == MagicBreakpointType.mobile;
  }

  /// Check if current screen is tablet.
  static bool isTablet(BuildContext context) {
    return typeOf(context) == MagicBreakpointType.tablet;
  }

  /// Check if current screen is desktop.
  static bool isDesktop(BuildContext context) {
    final type = typeOf(context);
    return type == MagicBreakpointType.desktop ||
        type == MagicBreakpointType.wide;
  }

  /// Check if current screen is wide desktop.
  static bool isWide(BuildContext context) {
    return typeOf(context) == MagicBreakpointType.wide;
  }

  /// Responsive value builder — returns different value based on breakpoint.
  ///
  /// ```dart
  /// final columns = MagicBreakpoints.responsive<int>(
  ///   context,
  ///   mobile: 1,
  ///   tablet: 2,
  ///   desktop: 3,
  ///   wide: 4,
  /// );
  /// ```
  static T responsive<T>(
    BuildContext context, {
    required T mobile,
    T? tablet,
    T? desktop,
    T? wide,
  }) {
    final type = typeOf(context);
    return switch (type) {
      MagicBreakpointType.mobile => mobile,
      MagicBreakpointType.tablet => tablet ?? mobile,
      MagicBreakpointType.desktop => desktop ?? tablet ?? mobile,
      MagicBreakpointType.wide => wide ?? desktop ?? tablet ?? mobile,
    };
  }

  /// Get grid columns count based on breakpoint.
  static int columns(BuildContext context, {int defaultColumns = 1}) {
    return responsive<int>(
      context,
      mobile: defaultColumns,
      tablet: (defaultColumns * 2).clamp(1, 6),
      desktop: (defaultColumns * 3).clamp(1, 8),
      wide: (defaultColumns * 4).clamp(1, 12),
    );
  }

  /// Get content max width based on breakpoint.
  static double contentMaxWidth(BuildContext context) {
    return responsive<double>(
      context,
      mobile: double.infinity,
      tablet: 600,
      desktop: 800,
      wide: 1000,
    );
  }

  MagicBreakpoints copyWith({
    double? mobile,
    double? tablet,
    double? desktop,
    double? wide,
  }) {
    return MagicBreakpoints(
      mobile: mobile ?? this.mobile,
      tablet: tablet ?? this.tablet,
      desktop: desktop ?? this.desktop,
      wide: wide ?? this.wide,
    );
  }
}

/// Breakpoint type enum.
enum MagicBreakpointType {
  /// Small phones — width <= 480px
  mobile,

  /// Tablets — width <= 768px
  tablet,

  /// Small desktops — width <= 1024px
  desktop,

  /// Large desktops — width > 1024px
  wide,
}
