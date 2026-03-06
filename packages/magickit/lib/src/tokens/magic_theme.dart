import 'package:flutter/material.dart';
import 'magic_colors.dart';
import 'magic_radius.dart';
import 'magic_shadows.dart';
import 'magic_spacing.dart';
import 'magic_typography.dart';

class MagicTheme extends ThemeExtension<MagicTheme> {
  final MagicColors colors;
  final MagicTypography typography;
  final MagicSpacing spacing;
  final MagicRadius radius;
  final MagicShadows shadows;

  const MagicTheme({
    required this.colors,
    required this.typography,
    required this.spacing,
    required this.radius,
    required this.shadows,
  });

  factory MagicTheme.light({String? fontFamily}) {
    return MagicTheme(
      colors: MagicColors.light(),
      typography: MagicTypography.defaultTypography(fontFamily: fontFamily),
      spacing: const MagicSpacing(),
      radius: const MagicRadius(),
      shadows: MagicShadows.defaultShadows(),
    );
  }

  factory MagicTheme.dark({String? fontFamily}) {
    return MagicTheme(
      colors: MagicColors.dark(),
      typography: MagicTypography.defaultTypography(fontFamily: fontFamily),
      spacing: const MagicSpacing(),
      radius: const MagicRadius(),
      shadows: MagicShadows.defaultShadows(),
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

  @override
  MagicTheme copyWith({
    MagicColors? colors,
    MagicTypography? typography,
    MagicSpacing? spacing,
    MagicRadius? radius,
    MagicShadows? shadows,
  }) {
    return MagicTheme(
      colors: colors ?? this.colors,
      typography: typography ?? this.typography,
      spacing: spacing ?? this.spacing,
      radius: radius ?? this.radius,
      shadows: shadows ?? this.shadows,
    );
  }

  @override
  MagicTheme lerp(MagicTheme? other, double t) {
    if (other == null) return this;
    return this;
  }
}
