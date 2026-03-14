import 'package:flutter/material.dart';
import 'package:magickit/magickit.dart';

class MagicKitFormExample extends StatefulWidget {
  const MagicKitFormExample({super.key});

  @override
  State<MagicKitFormExample> createState() => _MagicKitFormExampleState();
}

class _MagicKitFormExampleState extends State<MagicKitFormExample> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _showSuccess(BuildContext context) {
    MagicSnackbar.show(
      context,
      message: 'Profile updated',
      variant: MagicSnackbarVariant.success,
    );
  }

  @override
  Widget build(BuildContext context) {
    return MagicForm(
      submitLabel: 'Save changes',
      onSubmit: () => _showSuccess(context),
      children: [
        MagicFormField(
          label: 'Name',
          isRequired: true,
          child: MagicInput(
            controller: _nameController,
            hint: 'Your full name',
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Name is required';
              }
              return null;
            },
          ),
        ),
        MagicFormField(
          label: 'Email',
          child: MagicInput(
            controller: _emailController,
            hint: 'you@email.com',
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Email is required';
              }
              if (!value.contains('@')) return 'Invalid email';
              return null;
            },
          ),
        ),
      ],
    );
  }
}
