import 'package:flutter/material.dart';
import '../tokens/magic_theme.dart';
import 'magic_shimmer.dart';

/// {@magickit}
/// name: MagicImage
/// category: atom
/// use_case: Menampilkan gambar dari URL atau asset dengan loading dan error state
/// visual_keywords: image, gambar, foto, picture, thumbnail
/// {@end}
class MagicImage extends StatelessWidget {
  /// URL gambar (http/https) atau path asset lokal.
  final String src;

  final BoxFit fit;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;

  /// Widget saat gambar gagal dimuat.
  final Widget? errorWidget;

  const MagicImage({
    super.key,
    required this.src,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.borderRadius,
    this.errorWidget,
  });

  bool get _isNetwork =>
      src.startsWith('http://') || src.startsWith('https://');

  @override
  Widget build(BuildContext context) {
    final theme = MagicTheme.of(context);

    Widget image = _isNetwork ? _buildNetworkImage(theme) : _buildAssetImage(theme);

    if (borderRadius != null) {
      image = ClipRRect(borderRadius: borderRadius!, child: image);
    }

    return image;
  }

  Widget _buildNetworkImage(MagicTheme theme) {
    return Image.network(
      src,
      fit: fit,
      width: width,
      height: height,
      loadingBuilder: (_, child, event) {
        if (event == null) return child;
        return MagicShimmer(
          width: width,
          height: height,
          borderRadius: borderRadius,
        );
      },
      errorBuilder: (_, __, ___) => _buildError(theme),
    );
  }

  Widget _buildAssetImage(MagicTheme theme) {
    return Image.asset(
      src,
      fit: fit,
      width: width,
      height: height,
      errorBuilder: (_, __, ___) => _buildError(theme),
    );
  }

  Widget _buildError(MagicTheme theme) {
    return Container(
      width: width,
      height: height,
      color: theme.colors.disabled,
      alignment: Alignment.center,
      child: Icon(
        Icons.broken_image_outlined,
        color: theme.colors.disabledForeground,
        size: 24,
      ),
    );
  }
}
