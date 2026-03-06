class MagicRadius {
  /// 4px
  final double xs;

  /// 8px
  final double sm;

  /// 12px
  final double md;

  /// 16px
  final double lg;

  /// 24px
  final double xl;

  /// 999px — fully rounded (pill/circle)
  final double full;

  const MagicRadius({
    this.xs = 4,
    this.sm = 8,
    this.md = 12,
    this.lg = 16,
    this.xl = 24,
    this.full = 999,
  });
}
