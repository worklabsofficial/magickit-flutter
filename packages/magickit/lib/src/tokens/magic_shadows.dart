import 'package:flutter/painting.dart';

class MagicShadows {
  final List<BoxShadow> none;
  final List<BoxShadow> sm;
  final List<BoxShadow> md;
  final List<BoxShadow> lg;
  final List<BoxShadow> xl;

  const MagicShadows({
    this.none = const [],
    this.sm = const [BoxShadow(color: Color(0x14000000), blurRadius: 4, offset: Offset(0, 1))],
    this.md = const [BoxShadow(color: Color(0x1A000000), blurRadius: 8, offset: Offset(0, 2))],
    this.lg = const [BoxShadow(color: Color(0x1F000000), blurRadius: 16, offset: Offset(0, 4))],
    this.xl = const [BoxShadow(color: Color(0x29000000), blurRadius: 32, offset: Offset(0, 8))],
  });

  factory MagicShadows.defaultShadows() {
    return const MagicShadows(
      sm: [
        BoxShadow(
          color: Color(0x14000000),
          blurRadius: 4,
          offset: Offset(0, 1),
        ),
      ],
      md: [
        BoxShadow(
          color: Color(0x1A000000),
          blurRadius: 8,
          offset: Offset(0, 2),
        ),
      ],
      lg: [
        BoxShadow(
          color: Color(0x1F000000),
          blurRadius: 16,
          offset: Offset(0, 4),
        ),
      ],
      xl: [
        BoxShadow(
          color: Color(0x29000000),
          blurRadius: 32,
          offset: Offset(0, 8),
        ),
      ],
    );
  }
}
