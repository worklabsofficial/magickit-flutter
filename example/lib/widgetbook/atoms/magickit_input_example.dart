import 'package:flutter/material.dart';
import 'package:magickit/magickit.dart';

class MagicKitInputExample extends StatefulWidget {
  const MagicKitInputExample({super.key});

  @override
  State<MagicKitInputExample> createState() => _MagicKitInputExampleState();
}

class _MagicKitInputExampleState extends State<MagicKitInputExample> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = MagicTheme.of(context);

    return Column(
      children: [
        MagicInput(
          label: 'Email',
          hint: 'Masukkan email kamu',
          controller: _controller,
          keyboardType: TextInputType.emailAddress,
          prefixIcon: const Icon(Icons.email_outlined),
        ),
        SizedBox(height: theme.spacing.sm),
        const MagicInput(
          label: 'Password',
          hint: 'Masukkan password',
          obscureText: true,
          prefixIcon: Icon(Icons.lock_outlined),
        ),
        SizedBox(height: theme.spacing.sm),
        const MagicInput(
          hint: 'Input dengan error',
          errorText: 'Field ini wajib diisi',
        ),
        SizedBox(height: theme.spacing.sm),
        const MagicInput(
          hint: 'Disabled input',
          enabled: false,
        ),
      ],
    );
  }
}
