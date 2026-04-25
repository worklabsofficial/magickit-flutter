import 'package:flutter/material.dart';
import 'magic_theme.dart';

/// Design system color tokens untuk MagicKit.
///
/// Akses langsung dari context:
/// ```dart
/// final colors = MagicColors.of(context);
/// colors.primary        // Color utama
/// colors.onSurface      // Teks di atas surface
/// colors.extra('brand') // Custom color via extras
/// ```
///
/// Atau via MagicTheme:
/// ```dart
/// final theme = MagicTheme.of(context);
/// theme.colors.primary
/// ```
///
/// Tambah warna custom:
/// ```dart
/// final colors = MagicColors.light().copyWithExtras({
///   'brand': Color(0xFFFF6B00),
///   'success': Color(0xFF4CAF50),
///   'warning': Color(0xFFFFC107),
/// });
/// ```
///
/// Lalu daftarkan di ThemeData:
/// ```dart
/// MaterialApp(
///   theme: ThemeData(
///     extensions: [
///       MagicTheme.light().copyWith(colors: colors),
///     ],
///   ),
/// )
/// ```
class MagicColors extends ThemeExtension<MagicColors> {
  // ─── Core tokens ───────────────────────────────────────────

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

  // ─── Extensible custom colors ─────────────────────────────

  /// Warna custom tambahan. Akses via `colors.extra('name')`.
  final Map<String, Color> extras;

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
    this.extras = const {},
  });

  // ─── Context access ───────────────────────────────────────

  /// Akses MagicColors dari mana saja dalam widget tree.
  ///
  /// Membaca dari MagicTheme yang terdaftar di ThemeData.extensions.
  ///
  /// Throws jika MagicTheme tidak terdaftar.
  static MagicColors of(BuildContext context) {
    return MagicTheme.of(context).colors;
  }

  // ─── Extras convenience ───────────────────────────────────

  /// Ambil custom color berdasarkan nama.
  /// Returns `null` jika nama tidak ditemukan.
  Color? extra(String name) => extras[name];

  /// Ambil custom color, atau fallback jika tidak ada.
  Color extraOrDefault(String name, Color fallback) => extras[name] ?? fallback;

  /// Cek apakah custom color tersedia.
  bool hasExtra(String name) => extras.containsKey(name);

  // ─── Factories ────────────────────────────────────────────

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

  // ─── ThemeExtension ───────────────────────────────────────

  @override
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
    Map<String, Color>? extras,
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
      extras: extras ?? this.extras,
    );
  }

  /// Salin dengan menambah / mengganti custom colors.
  ///
  /// ```dart
  /// final colors = MagicColors.light().copyWithExtras({
  ///   'brand': Color(0xFFFF6B00),
  ///   'success': Color(0xFF4CAF50),
  ///   'warning': Color(0xFFFFC107),
  ///   'info': Color(0xFF2196F3),
  /// });
  /// ```
  MagicColors copyWithExtras(Map<String, Color> newExtras) {
    return copyWith(extras: {...extras, ...newExtras});
  }

  /// Hapus custom color berdasarkan nama.
  MagicColors removeExtra(String name) {
    final updated = Map<String, Color>.from(extras)..remove(name);
    return copyWith(extras: updated);
  }

  @override
  MagicColors lerp(MagicColors? other, double t) {
    if (other == null) return this;

    // Lerp extras maps
    final lerpedExtras = <String, Color>{};
    final allKeys = {...extras.keys, ...other.extras.keys};
    for (final key in allKeys) {
      final a = extras[key];
      final b = other.extras[key];
      if (a != null && b != null) {
        lerpedExtras[key] = Color.lerp(a, b, t)!;
      } else if (a != null) {
        lerpedExtras[key] = a;
      } else if (b != null) {
        lerpedExtras[key] = b;
      }
    }

    return MagicColors(
      primary: Color.lerp(primary, other.primary, t)!,
      primaryContainer:
          Color.lerp(primaryContainer, other.primaryContainer, t)!,
      secondary: Color.lerp(secondary, other.secondary, t)!,
      secondaryContainer:
          Color.lerp(secondaryContainer, other.secondaryContainer, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      background: Color.lerp(background, other.background, t)!,
      error: Color.lerp(error, other.error, t)!,
      onPrimary: Color.lerp(onPrimary, other.onPrimary, t)!,
      onSecondary: Color.lerp(onSecondary, other.onSecondary, t)!,
      onSurface: Color.lerp(onSurface, other.onSurface, t)!,
      onBackground: Color.lerp(onBackground, other.onBackground, t)!,
      onError: Color.lerp(onError, other.onError, t)!,
      outline: Color.lerp(outline, other.outline, t)!,
      disabled: Color.lerp(disabled, other.disabled, t)!,
      disabledForeground:
          Color.lerp(disabledForeground, other.disabledForeground, t)!,
      extras: lerpedExtras,
    );
  }
}
