import 'package:flutter/material.dart';

/// "Sosyal Akış & Dinamik Kart" (Modern Feed UI) paleti.
/// Koyu tema: Derin Karbon/Slate + Elektrik Mavi/Camgöbeği.
/// Açık tema: Ferah Buz Grisi Zemin + Saf Beyaz Akış Kartları + Okyanus Mavisi.
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

  // Stat çubukları: sağlık / mutluluk / eğitim / sosyal (canlı modern mobil oyun renkleri).
  Color get health => isDark ? const Color(0xFFFB7185) : const Color(0xFFE11D48);
  Color get happiness => isDark ? const Color(0xFFFBBF24) : const Color(0xFFD97706);
  Color get education => isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB);
  Color get social => isDark ? const Color(0xFF34D399) : const Color(0xFF059669);

  static const dark = VitaPalette(
    isDark: true,
    background: Color(0xFF0B0F19),
    surface: Color(0xFF131B2E),
    surfaceSunken: Color(0xFF1A243B),
    ink: Color(0xFFF8FAFC),
    muted: Color(0xFFA0AEC0),
    border: Color(0xFF263554),
    accent: Color(0xFF38BDF8),
    accentSoft: Color(0xFF152C44),
    positive: Color(0xFF4ADE80),
    negative: Color(0xFFFB7185),
    groundTop: Color(0xFF0F172A),
    groundBottom: Color(0xFF090D16),
  );

  static const light = VitaPalette(
    isDark: false,
    background: Color(0xFFF1F5F9),
    surface: Color(0xFFFFFFFF),
    surfaceSunken: Color(0xFFE2E8F0),
    ink: Color(0xFF0F172A),
    // P6: WCAG AA (>= 4.5:1) kontrast garantisi için yüksek kontrastlı modern tonlar.
    muted: Color(0xFF475569),
    border: Color(0xFFCBD5E1),
    accent: Color(0xFF0369A1),
    accentSoft: Color(0xFFE0F2FE),
    positive: Color(0xFF15803D),
    negative: Color(0xFFB91C1C),
    groundTop: Color(0xFFF8FAFC),
    groundBottom: Color(0xFFE2E8F0),
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
