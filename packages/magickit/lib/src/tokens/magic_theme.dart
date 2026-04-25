import 'package:flutter/material.dart';
import 'magic_animations.dart';
import 'magic_breakpoints.dart';
import 'magic_colors.dart';
import 'magic_radius.dart';
import 'magic_shadows.dart';
import 'magic_spacing.dart';
import 'magic_typography.dart';

/// Central theme extension untuk MagicKit design system.
///
/// Akses dari mana saja dengan:
/// ```dart
/// final theme = MagicTheme.of(context);
/// theme.colors.primary
/// theme.spacing.md
/// theme.animations.normal
/// ```
class MagicTheme extends ThemeExtension<MagicTheme> {
  final MagicColors colors;
  final MagicTypography typography;
  final MagicSpacing spacing;
  final MagicRadius radius;
  final MagicShadows shadows;
  final MagicAnimations animations;
  final MagicBreakpoints breakpoints;

  const MagicTheme({
    required this.colors,
    required this.typography,
    required this.spacing,
    required this.radius,
    required this.shadows,
    MagicAnimations? animations,
    MagicBreakpoints? breakpoints,
  })  : animations = animations ?? const MagicAnimations(),
        breakpoints = breakpoints ?? const MagicBreakpoints();

  factory MagicTheme.light({String? fontFamily}) {
    return MagicTheme(
      colors: MagicColors.light(),
      typography: MagicTypography.defaultTypography(fontFamily: fontFamily),
      spacing: const MagicSpacing(),
      radius: const MagicRadius(),
      shadows: MagicShadows.defaultShadows(),
      animations: MagicAnimations.defaults(),
      breakpoints: MagicBreakpoints.defaults(),
    );
  }

  factory MagicTheme.dark({String? fontFamily}) {
    return MagicTheme(
      colors: MagicColors.dark(),
      typography: MagicTypography.defaultTypography(fontFamily: fontFamily),
      spacing: const MagicSpacing(),
      radius: const MagicRadius(),
      shadows: MagicShadows.defaultShadows(),
      animations: MagicAnimations.defaults(),
      breakpoints: MagicBreakpoints.defaults(),
    );
  }

  /// Access MagicTheme from any widget context.
  ///
  /// Throws if MagicTheme is not registered in ThemeData.extensions.
  static MagicTheme of(BuildContext context) {
    final theme = Theme.of(context).extension<MagicTheme>();
    assert(
      theme != null,
      'MagicTheme not found in context.\n'
      'Make sure to add MagicTheme to ThemeData.extensions:\n\n'
      '  MaterialApp(\n'
      '    theme: ThemeData(\n'
      '      extensions: [MagicTheme.light()],\n'
      '    ),\n'
      '  );',
    );
    return theme!;
  }

  /// Check if current theme is dark mode.
  static bool isDark(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }

  /// Responsive breakpoint type dari context saat ini.
  static MagicBreakpointType breakpoint(BuildContext context) {
    return MagicBreakpoints.typeOf(context);
  }

  @override
  MagicTheme copyWith({
    MagicColors? colors,
    MagicTypography? typography,
    MagicSpacing? spacing,
    MagicRadius? radius,
    MagicShadows? shadows,
    MagicAnimations? animations,
    MagicBreakpoints? breakpoints,
  }) {
    return MagicTheme(
      colors: colors ?? this.colors,
      typography: typography ?? this.typography,
      spacing: spacing ?? this.spacing,
      radius: radius ?? this.radius,
      shadows: shadows ?? this.shadows,
      animations: animations ?? this.animations,
      breakpoints: breakpoints ?? this.breakpoints,
    );
  }

  @override
  MagicTheme lerp(MagicTheme? other, double t) {
    if (other == null) return this;
    return MagicTheme(
      colors: colors.lerp(other.colors, t),
      typography: typography,
      spacing: spacing,
      radius: radius,
      shadows: shadows,
      animations: animations,
      breakpoints: breakpoints,
    );
  }
}
