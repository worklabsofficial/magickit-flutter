import 'package:flutter/material.dart';
import '../atoms/magic_text.dart';
import '../tokens/magic_theme.dart';

/// {@magickit}
/// name: MagicBottomSheet
/// category: organism
/// use_case: Bottom sheet modal untuk menu aksi, filter, atau konten tambahan
/// visual_keywords: bottom sheet, modal, sheet, action sheet, drawer bawah
/// {@end}
class MagicBottomSheet extends StatelessWidget {
  final Widget child;
  final bool isDismissible;
  final String? title;
  final bool showHandle;

  const MagicBottomSheet({
    super.key,
    required this.child,
    this.isDismissible = true,
    this.title,
    this.showHandle = true,
  });

  /// Tampilkan [MagicBottomSheet] secara programatik.
  static Future<T?> show<T>(
    BuildContext context, {
    required Widget child,
    bool isDismissible = true,
    String? title,
    bool showHandle = true,
    bool isScrollControlled = false,
    bool useSafeArea = true,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isDismissible: isDismissible,
      isScrollControlled: isScrollControlled,
      useSafeArea: useSafeArea,
      backgroundColor: Colors.transparent,
      builder: (_) => MagicBottomSheet(
        isDismissible: isDismissible,
        title: title,
        showHandle: showHandle,
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = MagicTheme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colors.surface,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(theme.radius.xl),
          topRight: Radius.circular(theme.radius.xl),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          if (showHandle)
            Padding(
              padding: EdgeInsets.only(top: theme.spacing.sm),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colors.outline,
                  borderRadius: BorderRadius.circular(theme.radius.full),
                ),
              ),
            ),

          // Title
          if (title != null)
            Padding(
              padding: EdgeInsets.fromLTRB(
                theme.spacing.lg,
                theme.spacing.md,
                theme.spacing.lg,
                0,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: MagicText(title!, style: MagicTextStyle.h5),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(
                      Icons.close,
                      size: 20,
                      color: theme.colors.onSurface.withValues(alpha: 0.5),
                    ),
                    visualDensity: VisualDensity.compact,
                    splashRadius: 16,
                  ),
                ],
              ),
            ),

          // Content
          Padding(
            padding: EdgeInsets.fromLTRB(
              theme.spacing.lg,
              title != null ? theme.spacing.md : theme.spacing.lg,
              theme.spacing.lg,
              theme.spacing.lg,
            ),
            child: child,
          ),
        ],
      ),
    );
  }
}
