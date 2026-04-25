import 'package:flutter/material.dart';
import '../atoms/magic_button.dart';
import '../atoms/magic_text.dart';
import '../tokens/magic_theme.dart';

/// {@magickit}
/// name: MagicEmptyState
/// category: molecule
/// use_case: Tampilan kosong ketika tidak ada data, hasil pencarian kosong, error state
/// visual_keywords: empty, empty state, no data, kosong, tidak ada data, placeholder, error
/// {@end}
class MagicEmptyState extends StatelessWidget {
  /// Icon yang ditampilkan.
  final IconData? icon;

  /// Widget illustration custom (menggantikan icon).
  final Widget? illustration;

  /// Judul utama.
  final String title;

  /// Deskripsi/subtitle.
  final String? description;

  /// Primary action button.
  final String? actionLabel;

  /// Callback untuk primary action.
  final VoidCallback? onAction;

  /// Secondary action button.
  final String? secondaryActionLabel;

  /// Callback untuk secondary action.
  final VoidCallback? onSecondaryAction;

  /// Ukuran icon.
  final double iconSize;

  /// Warna icon.
  final Color? iconColor;

  /// Alignment konten.
  final CrossAxisAlignment crossAxisAlignment;

  /// Padding container.
  final EdgeInsetsGeometry? padding;

  /// Background color.
  final Color? backgroundColor;

  const MagicEmptyState({
    super.key,
    this.icon,
    this.illustration,
    required this.title,
    this.description,
    this.actionLabel,
    this.onAction,
    this.secondaryActionLabel,
    this.onSecondaryAction,
    this.iconSize = 64,
    this.iconColor,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.padding,
    this.backgroundColor,
  });

  /// Empty state untuk list/data yang kosong.
  const MagicEmptyState.noData({
    super.key,
    String? customTitle,
    String? customDescription,
    this.actionLabel,
    this.onAction,
    this.illustration,
    this.iconColor,
    this.padding,
    this.backgroundColor,
  })  : icon = Icons.inbox_rounded,
        title = customTitle ?? 'Belum ada data',
        description = customDescription ??
            'Data akan muncul di sini setelah ditambahkan.',
        secondaryActionLabel = null,
        onSecondaryAction = null,
        iconSize = 64,
        crossAxisAlignment = CrossAxisAlignment.center;

  /// Empty state untuk hasil pencarian kosong.
  const MagicEmptyState.noResults({
    super.key,
    String? query,
    this.actionLabel,
    this.onAction,
    this.illustration,
    this.iconColor,
    this.padding,
    this.backgroundColor,
  })  : icon = Icons.search_off_rounded,
        title = 'Tidak ditemukan',
        description = query != null
            ? 'Tidak ada hasil untuk "$query". Coba kata kunci lain.'
            : 'Coba kata kunci yang berbeda.',
        secondaryActionLabel = null,
        onSecondaryAction = null,
        iconSize = 64,
        crossAxisAlignment = CrossAxisAlignment.center;

  /// Empty state untuk error.
  const MagicEmptyState.error({
    super.key,
    String? customTitle,
    String? customDescription,
    this.actionLabel = 'Coba Lagi',
    this.onAction,
    this.secondaryActionLabel,
    this.onSecondaryAction,
    this.illustration,
    this.iconColor,
    this.padding,
    this.backgroundColor,
  })  : icon = Icons.error_outline_rounded,
        title = customTitle ?? 'Terjadi Kesalahan',
        description =
            customDescription ?? 'Gagal memuat data. Silakan coba lagi.',
        iconSize = 64,
        crossAxisAlignment = CrossAxisAlignment.center;

  /// Empty state untuk tidak ada koneksi internet.
  const MagicEmptyState.offline({
    super.key,
    this.actionLabel = 'Coba Lagi',
    this.onAction,
    this.illustration,
    this.iconColor,
    this.padding,
    this.backgroundColor,
  })  : icon = Icons.wifi_off_rounded,
        title = 'Tidak Ada Koneksi',
        description = 'Periksa koneksi internet Anda dan coba lagi.',
        secondaryActionLabel = null,
        onSecondaryAction = null,
        iconSize = 64,
        crossAxisAlignment = CrossAxisAlignment.center;

  @override
  Widget build(BuildContext context) {
    final theme = MagicTheme.of(context);
    final resolvedIconColor = iconColor ?? theme.colors.disabledForeground;

    final children = <Widget>[];

    // Illustration or Icon
    if (illustration != null) {
      children.add(illustration!);
    } else if (icon != null) {
      children.add(
        Icon(
          icon,
          size: iconSize,
          color: resolvedIconColor,
        ),
      );
    }

    children.add(SizedBox(height: theme.spacing.lg));

    // Title
    children.add(
      MagicText(
        title,
        style: MagicTextStyle.h5,
        textAlign: TextAlign.center,
      ),
    );

    // Description
    if (description != null) {
      children.add(SizedBox(height: theme.spacing.sm));
      children.add(
        MagicText(
          description!,
          style: MagicTextStyle.bodyMedium,
          color: theme.colors.disabledForeground,
          textAlign: TextAlign.center,
        ),
      );
    }

    // Actions
    if (actionLabel != null || secondaryActionLabel != null) {
      children.add(SizedBox(height: theme.spacing.lg));

      final actionButtons = <Widget>[];

      if (actionLabel != null && onAction != null) {
        actionButtons.add(
          MagicButton(
            label: actionLabel!,
            onPressed: onAction,
          ),
        );
      }

      if (secondaryActionLabel != null && onSecondaryAction != null) {
        actionButtons.add(
          MagicButton(
            label: secondaryActionLabel!,
            onPressed: onSecondaryAction,
            variant: MagicButtonVariant.outlined,
          ),
        );
      }

      if (actionButtons.length == 1) {
        children.add(actionButtons.first);
      } else {
        children.add(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              actionButtons[0],
              SizedBox(width: theme.spacing.sm),
              actionButtons[1],
            ],
          ),
        );
      }
    }

    return Container(
      padding: padding ?? EdgeInsets.all(theme.spacing.xl),
      color: backgroundColor,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: crossAxisAlignment,
        children: children,
      ),
    );
  }
}
