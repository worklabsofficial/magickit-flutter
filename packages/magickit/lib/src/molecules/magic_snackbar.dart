import 'package:flutter/material.dart';
import '../tokens/magic_theme.dart';

enum MagicSnackbarVariant { info, success, warning, error }

/// {@magickit}
/// name: MagicSnackbar
/// category: molecule
/// use_case: Notifikasi sementara di bagian bawah layar
/// visual_keywords: snackbar, toast, notifikasi, pesan, alert
/// {@end}
///
/// Gunakan [MagicSnackbar.show] untuk menampilkan snackbar.
///
/// ```dart
/// MagicSnackbar.show(
///   context,
///   message: 'Data berhasil disimpan',
///   variant: MagicSnackbarVariant.success,
/// );
/// ```
class MagicSnackbar {
  MagicSnackbar._();

  static void show(
    BuildContext context, {
    required String message,
    MagicSnackbarVariant variant = MagicSnackbarVariant.info,
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(seconds: 3),
  }) {
    final theme = MagicTheme.of(context);

    final (Color bg, Color fg, IconData icon) = switch (variant) {
      MagicSnackbarVariant.info => (
          theme.colors.secondary,
          theme.colors.onSecondary,
          Icons.info_outline,
        ),
      MagicSnackbarVariant.success => (
          const Color(0xFF1B7A3E),
          Colors.white,
          Icons.check_circle_outline,
        ),
      MagicSnackbarVariant.warning => (
          const Color(0xFF92610D),
          Colors.white,
          Icons.warning_amber_outlined,
        ),
      MagicSnackbarVariant.error => (
          theme.colors.error,
          theme.colors.onError,
          Icons.error_outline,
        ),
    };

    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          duration: duration,
          backgroundColor: bg,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(theme.radius.sm),
          ),
          margin: EdgeInsets.all(theme.spacing.md),
          content: Row(
            children: [
              Icon(icon, size: 18, color: fg),
              SizedBox(width: theme.spacing.sm),
              Expanded(
                child: Text(
                  message,
                  style: theme.typography.bodySmall.copyWith(
                    color: fg,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          action: actionLabel != null
              ? SnackBarAction(
                  label: actionLabel,
                  textColor: fg.withValues(alpha: 0.85),
                  onPressed: onAction ?? () {},
                )
              : null,
        ),
      );
  }
}
