import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../tokens/magic_theme.dart';

/// {@magickit}
/// name: MagicPinInput
/// category: atom
/// use_case: Input PIN/OTP dengan kotak-kotak digit, cocok untuk verifikasi kode
/// visual_keywords: pin, otp, verification, code, input, digit, box, security
/// {@end}
class MagicPinInput extends StatefulWidget {
  /// Jumlah digit PIN.
  final int length;

  /// Callback saat PIN lengkap terisi.
  final ValueChanged<String>? onCompleted;

  /// Callback saat setiap perubahan input.
  final ValueChanged<String>? onChanged;

  /// Controller untuk mengontrol value.
  final TextEditingController? controller;

  /// Auto-focus saat pertama kali tampil.
  final bool autofocus;

  /// Obscure text (untuk PIN sensitif).
  final bool obscureText;

  /// Character untuk obscure (default: •).
  final String obscureChar;

  /// Error state.
  final bool hasError;

  /// Disabled state.
  final bool enabled;

  /// Warna border kotak.
  final Color? borderColor;

  /// Warna border saat focused.
  final Color? focusedBorderColor;

  /// Warna border saat error.
  final Color? errorBorderColor;

  /// Warna background kotak.
  final Color? fillColor;

  /// Warna text.
  final Color? textColor;

  /// Ukuran setiap kotak.
  final double boxWidth;

  /// Tinggi setiap kotak.
  final double boxHeight;

  /// Jarak antar kotak.
  final double spacing;

  /// Border radius setiap kotak.
  final BorderRadius? borderRadius;

  /// Keyboard type.
  final TextInputType keyboardType;

  /// Shape dari box decoration.
  final MagicPinInputShape shape;

  const MagicPinInput({
    super.key,
    this.length = 6,
    this.onCompleted,
    this.onChanged,
    this.controller,
    this.autofocus = true,
    this.obscureText = false,
    this.obscureChar = '•',
    this.hasError = false,
    this.enabled = true,
    this.borderColor,
    this.focusedBorderColor,
    this.errorBorderColor,
    this.fillColor,
    this.textColor,
    this.boxWidth = 48,
    this.boxHeight = 56,
    this.spacing = 8,
    this.borderRadius,
    this.keyboardType = TextInputType.number,
    this.shape = MagicPinInputShape.outlined,
  });

  /// PIN input dengan filled background style.
  const MagicPinInput.filled({
    super.key,
    this.length = 6,
    this.onCompleted,
    this.onChanged,
    this.controller,
    this.autofocus = true,
    this.obscureText = false,
    this.obscureChar = '•',
    this.hasError = false,
    this.enabled = true,
    this.borderColor,
    this.focusedBorderColor,
    this.errorBorderColor,
    this.fillColor,
    this.textColor,
    this.boxWidth = 48,
    this.boxHeight = 56,
    this.spacing = 8,
    this.borderRadius,
    this.keyboardType = TextInputType.number,
  }) : shape = MagicPinInputShape.filled;

  /// PIN input dengan underline style.
  const MagicPinInput.underlined({
    super.key,
    this.length = 6,
    this.onCompleted,
    this.onChanged,
    this.controller,
    this.autofocus = true,
    this.obscureText = false,
    this.obscureChar = '•',
    this.hasError = false,
    this.enabled = true,
    this.borderColor,
    this.focusedBorderColor,
    this.errorBorderColor,
    this.fillColor,
    this.textColor,
    this.boxWidth = 48,
    this.boxHeight = 56,
    this.spacing = 8,
    this.borderRadius,
    this.keyboardType = TextInputType.number,
  }) : shape = MagicPinInputShape.underlined;

  @override
  State<MagicPinInput> createState() => _MagicPinInputState();
}

class _MagicPinInputState extends State<MagicPinInput> {
  late TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;

  TextEditingController get _effectiveController =>
      widget.controller ?? _controller;

  @override
  void initState() {
    super.initState();
    if (widget.controller == null) {
      _controller = TextEditingController();
    }
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
  }

