import 'package:flutter/material.dart';
import 'package:magickit/magickit.dart';

class MagicKitStepperExample extends StatefulWidget {
  const MagicKitStepperExample({super.key});

  @override
  State<MagicKitStepperExample> createState() => _MagicKitStepperExampleState();
}

class _MagicKitStepperExampleState extends State<MagicKitStepperExample> {
  int _currentStep = 1;

  static const _steps = [
    MagicStepData(title: 'Akun', description: 'Buat akun baru'),
    MagicStepData(title: 'Profil', description: 'Isi data diri'),
    MagicStepData(title: 'Verifikasi', description: 'Verifikasi email'),
    MagicStepData(title: 'Selesai'),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = MagicTheme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const MagicText('Horizontal (Numbered)', style: MagicTextStyle.label),
        SizedBox(height: theme.spacing.sm),
        MagicStepper(
          steps: _steps,
          currentStep: _currentStep,
          onStepTapped: (index) => setState(() => _currentStep = index),
        ),
        SizedBox(height: theme.spacing.sm),
        Row(
          children: [
            MagicButton(
              label: 'Prev',
              onPressed: _currentStep > 0
                  ? () => setState(() => _currentStep--)
                  : null,
              size: MagicButtonSize.small,
              variant: MagicButtonVariant.outlined,
            ),
            SizedBox(width: theme.spacing.sm),
            MagicButton(
              label: 'Next',
              onPressed: _currentStep < _steps.length - 1
                  ? () => setState(() => _currentStep++)
                  : null,
              size: MagicButtonSize.small,
            ),
          ],
        ),
        SizedBox(height: theme.spacing.md),
        const MagicText('Horizontal (Dots)', style: MagicTextStyle.label),
        SizedBox(height: theme.spacing.sm),
        MagicStepper(
          steps: _steps,
          currentStep: _currentStep,
          type: MagicStepperType.dots,
        ),
        SizedBox(height: theme.spacing.md),
        const MagicText('Vertical', style: MagicTextStyle.label),
        SizedBox(height: theme.spacing.sm),
        const MagicStepper(
          steps: [
            MagicStepData(
              title: 'Pilih Produk',
              description: 'Pilih produk yang ingin dibeli',
              status: MagicStepStatus.completed,
            ),
            MagicStepData(
              title: 'Isi Alamat',
              description: 'Masukkan alamat pengiriman',
              status: MagicStepStatus.active,
            ),
            MagicStepData(
              title: 'Pembayaran',
              description: 'Pilih metode pembayaran',
            ),
            MagicStepData(
              title: 'Konfirmasi',
              status: MagicStepStatus.pending,
            ),
          ],
          currentStep: 1,
          direction: Axis.vertical,
        ),
        SizedBox(height: theme.spacing.md),
        const MagicText('With Error', style: MagicTextStyle.label),
        SizedBox(height: theme.spacing.sm),
        const MagicStepper(
          steps: [
            MagicStepData(title: 'Step 1', status: MagicStepStatus.completed),
            MagicStepData(title: 'Step 2', status: MagicStepStatus.active),
            MagicStepData(title: 'Step 3', status: MagicStepStatus.error),
          ],
          currentStep: 1,
        ),
      ],
    );
  }
}
