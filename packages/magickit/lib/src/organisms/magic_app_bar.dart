import 'package:flutter/material.dart';
import '../atoms/magic_text.dart';
import '../tokens/magic_theme.dart';

/// {@magickit}
/// name: MagicAppBar
/// category: organism
/// use_case: App bar utama dengan title, actions, dan back button yang themed
/// visual_keywords: app bar, header, navigation bar, title bar, toolbar
/// {@end}
class MagicAppBar extends StatelessWidget implements PreferredSizeWidget {
  /// Teks judul. Gunakan [titleWidget] untuk widget kustom.
  final String? title;

  /// Widget kustom sebagai judul. Override [title] jika keduanya disetel.
  final Widget? titleWidget;

  final List<Widget>? actions;
  final Widget? leading;
  final bool centerTitle;
  final Color? backgroundColor;
  final double elevation;
  final PreferredSizeWidget? bottom;

  /// Tampilkan border/divider di bawah AppBar.
  final bool showBorder;

  const MagicAppBar({
    super.key,
    this.title,
    this.titleWidget,
    this.actions,
    this.leading,
    this.centerTitle = false,
    this.backgroundColor,
    this.elevation = 0,
    this.bottom,
    this.showBorder = true,
  });

  @override
  Size get preferredSize => Size.fromHeight(
        kToolbarHeight + (bottom?.preferredSize.height ?? 0),
      );

  @override
  Widget build(BuildContext context) {
    final theme = MagicTheme.of(context);

    return AppBar(
      title: titleWidget ??
          (title != null
              ? MagicText(title!, style: MagicTextStyle.h5)
              : null),
      actions: actions,
      leading: leading,
      centerTitle: centerTitle,
      backgroundColor: backgroundColor ?? theme.colors.surface,
      elevation: elevation,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      foregroundColor: theme.colors.onSurface,
      bottom: bottom ??
          (showBorder
              ? PreferredSize(
                  preferredSize: const Size.fromHeight(1),
                  child: Divider(
                    height: 1,
                    thickness: 1,
                    color: theme.colors.outline,
                  ),
                )
              : null),
    );
  }
}
