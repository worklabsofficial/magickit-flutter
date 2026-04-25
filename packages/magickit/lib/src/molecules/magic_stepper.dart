import 'package:flutter/material.dart';
import '../tokens/magic_theme.dart';

/// Status dari setiap step.
enum MagicStepStatus {
  /// Belum dicapai
  pending,

  /// Sedang aktif
  active,

  /// Sudah selesai
  completed,

  /// Error di step ini
  error,
}

/// Tipe tampilan stepper.
enum MagicStepperType {
  /// Step indicator berupa angka/icon dengan garis penghubung
  numbered,

  /// Step indicator berupa dot kecil
  dots,
}

/// Data untuk satu step.
class MagicStepData {
  /// Judul step.
  final String title;

  /// Deskripsi opsional.
  final String? description;

  /// Custom icon untuk step (default: angka).
  final IconData? icon;

  /// Status step.
  final MagicStepStatus status;

  const MagicStepData({
    required this.title,
    this.description,
    this.icon,
    this.status = MagicStepStatus.pending,
  });

  MagicStepData copyWith({
    String? title,
    String? description,
    IconData? icon,
    MagicStepStatus? status,
  }) {
    return MagicStepData(
      title: title ?? this.title,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      status: status ?? this.status,
    );
  }
}

/// {@magickit}
/// name: MagicStepper
/// category: molecule
/// use_case: Step wizard untuk multi-step form, checkout flow, onboarding
/// visual_keywords: stepper, wizard, step, progress, multi-step, form, checkout, flow
/// {@end}
class MagicStepper extends StatelessWidget {
  /// Daftar step data.
  final List<MagicStepData> steps;

  /// Index step yang aktif saat ini.
  final int currentStep;

  /// Callback saat step diklik.
  final ValueChanged<int>? onStepTapped;

  /// Tipe tampilan stepper.
  final MagicStepperType type;

  /// Direction stepper (horizontal/vertical).
  final Axis direction;

  /// Warna untuk step yang completed.
  final Color? completedColor;

  /// Warna untuk step yang active.
  final Color? activeColor;

  /// Warna untuk step yang pending.
  final Color? pendingColor;

  /// Warna untuk step yang error.
  final Color? errorColor;

  /// Tampilkan connector line antar step.
  final bool showConnector;

  /// Connector line thickness.
  final double connectorThickness;

