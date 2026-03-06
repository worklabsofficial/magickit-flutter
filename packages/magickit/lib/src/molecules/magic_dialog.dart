import 'package:flutter/material.dart';
import '../atoms/magic_button.dart';
import '../atoms/magic_text.dart';
import '../tokens/magic_theme.dart';

/// {@magickit}
/// name: MagicDialog
/// category: molecule
/// use_case: Dialog popup untuk konfirmasi, informasi, atau input tambahan
/// visual_keywords: dialog, modal, popup, alert, konfirmasi
/// {@end}
class MagicDialog extends StatelessWidget {
  final String? title;
  final Widget content;
  final List<Widget>? actions;
  final bool showClose;
  final double? width;

  const MagicDialog({
    super.key,
    this.title,
    required this.content,
    this.actions,
    this.showClose = true,
    this.width,
  });

  /// Tampilkan [MagicDialog] secara programatik.
  static Future<T?> show<T>(
    BuildContext context, {
    String? title,
    required Widget content,
    List<Widget>? actions,
    bool showClose = true,
    bool barrierDismissible = true,
    double? width,
  }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (_) => MagicDialog(
        title: title,
        content: content,
        actions: actions,
        showClose: showClose,
        width: width,
      ),
    );
  }

  /// Shortcut untuk dialog konfirmasi dengan dua tombol.
  static Future<bool?> confirm(
    BuildContext context, {
    required String title,
    required String message,
    String confirmLabel = 'Konfirmasi',
    String cancelLabel = 'Batal',
    MagicButtonVariant confirmVariant = MagicButtonVariant.primary,
  }) {
    return show<bool>(
      context,
      title: title,
      content: Text(message),
      showClose: false,
      actions: [
        MagicButton(
          label: cancelLabel,
          onPressed: () => Navigator.of(context).pop(false),
          variant: MagicButtonVariant.ghost,
        ),
        MagicButton(
          label: confirmLabel,
          onPressed: () => Navigator.of(context).pop(true),
          variant: confirmVariant,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = MagicTheme.of(context);

    return Dialog(
      backgroundColor: theme.colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(theme.radius.lg),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: width ?? 480),
        child: Padding(
          padding: EdgeInsets.all(theme.spacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              if (title != null || showClose)
                Row(
                  children: [
                    if (title != null)
                      Expanded(
                        child: MagicText(
                          title!,
                          style: MagicTextStyle.h5,
                        ),
                      ),
                    if (showClose)
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: Icon(
                          Icons.close,
                          color: theme.colors.onSurface.withValues(alpha: 0.5),
                          size: 20,
                        ),
                        visualDensity: VisualDensity.compact,
                        splashRadius: 16,
                      ),
                  ],
                ),

              if (title != null || showClose)
                SizedBox(height: theme.spacing.md),

              // Content
              DefaultTextStyle(
                style: theme.typography.bodyMedium.copyWith(
                  color: theme.colors.onSurface.withValues(alpha: 0.8),
                ),
                child: content,
              ),

              // Actions
              if (actions != null && actions!.isNotEmpty) ...[
                SizedBox(height: theme.spacing.lg),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: actions!
                      .map((a) => Padding(
                            padding: EdgeInsets.only(left: theme.spacing.sm),
                            child: a,
                          ))
                      .toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
