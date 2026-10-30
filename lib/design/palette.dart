import 'package:flutter/material.dart';

/// "Gece kitabı" paleti. Koyu tema varsayılan, açık tema "kâğıt".
@immutable
class VitaPalette extends ThemeExtension<VitaPalette> {
  const VitaPalette({
    required this.isDark,
    required this.background,
    required this.surface,
    required this.surfaceSunken,
    required this.ink,
    required this.muted,
    required this.border,
    required this.accent,
    required this.accentSoft,
    required this.positive,
    required this.negative,
    required this.groundTop,
    required this.groundBottom,
  });

  final bool isDark;
  final Color background;
  final Color surface;
  final Color surfaceSunken;
  final Color ink;
  final Color muted;
  final Color border;
  final Color accent;
  final Color accentSoft;
  final Color positive;
  final Color negative;
  final Color groundTop;
  final Color groundBottom;

  // Stat çubukları: sağlık / mutluluk / eğitim / sosyal.
  Color get health => isDark ? const Color(0xFFD98C86) : const Color(0xFFB65049);
  Color get happiness => isDark ? const Color(0xFFE6C27A) : const Color(0xFFB27C25);
  Color get education => isDark ? const Color(0xFF8FA8DE) : const Color(0xFF41609E);
  Color get social => isDark ? const Color(0xFF8CC7A6) : const Color(0xFF3F7F5E);

  static const dark = VitaPalette(
    isDark: true,
    background: Color(0xFF100E18),
    surface: Color(0xFF1A1726),
    surfaceSunken: Color(0xFF241F33),
    ink: Color(0xFFEFEAE0),
    muted: Color(0xFF9C93A8),
    border: Color(0xFF302A42),
    accent: Color(0xFFE0B472),
    accentSoft: Color(0xFF2B2338),
    positive: Color(0xFF7FBE93),
    negative: Color(0xFFD97E79),
    groundTop: Color(0xFF191325),
    groundBottom: Color(0xFF0B0A12),
  );

  static const light = VitaPalette(
    isDark: false,
    background: Color(0xFFF3EDE2),
    surface: Color(0xFFFFFCF7),
    surfaceSunken: Color(0xFFEDE5D7),
    ink: Color(0xFF241F2B),
    // P6: WCAG AA (4,5:1) için tasarım değerleri 7C7488 / A9682B / 3F7F55'ten aynı tonda koyulaştırıldı.
    muted: Color(0xFF696374),
    border: Color(0xFFE3D9C9),
    accent: Color(0xFF905825),
    accentSoft: Color(0xFFF3E7D4),
    positive: Color(0xFF38714C),
    negative: Color(0xFFB4453C),
    groundTop: Color(0xFFFBF6EC),
    groundBottom: Color(0xFFECE3D4),
  );

  @override
  VitaPalette copyWith() => this;

  @override
  VitaPalette lerp(ThemeExtension<VitaPalette>? other, double t) {
    if (other is! VitaPalette) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return VitaPalette(
      isDark: t < .5 ? isDark : other.isDark,
      background: l(background, other.background),
      surface: l(surface, other.surface),
      surfaceSunken: l(surfaceSunken, other.surfaceSunken),
      ink: l(ink, other.ink),
      muted: l(muted, other.muted),
      border: l(border, other.border),
      accent: l(accent, other.accent),
      accentSoft: l(accentSoft, other.accentSoft),
      positive: l(positive, other.positive),
      negative: l(negative, other.negative),
      groundTop: l(groundTop, other.groundTop),
      groundBottom: l(groundBottom, other.groundBottom),
    );
  }
}

extension VitaContext on BuildContext {
  VitaPalette get vita => Theme.of(this).extension<VitaPalette>()!;
}
