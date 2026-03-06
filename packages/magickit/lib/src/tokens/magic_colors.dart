import 'dart:ui';

class MagicColors {
  final Color primary;
  final Color primaryContainer;
  final Color secondary;
  final Color secondaryContainer;
  final Color surface;
  final Color background;
  final Color error;
  final Color onPrimary;
  final Color onSecondary;
  final Color onSurface;
  final Color onBackground;
  final Color onError;
  final Color outline;
  final Color disabled;
  final Color disabledForeground;

  const MagicColors({
    required this.primary,
    required this.primaryContainer,
    required this.secondary,
    required this.secondaryContainer,
    required this.surface,
    required this.background,
    required this.error,
    required this.onPrimary,
    required this.onSecondary,
    required this.onSurface,
    required this.onBackground,
    required this.onError,
    required this.outline,
    required this.disabled,
    required this.disabledForeground,
  });

  factory MagicColors.light() {
    return const MagicColors(
      primary: Color(0xFF2D4AF5),
      primaryContainer: Color(0xFFDDE1FD),
      secondary: Color(0xFF1A1A2E),
      secondaryContainer: Color(0xFFE8E8F0),
      surface: Color(0xFFFFFFFF),
      background: Color(0xFFF5F4F0),
      error: Color(0xFFE53935),
      onPrimary: Color(0xFFFFFFFF),
      onSecondary: Color(0xFFFFFFFF),
      onSurface: Color(0xFF1A1A2E),
      onBackground: Color(0xFF1A1A2E),
      onError: Color(0xFFFFFFFF),
      outline: Color(0xFFD0CFC9),
      disabled: Color(0xFFE8E8E8),
      disabledForeground: Color(0xFF9E9E9E),
    );
  }

  factory MagicColors.dark() {
    return const MagicColors(
      primary: Color(0xFF6B82F8),
      primaryContainer: Color(0xFF1A2580),
      secondary: Color(0xFFB0B8C8),
      secondaryContainer: Color(0xFF2A2A3E),
      surface: Color(0xFF1E1E2E),
      background: Color(0xFF121218),
      error: Color(0xFFEF5350),
      onPrimary: Color(0xFFFFFFFF),
      onSecondary: Color(0xFF1A1A2E),
      onSurface: Color(0xFFE8E8F0),
      onBackground: Color(0xFFE8E8F0),
      onError: Color(0xFFFFFFFF),
      outline: Color(0xFF3A3A4E),
      disabled: Color(0xFF2A2A3E),
      disabledForeground: Color(0xFF5A5A6E),
    );
  }

  MagicColors copyWith({
    Color? primary,
    Color? primaryContainer,
    Color? secondary,
    Color? secondaryContainer,
    Color? surface,
    Color? background,
    Color? error,
    Color? onPrimary,
    Color? onSecondary,
    Color? onSurface,
    Color? onBackground,
    Color? onError,
    Color? outline,
    Color? disabled,
    Color? disabledForeground,
  }) {
    return MagicColors(
      primary: primary ?? this.primary,
      primaryContainer: primaryContainer ?? this.primaryContainer,
      secondary: secondary ?? this.secondary,
      secondaryContainer: secondaryContainer ?? this.secondaryContainer,
      surface: surface ?? this.surface,
      background: background ?? this.background,
      error: error ?? this.error,
      onPrimary: onPrimary ?? this.onPrimary,
      onSecondary: onSecondary ?? this.onSecondary,
      onSurface: onSurface ?? this.onSurface,
      onBackground: onBackground ?? this.onBackground,
      onError: onError ?? this.onError,
      outline: outline ?? this.outline,
      disabled: disabled ?? this.disabled,
      disabledForeground: disabledForeground ?? this.disabledForeground,
    );
  }
}
