import 'package:flutter/material.dart';

/// Design token untuk animasi durations dan curves.
///
/// Memberikan konsistensi motion design across semua MagicKit components.
///
/// ```dart
/// AnimatedContainer(
///   duration: MagicTheme.of(context).animations.normal,
///   curve: MagicTheme.of(context).animations.curveDefault,
///   child: child,
/// );
/// ```
class MagicAnimations {
  /// Duration sangat cepat — micro-interactions (50ms)
  final Duration fastest;

  /// Duration cepat — button press, toggle (150ms)
  final Duration fast;

  /// Duration normal — default untuk sebagian besar animasi (250ms)
  final Duration normal;

  /// Duration lambat — page transitions, modal (350ms)
  final Duration slow;

  /// Duration sangat lambat — complex animations (500ms)
  final Duration slowest;

  /// Default curve — standard easing
  final Curve curveDefault;

  /// Decelerate curve — untuk elemen yang masuk ke layar
  final Curve curveDecelerate;

  /// Accelerate curve — untuk elemen yang keluar dari layar
  final Curve curveAccelerate;

  /// Emphasized curve — untuk motion yang menarik perhatian
  final Curve curveEmphasized;

  /// Bounce curve — playful bounce effect
  final Curve curveBounce;

  /// Spring curve — natural spring motion
  final Curve curveSpring;

  const MagicAnimations({
    this.fastest = const Duration(milliseconds: 50),
    this.fast = const Duration(milliseconds: 150),
    this.normal = const Duration(milliseconds: 250),
    this.slow = const Duration(milliseconds: 350),
    this.slowest = const Duration(milliseconds: 500),
    this.curveDefault = Curves.easeInOut,
    this.curveDecelerate = Curves.decelerate,
    this.curveAccelerate = Curves.easeIn,
    this.curveEmphasized = Curves.easeInOutCubicEmphasized,
    this.curveBounce = Curves.bounceOut,
    this.curveSpring = Curves.elasticOut,
  });

  /// Default animations instance.
  factory MagicAnimations.defaults() => const MagicAnimations();

  MagicAnimations copyWith({
    Duration? fastest,
    Duration? fast,
    Duration? normal,
    Duration? slow,
    Duration? slowest,
    Curve? curveDefault,
    Curve? curveDecelerate,
    Curve? curveAccelerate,
    Curve? curveEmphasized,
    Curve? curveBounce,
    Curve? curveSpring,
  }) {
    return MagicAnimations(
      fastest: fastest ?? this.fastest,
      fast: fast ?? this.fast,
      normal: normal ?? this.normal,
      slow: slow ?? this.slow,
      slowest: slowest ?? this.slowest,
      curveDefault: curveDefault ?? this.curveDefault,
      curveDecelerate: curveDecelerate ?? this.curveDecelerate,
      curveAccelerate: curveAccelerate ?? this.curveAccelerate,
      curveEmphasized: curveEmphasized ?? this.curveEmphasized,
      curveBounce: curveBounce ?? this.curveBounce,
      curveSpring: curveSpring ?? this.curveSpring,
    );
  }
}
