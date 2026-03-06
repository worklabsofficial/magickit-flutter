import 'package:flutter/material.dart';
import '../atoms/magic_button.dart';
import '../tokens/magic_theme.dart';

/// {@magickit}
/// name: MagicForm
/// category: organism
/// use_case: Form wrapper dengan validasi otomatis dan submit button
/// visual_keywords: form, formulir, input form, submit, validasi
/// {@end}
class MagicForm extends StatefulWidget {
  final List<Widget> children;

  /// Callback saat form valid dan user menekan submit.
  final VoidCallback? onSubmit;

  /// Label tombol submit. Default: 'Submit'.
  final String submitLabel;

  final AutovalidateMode autovalidateMode;

  /// Sembunyikan tombol submit bawaan.
  final bool hideSubmitButton;

  /// Akses ke FormState dari parent via key.
  final GlobalKey<FormState>? formKey;

  const MagicForm({
    super.key,
    required this.children,
    this.onSubmit,
    this.submitLabel = 'Submit',
    this.autovalidateMode = AutovalidateMode.onUserInteraction,
    this.hideSubmitButton = false,
    this.formKey,
  });

  @override
  State<MagicForm> createState() => _MagicFormState();
}

class _MagicFormState extends State<MagicForm> {
  late final GlobalKey<FormState> _key;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _key = widget.formKey ?? GlobalKey<FormState>();
  }

  Future<void> _handleSubmit() async {
    if (!(_key.currentState?.validate() ?? false)) return;
    _key.currentState?.save();

    setState(() => _isSubmitting = true);
    try {
      widget.onSubmit?.call();
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = MagicTheme.of(context);

    return Form(
      key: _key,
      autovalidateMode: widget.autovalidateMode,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          ...widget.children
              .expand((child) => [child, SizedBox(height: theme.spacing.md)])
              .toList()
            ..removeLast(),

          if (!widget.hideSubmitButton && widget.onSubmit != null) ...[
            SizedBox(height: theme.spacing.lg),
            MagicButton(
              label: widget.submitLabel,
              onPressed: _handleSubmit,
              isLoading: _isSubmitting,
            ),
          ],
        ],
      ),
    );
  }
}