  void _onTextChanged(String value) {
    if (value.length > widget.length) {
      _effectiveController.text = value.substring(0, widget.length);
      _effectiveController.selection = TextSelection.collapsed(
        offset: widget.length,
      );
      return;
    }

    widget.onChanged?.call(value);

    if (value.length == widget.length) {
      widget.onCompleted?.call(value);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = MagicTheme.of(context);
    final resolvedBorderColor = widget.borderColor ?? theme.colors.outline;
    final resolvedFocusedColor =
        widget.focusedBorderColor ?? theme.colors.primary;
    final resolvedErrorColor = widget.errorBorderColor ?? theme.colors.error;
    final resolvedFillColor = widget.fillColor ?? Colors.transparent;
    final resolvedTextColor = widget.textColor ?? theme.colors.onSurface;
    final resolvedRadius =
        widget.borderRadius ?? BorderRadius.circular(theme.radius.md);

    return GestureDetector(
      onTap: () => _focusNode.requestFocus(),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Visible boxes
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(widget.length, (index) {
              return Container(
                margin: EdgeInsets.only(
                  right: index < widget.length - 1 ? widget.spacing : 0,
                ),
                child: _buildBox(
                  index: index,
                  theme: theme,
                  borderColor: resolvedBorderColor,
                  focusedColor: resolvedFocusedColor,
                  errorColor: resolvedErrorColor,
                  fillColor: resolvedFillColor,
                  textColor: resolvedTextColor,
                  borderRadius: resolvedRadius,
                ),
              );
            }),
          ),

          // Hidden text field
          SizedBox(
            width: 0,
            height: 0,
            child: TextField(
              controller: _effectiveController,
              focusNode: _focusNode,
              autofocus: widget.autofocus,
              enabled: widget.enabled,
              keyboardType: widget.keyboardType,
              maxLength: widget.length,
              inputFormatters: [
                if (widget.keyboardType == TextInputType.number)
                  FilteringTextInputFormatter.digitsOnly,
              ],
              onChanged: _onTextChanged,
              style: const TextStyle(fontSize: 0),
              decoration: const InputDecoration(
                border: InputBorder.none,
                counterText: '',
                contentPadding: EdgeInsets.zero,
              ),
              enableInteractiveSelection: false,
              showCursor: false,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBox({
    required int index,
    required MagicTheme theme,
    required Color borderColor,
    required Color focusedColor,
    required Color errorColor,
    required Color fillColor,
    required Color textColor,
    required BorderRadius borderRadius,
  }) {
    final currentLength = _effectiveController.text.length;
    final hasValue = index < currentLength;
    final isCurrentField = index == currentLength && _isFocused;
    final displayChar = hasValue ? _effectiveController.text[index] : '';

    Color resolvedBorderColor = borderColor;
    if (widget.hasError) {
      resolvedBorderColor = errorColor;
    } else if (isCurrentField) {
      resolvedBorderColor = focusedColor;
    } else if (hasValue) {
      resolvedBorderColor = focusedColor;
    }

    final double borderWidth = (isCurrentField || widget.hasError) ? 2.0 : 1.0;

    BoxDecoration decoration;

    switch (widget.shape) {
      case MagicPinInputShape.outlined:
        decoration = BoxDecoration(
          color: fillColor,
          borderRadius: borderRadius,
          border: Border.all(
            color: resolvedBorderColor,
            width: borderWidth,
          ),
        );
        break;
      case MagicPinInputShape.filled:
        decoration = BoxDecoration(
          color: widget.hasError
              ? errorColor.withValues(alpha: 0.08)
              : (hasValue || isCurrentField)
                  ? focusedColor.withValues(alpha: 0.08)
                  : fillColor,
          borderRadius: borderRadius,
          border: Border.all(
            color: resolvedBorderColor,
            width: borderWidth,
          ),
        );
        break;
      case MagicPinInputShape.underlined:
        decoration = BoxDecoration(
          color: Colors.transparent,
          border: Border(
            bottom: BorderSide(
              color: resolvedBorderColor,
              width: borderWidth,
            ),
          ),
        );
        break;
    }

    return AnimatedContainer(
      duration: theme.animations.fast,
      curve: theme.animations.curveDefault,
      width: widget.boxWidth,
      height: widget.boxHeight,
      decoration: decoration,
      alignment: Alignment.center,
      child: hasValue
          ? Text(
              widget.obscureText ? widget.obscureChar : displayChar,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            )
          : (isCurrentField ? _BlinkingCursor(color: focusedColor) : null),
    );
  }
}

/// Blinking cursor indicator untuk current active field.
class _BlinkingCursor extends StatefulWidget {
  final Color color;

  const _BlinkingCursor({required this.color});

  @override
  State<_BlinkingCursor> createState() => _BlinkingCursorState();
}

class _BlinkingCursorState extends State<_BlinkingCursor>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: Container(
        width: 2,
        height: 24,
        decoration: BoxDecoration(
          color: widget.color,
          borderRadius: BorderRadius.circular(1),
        ),
      ),
    );
  }
}

/// Shape dari PIN input box.
enum MagicPinInputShape {
  /// Kotak dengan border
  outlined,

  /// Kotak dengan background filled
  filled,

  /// Garis bawah saja
  underlined,
}
