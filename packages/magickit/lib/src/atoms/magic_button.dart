import 'package:flutter/material.dart';
import '../tokens/magic_theme.dart';

enum MagicButtonVariant { primary, secondary, outlined, ghost }

enum MagicButtonSize { small, medium, large }

/// {@magickit}
/// name: MagicButton
/// category: atom
/// use_case: Tombol aksi utama, submit form, navigasi
/// visual_keywords: button, tombol, CTA, submit, aksi
/// {@end}
class MagicButton extends StatelessWidget {
  /// Label teks yang ditampilkan di tombol.
  final String label;

  /// Callback saat tombol ditekan. Null = disabled state.
  final VoidCallback? onPressed;

  /// Variant tampilan tombol.
  final MagicButtonVariant variant;

  /// Ukuran tombol.
  final MagicButtonSize size;

  /// Loading state — menampilkan spinner dan menonaktifkan interaksi.
  final bool isLoading;

  /// Icon opsional di sebelah kiri label.
  final IconData? icon;

  const MagicButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = MagicButtonVariant.primary,
    this.size = MagicButtonSize.medium,
    this.isLoading = false,
    this.icon,
  });

  double get _height => switch (size) {
        MagicButtonSize.small => 32,
        MagicButtonSize.medium => 40,
        MagicButtonSize.large => 48,
      };

  EdgeInsets get _padding => switch (size) {
        MagicButtonSize.small =>
          const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        MagicButtonSize.medium =>
          const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        MagicButtonSize.large =>
          const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      };

  double get _fontSize => switch (size) {
        MagicButtonSize.small => 12,
        MagicButtonSize.medium => 14,
        MagicButtonSize.large => 16,
      };

  double get _iconSize => switch (size) {
        MagicButtonSize.small => 14,
        MagicButtonSize.medium => 16,
        MagicButtonSize.large => 18,
      };

  ButtonStyle _buildStyle(MagicTheme theme) {
    final colors = theme.colors;
    final radius = theme.radius;

    final (Color bg, Color fg, Color border) = switch (variant) {
      MagicButtonVariant.primary => (
          colors.primary,
          colors.onPrimary,
          colors.primary,
        ),
      MagicButtonVariant.secondary => (
          colors.secondary,
          colors.onSecondary,
          colors.secondary,
        ),
      MagicButtonVariant.outlined => (
          Colors.transparent,
          colors.primary,
          colors.primary,
        ),
      MagicButtonVariant.ghost => (
          Colors.transparent,
          colors.primary,
          Colors.transparent,
        ),
    };

    return ButtonStyle(
      backgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) return colors.disabled;
        if (states.contains(WidgetState.pressed)) {
          return bg.withValues(alpha: 0.85);
        }
        if (states.contains(WidgetState.hovered)) {
          return bg.withValues(alpha: 0.92);
        }
        return bg;
      }),
      foregroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return colors.disabledForeground;
        }
        return fg;
      }),
      overlayColor: WidgetStateProperty.all(Colors.transparent),
      elevation: WidgetStateProperty.all(0),
      shape: WidgetStateProperty.all(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius.sm),
          side: BorderSide(
            color: border,
            width: variant == MagicButtonVariant.outlined ? 1.5 : 0,
          ),
        ),
      ),
      padding: WidgetStateProperty.all(_padding),
      minimumSize: WidgetStateProperty.all(Size(0, _height)),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  Widget _buildChild(MagicTheme theme) {
    if (isLoading) {
      final spinnerColor =
          variant == MagicButtonVariant.outlined ||
                  variant == MagicButtonVariant.ghost
              ? theme.colors.primary
              : theme.colors.onPrimary;

      return SizedBox(
        width: _iconSize,
        height: _iconSize,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation(spinnerColor),
        ),
      );
    }

    final textWidget = Text(
      label,
      style: TextStyle(fontSize: _fontSize, fontWeight: FontWeight.w600),
    );

    if (icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: _iconSize),
          SizedBox(width: theme.spacing.xs),
          textWidget,
        ],
      );
    }

    return textWidget;
  }

  @override
  Widget build(BuildContext context) {
    final theme = MagicTheme.of(context);
    return ElevatedButton(
      onPressed: (onPressed == null || isLoading) ? null : onPressed,
      style: _buildStyle(theme),
      child: _buildChild(theme),
    );
  }
}
