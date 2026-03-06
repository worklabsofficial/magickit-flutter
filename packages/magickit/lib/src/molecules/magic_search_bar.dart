import 'package:flutter/material.dart';
import '../atoms/magic_icon.dart';
import '../tokens/magic_theme.dart';

/// {@magickit}
/// name: MagicSearchBar
/// category: molecule
/// use_case: Input pencarian dengan tombol clear dan submit
/// visual_keywords: search, cari, pencarian, search bar, find
/// {@end}
class MagicSearchBar extends StatefulWidget {
  final TextEditingController? controller;

  /// Callback saat user menekan enter/search di keyboard.
  final ValueChanged<String>? onSearch;

  /// Callback setiap karakter berubah.
  final ValueChanged<String>? onChanged;

  final String hint;
  final bool autofocus;
  final VoidCallback? onClear;
  final bool enabled;

  const MagicSearchBar({
    super.key,
    this.controller,
    this.onSearch,
    this.onChanged,
    this.hint = 'Cari...',
    this.autofocus = false,
    this.onClear,
    this.enabled = true,
  });

  @override
  State<MagicSearchBar> createState() => _MagicSearchBarState();
}

class _MagicSearchBarState extends State<MagicSearchBar> {
  late TextEditingController _controller;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _hasText = _controller.text.isNotEmpty;
    _controller.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    final hasText = _controller.text.isNotEmpty;
    if (hasText != _hasText) {
      setState(() => _hasText = hasText);
    }
    widget.onChanged?.call(_controller.text);
  }

  void _handleClear() {
    _controller.clear();
    widget.onClear?.call();
    widget.onSearch?.call('');
  }

  @override
  void dispose() {
    if (widget.controller == null) _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = MagicTheme.of(context);
    final colors = theme.colors;
    final radius = theme.radius;
    final spacing = theme.spacing;

    return TextField(
      controller: _controller,
      enabled: widget.enabled,
      autofocus: widget.autofocus,
      textInputAction: TextInputAction.search,
      onSubmitted: widget.onSearch,
      style: theme.typography.bodyMedium.copyWith(color: colors.onSurface),
      decoration: InputDecoration(
        hintText: widget.hint,
        hintStyle: theme.typography.bodyMedium.copyWith(
          color: colors.onSurface.withValues(alpha: 0.4),
        ),
        prefixIcon: Padding(
          padding: EdgeInsets.symmetric(horizontal: spacing.sm),
          child: MagicIcon(
            Icons.search,
            size: 20,
            color: colors.onSurface.withValues(alpha: 0.5),
          ),
        ),
        suffixIcon: _hasText
            ? IconButton(
                onPressed: _handleClear,
                icon: MagicIcon(
                  Icons.close,
                  size: 18,
                  color: colors.onSurface.withValues(alpha: 0.5),
                ),
                splashRadius: 16,
              )
            : null,
        filled: true,
        fillColor: widget.enabled ? colors.surface : colors.disabled,
        contentPadding: EdgeInsets.symmetric(
          horizontal: spacing.md,
          vertical: spacing.sm + 2,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius.xl),
          borderSide: BorderSide(color: colors.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius.xl),
          borderSide: BorderSide(color: colors.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius.xl),
          borderSide: BorderSide(color: colors.primary, width: 1.5),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius.xl),
          borderSide: BorderSide(color: colors.disabled),
        ),
      ),
    );
  }
}