  const MagicStepper({
    super.key,
    required this.steps,
    this.currentStep = 0,
    this.onStepTapped,
    this.type = MagicStepperType.numbered,
    this.direction = Axis.horizontal,
    this.completedColor,
    this.activeColor,
    this.pendingColor,
    this.errorColor,
    this.showConnector = true,
    this.connectorThickness = 2.0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = MagicTheme.of(context);
    final resolvedCompletedColor = completedColor ?? theme.colors.primary;
    final resolvedActiveColor = activeColor ?? theme.colors.primary;
    final resolvedPendingColor = pendingColor ?? theme.colors.disabled;
    final resolvedErrorColor = errorColor ?? theme.colors.error;

    if (direction == Axis.horizontal) {
      return _buildHorizontal(
        theme,
        resolvedCompletedColor,
        resolvedActiveColor,
        resolvedPendingColor,
        resolvedErrorColor,
      );
    }

    return _buildVertical(
      theme,
      resolvedCompletedColor,
      resolvedActiveColor,
      resolvedPendingColor,
      resolvedErrorColor,
    );
  }

  Widget _buildHorizontal(
    MagicTheme theme,
    Color completedColor,
    Color activeColor,
    Color pendingColor,
    Color errorColor,
  ) {
    return Row(
      children: List.generate(steps.length * 2 - 1, (index) {
        if (index.isOdd && showConnector) {
          // Connector line
          final stepIndex = index ~/ 2;
          final isCompleted = stepIndex < currentStep;
          final connectorColor = isCompleted ? completedColor : pendingColor;

          return Expanded(
            child: Container(
              height: connectorThickness,
              margin: EdgeInsets.symmetric(horizontal: theme.spacing.xs),
              decoration: BoxDecoration(
                color: connectorColor,
                borderRadius: BorderRadius.circular(connectorThickness / 2),
              ),
            ),
          );
        }

        if (index.isOdd) {
          return SizedBox(width: theme.spacing.xs);
        }

        final stepIndex = index ~/ 2;
        return _buildStepIndicator(
          index: stepIndex,
          theme: theme,
          completedColor: completedColor,
          activeColor: activeColor,
          pendingColor: pendingColor,
          errorColor: errorColor,
        );
      }),
    );
  }

  Widget _buildVertical(
    MagicTheme theme,
    Color completedColor,
    Color activeColor,
    Color pendingColor,
    Color errorColor,
  ) {
    return Column(
      children: List.generate(steps.length * 2 - 1, (index) {
        if (index.isOdd && showConnector) {
          final stepIndex = index ~/ 2;
          final isCompleted = stepIndex < currentStep;
          final connectorColor = isCompleted ? completedColor : pendingColor;

          return Container(
            width: connectorThickness,
            height: 24,
            margin: const EdgeInsets.only(left: 15, top: 2, bottom: 2),
            decoration: BoxDecoration(
              color: connectorColor,
              borderRadius: BorderRadius.circular(connectorThickness / 2),
            ),
          );
        }

        if (index.isOdd) {
          return SizedBox(height: theme.spacing.xs);
        }

        final stepIndex = index ~/ 2;
        final step = steps[stepIndex];
        final isActive = stepIndex == currentStep;
        final isCompleted = stepIndex < currentStep;

        return GestureDetector(
          onTap: onStepTapped != null ? () => onStepTapped!(stepIndex) : null,
          behavior: HitTestBehavior.opaque,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildIndicator(
                index: stepIndex,
                step: step,
                theme: theme,
                completedColor: completedColor,
                activeColor: activeColor,
                pendingColor: pendingColor,
                errorColor: errorColor,
                isActive: isActive,
                isCompleted: isCompleted,
              ),
              SizedBox(width: theme.spacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      step.title,
                      style: theme.typography.bodyMedium.copyWith(
                        fontWeight:
                            isActive ? FontWeight.w600 : FontWeight.w400,
                        color: isActive
                            ? activeColor
                            : isCompleted
                                ? completedColor
                                : theme.colors.onSurface,
                      ),
                    ),
                    if (step.description != null) ...[
                      SizedBox(height: theme.spacing.xs / 2),
                      Text(
                        step.description!,
                        style: theme.typography.caption.copyWith(
                          color: theme.colors.disabledForeground,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildStepIndicator({
    required int index,
    required MagicTheme theme,
    required Color completedColor,
    required Color activeColor,
    required Color pendingColor,
    required Color errorColor,
  }) {
    final step = steps[index];
    final isActive = index == currentStep;
    final isCompleted = index < currentStep;

    return GestureDetector(
      onTap: onStepTapped != null ? () => onStepTapped!(index) : null,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildIndicator(
            index: index,
            step: step,
            theme: theme,
            completedColor: completedColor,
            activeColor: activeColor,
            pendingColor: pendingColor,
            errorColor: errorColor,
            isActive: isActive,
            isCompleted: isCompleted,
          ),
          SizedBox(height: theme.spacing.xs),
          Text(
            step.title,
            style: theme.typography.caption.copyWith(
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              color: isActive
                  ? activeColor
                  : isCompleted
                      ? completedColor
                      : theme.colors.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildIndicator({
    required int index,
    required MagicStepData step,
    required MagicTheme theme,
    required Color completedColor,
    required Color activeColor,
    required Color pendingColor,
    required Color errorColor,
    required bool isActive,
    required bool isCompleted,
  }) {
    final isError = step.status == MagicStepStatus.error;

    Color indicatorColor;
    Color textColor;
    Color borderColor;

    if (isError) {
      indicatorColor = errorColor;
      textColor = Colors.white;
      borderColor = errorColor;
    } else if (isCompleted) {
      indicatorColor = completedColor;
      textColor = Colors.white;
      borderColor = completedColor;
    } else if (isActive) {
      indicatorColor = Colors.transparent;
      textColor = activeColor;
      borderColor = activeColor;
    } else {
      indicatorColor = Colors.transparent;
      textColor = pendingColor;
      borderColor = pendingColor;
    }

    if (type == MagicStepperType.dots) {
      return AnimatedContainer(
        duration: theme.animations.fast,
        width: isActive ? 12 : 8,
        height: isActive ? 12 : 8,
        decoration: BoxDecoration(
          color: isCompleted
              ? indicatorColor
              : (isActive ? activeColor : pendingColor),
          shape: BoxShape.circle,
        ),
      );
    }

    // Numbered type
    return AnimatedContainer(
      duration: theme.animations.fast,
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: indicatorColor,
        shape: BoxShape.circle,
        border: Border.all(color: borderColor, width: 2),
      ),
      child: Center(
        child: isCompleted && !isError
            ? Icon(Icons.check, size: 16, color: textColor)
            : isError
                ? Icon(Icons.close, size: 16, color: textColor)
                : step.icon != null
                    ? Icon(step.icon, size: 16, color: textColor)
                    : Text(
                        '${index + 1}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
      ),
    );
  }
}
