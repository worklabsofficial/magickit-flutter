import 'package:flutter/material.dart';
import '../tokens/magic_theme.dart';

enum MagicAvatarSize { sm, md, lg }

/// {@magickit}
/// name: MagicAvatar
/// category: atom
/// use_case: Menampilkan avatar user dengan fallback initials
/// visual_keywords: avatar, profil, user, profile picture, foto
/// {@end}
class MagicAvatar extends StatelessWidget {
  /// URL gambar avatar. Jika null atau gagal load, tampilkan fallback.
  final String? imageUrl;

  /// Ukuran avatar: sm (32), md (40), lg (56).
  final MagicAvatarSize size;

  /// Inisial yang ditampilkan saat gambar tidak tersedia.
  final String? fallbackInitial;

  /// Warna background fallback. Default: theme.colors.primaryContainer.
  final Color? backgroundColor;

  const MagicAvatar({
    super.key,
    this.imageUrl,
    this.size = MagicAvatarSize.md,
    this.fallbackInitial,
    this.backgroundColor,
  });

  double get _dimension => switch (size) {
        MagicAvatarSize.sm => 32,
        MagicAvatarSize.md => 40,
        MagicAvatarSize.lg => 56,
      };

  double get _fontSize => switch (size) {
        MagicAvatarSize.sm => 12,
        MagicAvatarSize.md => 16,
        MagicAvatarSize.lg => 22,
      };

  @override
  Widget build(BuildContext context) {
    final theme = MagicTheme.of(context);
    final dim = _dimension;

    Widget content;
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      content = Image.network(
        imageUrl!,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildFallback(theme),
        loadingBuilder: (_, child, event) {
          if (event == null) return child;
          return _buildFallback(theme);
        },
      );
    } else {
      content = _buildFallback(theme);
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(theme.radius.full),
      child: SizedBox(width: dim, height: dim, child: content),
    );
  }

  Widget _buildFallback(MagicTheme theme) {
    final initial =
        fallbackInitial?.isNotEmpty == true ? fallbackInitial![0].toUpperCase() : '?';
    return Container(
      color: backgroundColor ?? theme.colors.primaryContainer,
      alignment: Alignment.center,
      child: Text(
        initial,
        style: TextStyle(
          fontSize: _fontSize,
          fontWeight: FontWeight.w600,
          color: theme.colors.primary,
        ),
      ),
    );
  }
}
