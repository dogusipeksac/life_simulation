import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'palette.dart';

/// Tipografi ölçeği: Sosyal Akış & Dinamik Kart stili.
/// Çevrimdışı (allowRuntimeFetching = false) paketlenmiş font testiyle tam uyum için
/// `serif` yalnızca paketlenmiş ağırlıkları (w400, w500, w600) kullanır; kart, karar ve
/// arayüz metinleri ise modern sistem sans-serif ailesini kullanır.
abstract final class VitaType {
  static FontWeight _bundledWeight(FontWeight w) {
    if (w.index >= FontWeight.w600.index) return FontWeight.w600;
    if (w.index == FontWeight.w500.index) return FontWeight.w500;
    return FontWeight.w400;
  }

  static TextStyle serif(double size, Color color, {FontWeight weight = FontWeight.w600, double? height}) =>
      GoogleFonts.notoSerif(
        fontSize: size,
        color: color,
        fontWeight: _bundledWeight(weight),
        height: height,
      );

  static TextStyle display(VitaPalette p) => serif(36, p.ink, weight: FontWeight.w600, height: 1.12);
  static TextStyle title(VitaPalette p) => serif(22, p.ink, weight: FontWeight.w600, height: 1.25);
  static TextStyle cardTitle(VitaPalette p) => serif(18, p.ink, weight: FontWeight.w500, height: 1.3);
  static TextStyle prose(VitaPalette p) => TextStyle(
        fontSize: 16.5,
        color: p.ink,
        fontWeight: FontWeight.w400,
        height: 1.55,
      );
  static TextStyle decision(VitaPalette p) => TextStyle(
        fontSize: 15.5,
        color: p.ink,
        fontWeight: FontWeight.w600,
        height: 1.38,
      );

  static TextStyle body(VitaPalette p) => TextStyle(fontSize: 15, color: p.ink, height: 1.4);
  static TextStyle caption(VitaPalette p) => TextStyle(fontSize: 12, color: p.muted, height: 1.35);
  static TextStyle overline(VitaPalette p, {Color? color}) => TextStyle(
        fontSize: 11,
        letterSpacing: 1.0,
        fontWeight: FontWeight.w700,
        color: color ?? p.accent,
      );
}

ThemeData buildVitaTheme(VitaPalette p) {
  final scheme = ColorScheme.fromSeed(
    seedColor: p.accent,
    brightness: p.isDark ? Brightness.dark : Brightness.light,
  ).copyWith(
    primary: p.accent,
    onPrimary: p.background,
    surface: p.surface,
    onSurface: p.ink,
    outline: p.border,
    error: p.negative,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: p.background,
    extensions: [p],
    splashFactory: InkSparkle.splashFactory,
    textTheme: TextTheme(
      displayLarge: VitaType.display(p),
      titleLarge: VitaType.title(p),
      titleMedium: VitaType.cardTitle(p),
      bodyLarge: VitaType.prose(p),
      bodyMedium: VitaType.body(p),
      bodySmall: VitaType.caption(p),
      labelSmall: VitaType.overline(p),
    ),
    dividerTheme: DividerThemeData(color: p.border, thickness: 1, space: 1),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: p.surface,
      modalBarrierColor: Colors.black.withValues(alpha: .55),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      showDragHandle: true,
      dragHandleColor: p.border,
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? p.background : p.muted),
      trackColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? p.accent : p.surfaceSunken),
      trackOutlineColor: WidgetStatePropertyAll(p.border),
    ),
    pageTransitionsTheme: const PageTransitionsTheme(builders: {
      TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
      TargetPlatform.iOS: FadeForwardsPageTransitionsBuilder(),
    }),
  );
}

/// Türkçe büyük harf: Dart'ın toUpperCase'i 'i'yi 'I' yapar, Türkçede 'İ' olmalı.
String upperTr(String s) => s.replaceAll('i', 'İ').toUpperCase();
