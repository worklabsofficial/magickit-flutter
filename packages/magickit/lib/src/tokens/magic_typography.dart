import 'package:flutter/painting.dart';

class MagicTypography {
  final TextStyle heading1;
  final TextStyle heading2;
  final TextStyle heading3;
  final TextStyle heading4;
  final TextStyle heading5;
  final TextStyle heading6;
  final TextStyle bodyLarge;
  final TextStyle bodyMedium;
  final TextStyle bodySmall;
  final TextStyle caption;
  final TextStyle label;

  const MagicTypography({
    this.heading1 = const TextStyle(fontSize: 40, fontWeight: FontWeight.w700, letterSpacing: -0.5, height: 1.2),
    this.heading2 = const TextStyle(fontSize: 32, fontWeight: FontWeight.w700, height: 1.25),
    this.heading3 = const TextStyle(fontSize: 24, fontWeight: FontWeight.w600, height: 1.3),
    this.heading4 = const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, height: 1.35),
    this.heading5 = const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, height: 1.4),
    this.heading6 = const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, height: 1.4),
    this.bodyLarge = const TextStyle(fontSize: 16, fontWeight: FontWeight.w400, height: 1.5),
    this.bodyMedium = const TextStyle(fontSize: 14, fontWeight: FontWeight.w400, height: 1.5),
    this.bodySmall = const TextStyle(fontSize: 12, fontWeight: FontWeight.w400, height: 1.5),
    this.caption = const TextStyle(fontSize: 11, fontWeight: FontWeight.w400, height: 1.4),
    this.label = const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, letterSpacing: 0.1, height: 1.4),
  });

  factory MagicTypography.defaultTypography({String? fontFamily}) {
    return MagicTypography(
      heading1: TextStyle(
        fontSize: 40,
        fontWeight: FontWeight.w700,
        fontFamily: fontFamily,
        letterSpacing: -0.5,
        height: 1.2,
      ),
      heading2: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        fontFamily: fontFamily,
        height: 1.25,
      ),
      heading3: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        fontFamily: fontFamily,
        height: 1.3,
      ),
      heading4: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        fontFamily: fontFamily,
        height: 1.35,
      ),
      heading5: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        fontFamily: fontFamily,
        height: 1.4,
      ),
      heading6: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        fontFamily: fontFamily,
        height: 1.4,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        fontFamily: fontFamily,
        height: 1.5,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        fontFamily: fontFamily,
        height: 1.5,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        fontFamily: fontFamily,
        height: 1.5,
      ),
      caption: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w400,
        fontFamily: fontFamily,
        height: 1.4,
      ),
      label: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        fontFamily: fontFamily,
        letterSpacing: 0.1,
        height: 1.4,
      ),
    );
  }
}
