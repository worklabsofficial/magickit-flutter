import 'package:flutter/material.dart';
import '../tokens/magic_animations.dart';
import '../tokens/magic_breakpoints.dart';
import '../tokens/magic_colors.dart';
import '../tokens/magic_radius.dart';
import '../tokens/magic_shadows.dart';
import '../tokens/magic_spacing.dart';
import '../tokens/magic_theme.dart';
import '../tokens/magic_typography.dart';

extension MagicContextExtensions on BuildContext {
  MagicTheme get theme => MagicTheme.of(this);

  MagicColors get colors => MagicColors.of(this);

  MagicTypography get typography => MagicTheme.of(this).typography;

  MagicSpacing get spacing => MagicTheme.of(this).spacing;

  MagicRadius get radius => MagicTheme.of(this).radius;

  MagicShadows get shadows => MagicTheme.of(this).shadows;

  MagicAnimations get animations => MagicTheme.of(this).animations;

  MagicBreakpoints get breakpoints => MagicTheme.of(this).breakpoints;
}
