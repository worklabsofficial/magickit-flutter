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
    required this.heading1,
    required this.heading2,
    required this.heading3,
    required this.heading4,
    required this.heading5,
    required this.heading6,
    required this.bodyLarge,
    required this.bodyMedium,
    required this.bodySmall,
    required this.caption,
    required this.label,
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
