import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'palette.dart';

/// Her ekranın arkasındaki modern zemin: temiz dikey degrade ve üstte hafif dinamik ambiyans ışığı.
/// Yalnızca boyut ya da tema değişince yeniden çizilir.
class Backdrop extends StatelessWidget {
  const Backdrop({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _BackdropPainter(context.vita),
      child: child,
    );
  }
}

class _BackdropPainter extends CustomPainter {
  _BackdropPainter(this.p);
  final VitaPalette p;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [p.groundTop, p.groundBottom],
        ).createShader(rect),
    );
    final glowTop = Offset(size.width * .85, size.height * .02);
    canvas.drawCircle(
      glowTop,
      size.width * .75,
      Paint()
        ..shader = RadialGradient(colors: [
          p.accent.withValues(alpha: p.isDark ? .12 : .08),
          p.accent.withValues(alpha: 0),
        ]).createShader(Rect.fromCircle(center: glowTop, radius: size.width * .75)),
    );
    final glowLeft = Offset(size.width * .12, size.height * .28);
    canvas.drawCircle(
      glowLeft,
      size.width * .55,
      Paint()
        ..shader = RadialGradient(colors: [
          p.social.withValues(alpha: p.isDark ? .06 : .05),
          p.social.withValues(alpha: 0),
        ]).createShader(Rect.fromCircle(center: glowLeft, radius: size.width * .55)),
    );
  }

  @override
  bool shouldRepaint(_BackdropPainter old) => old.p != p;
}

/// Sosyal Akış & Dinamik Kart üst başlığı:
/// Üstte 4 segmentli Instagram/Reigns tarzı yaşam evresi ilerleme çubuğu,
/// ortada canlı nabız dalgası (pulse wave), sol altta dönem etiketi ve sağda modern yaş rozeti.
class AtmosphereStrip extends StatelessWidget {
  const AtmosphereStrip({super.key, this.stage = 2, this.numeral = '', this.height = 104});

  /// 0 bebeklik, 1 gençlik, 2 yetişkinlik, 3 olgunluk.
  final int stage;
  final String numeral;
  final double height;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: SizedBox(
          height: height,
          width: double.infinity,
          child: CustomPaint(
            painter: _AtmospherePainter(
              context.vita,
              stage,
              numeral,
              GoogleFonts.notoSerif().fontFamily,
            ),
          ),
        ),
      ),
    );
  }
}

class _AtmospherePainter extends CustomPainter {
  _AtmospherePainter(this.p, this.stage, this.numeral, this.fontFamily);
  final VitaPalette p;
  final int stage;
  final String numeral;
  final String? fontFamily;

  static const _stageNames = ['BAŞLANGIÇ & ÇOCUKLUK', 'GENÇLİK AKIŞI', 'YETİŞKİNLİK DÖNEMİ', 'OLGUNLUK & MİRAS'];

  (Color, Color, Color) get _feedColors => switch ((p.isDark, stage)) {
        (true, 0) => (const Color(0xFF172554), const Color(0xFF0F172A), const Color(0xFF38BDF8)),
        (true, 1) => (const Color(0xFF1E1B4B), const Color(0xFF0F172A), const Color(0xFF818CF8)),
        (true, 3) => (const Color(0xFF064E3B), const Color(0xFF0F172A), const Color(0xFF34D399)),
        (true, _) => (const Color(0xFF0C4A6E), const Color(0xFF0F172A), const Color(0xFF38BDF8)),
        (false, 0) => (const Color(0xFFE0F2FE), const Color(0xFFF8FAFC), const Color(0xFF0284C7)),
        (false, 1) => (const Color(0xFFEEF2FF), const Color(0xFFF8FAFC), const Color(0xFF4F46E5)),
        (false, 3) => (const Color(0xFFECFDF5), const Color(0xFFF8FAFC), const Color(0xFF059669)),
        _ => (const Color(0xFFE0F2FE), const Color(0xFFF8FAFC), const Color(0xFF0369A1)),
      };

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final (startBg, endBg, glow) = _feedColors;
    final rect = Offset.zero & size;

    // 1. Modern kart zemini
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [startBg, endBg],
        ).createShader(rect),
    );

    // 2. Sağ üstten yayılan modern neon/akış parıltısı
    final orb = Offset(w * .82, h * .45);
    canvas.drawCircle(
      orb,
      h * 1.1,
      Paint()
        ..shader = RadialGradient(
          colors: [glow.withValues(alpha: p.isDark ? .26 : .18), glow.withValues(alpha: 0)],
        ).createShader(Rect.fromCircle(center: orb, radius: h * 1.1)),
    );

    // 3. Dinamik yaşam nabzı (pulse wave) çizgileri
    _drawPulseWave(canvas, size, h * .65, h * .14, 1.8, glow.withValues(alpha: p.isDark ? .28 : .22), 2.2);
    _drawPulseWave(canvas, size, h * .74, h * .10, 2.7, p.accent.withValues(alpha: p.isDark ? .18 : .14), 1.4);

    // 4. Üstte 4 segmentli Sosyal Hikâye (Story) ilerleme çubuğu
    const segCount = 4;
    const gap = 6.0;
    const padX = 16.0;
    final totalBarW = w - padX * 2 - gap * (segCount - 1);
    final segW = math.max(12.0, totalBarW / segCount);
    final activeStage = stage.clamp(0, segCount - 1);

    for (var i = 0; i < segCount; i++) {
      final left = padX + i * (segW + gap);
      final rrect = RRect.fromRectAndRadius(Rect.fromLTWH(left, 12, segW, 4), const Radius.circular(99));
      final filled = i <= activeStage;
      canvas.drawRRect(
        rrect,
        Paint()
          ..color = filled
              ? (i == activeStage ? glow : glow.withValues(alpha: .65))
              : p.ink.withValues(alpha: p.isDark ? .14 : .12),
      );
    }

    // 5. Sol tarafta canlı akış rozeti + evre başlığı
    final dotCenter = const Offset(22, 34);
    canvas.drawCircle(dotCenter, 4, Paint()..color = p.positive);
    canvas.drawCircle(dotCenter, 7, Paint()..color = p.positive.withValues(alpha: .24));

    final stageLabel = _stageNames[activeStage];
    final badgeTp = TextPainter(
      text: TextSpan(
        text: 'CANLI AKIŞ · $stageLabel',
        style: TextStyle(
          fontFamily: fontFamily,
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.9,
          color: p.ink.withValues(alpha: .88),
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout(maxWidth: w * .68);
    badgeTp.paint(canvas, const Offset(34, 27));

    final subTp = TextPainter(
      text: TextSpan(
        text: numeral.isEmpty ? 'Her seçim yeni bir akış başlatır' : 'Hayat akışı devam ediyor',
        style: TextStyle(
          fontFamily: fontFamily,
          fontSize: 13.5,
          fontWeight: FontWeight.w600,
          color: p.ink.withValues(alpha: .72),
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout(maxWidth: w * .65);
    subTp.paint(canvas, const Offset(16, 48));

    // 6. Sağ tarafta modern yaş kapsülü (numeral varsa)
    if (numeral.isNotEmpty) {
      final ageTp = TextPainter(
        text: TextSpan(
          children: [
            TextSpan(
              text: 'YAŞ ',
              style: TextStyle(
                fontFamily: fontFamily,
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
                color: glow,
              ),
            ),
            TextSpan(
              text: numeral,
              style: TextStyle(
                fontFamily: fontFamily,
                fontSize: 24,
                fontWeight: FontWeight.w900,
                height: 1.0,
                color: p.ink,
              ),
            ),
          ],
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      final pillW = ageTp.width + 24;
      final pillH = ageTp.height + 14;
      final pillRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(w - pillW - 14, (h - pillH) * .56, pillW, pillH),
        const Radius.circular(14),
      );
      canvas.drawRRect(
        pillRect,
        Paint()..color = p.surface.withValues(alpha: p.isDark ? .75 : .88),
      );
      canvas.drawRRect(
        pillRect,
        Paint()
          ..color = glow.withValues(alpha: .45)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2,
      );
      ageTp.paint(canvas, Offset(pillRect.left + 12, pillRect.top + 7));
    }

    // 7. İnce dış çerçeve
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect.deflate(0.5), const Radius.circular(18)),
      Paint()
        ..color = p.border
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  void _drawPulseWave(Canvas canvas, Size size, double baseY, double amp, double freq, Color color, double stroke) {
    const steps = 36;
    final path = Path();
    for (var i = 0; i <= steps; i++) {
      final t = i / steps;
      final y = baseY -
          math.sin(t * math.pi * freq * 2 + 0.8) * amp * .45 -
          math.cos(t * math.pi * freq * 3.2) * amp * .25;
      if (i == 0) {
        path.moveTo(0, y);
      } else {
        path.lineTo(t * size.width, y);
      }
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_AtmospherePainter old) =>
      old.p != p || old.stage != stage || old.numeral != numeral || old.fontFamily != fontFamily;
}

/// Kişi madalyonu: halka içinde sade bir yüz. Hafıza oyunu kişiyi isimsiz ayırt
/// etmeyi gerektirdiği için baş harf yerine yüz çizilir. (Godot: UI/PersonAvatar.cs)
class PersonMedallion extends StatelessWidget {
  const PersonMedallion({
    super.key,
    required this.name,
    this.female = false,
    this.alive = true,
    this.grandparent = false,
    this.size = 56,
  });

  final String name;
  final bool female;
  final bool alive;
  final bool grandparent;
  final double size;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
        child: SizedBox.square(
          dimension: size,
          child: CustomPaint(painter: _MedallionPainter(context.vita, name, female, alive, grandparent)),
        ),
      );
}

class _MedallionPainter extends CustomPainter {
  _MedallionPainter(this.p, this.name, this.female, this.alive, this.grandparent);
  final VitaPalette p;
  final String name;
  final bool female, alive, grandparent;

  static const _hairs = [Color(0xFF8C6F6B), Color(0xFF4B4560), Color(0xFFA98755), Color(0xFF5D4438)];
  static const _clothes = [Color(0xFF0284C7), Color(0xFF059669), Color(0xFF6366F1), Color(0xFFE11D48)];
  static const _skin = Color(0xFFE8C3A6);
  static const _feature = Color(0xFF1E293B);

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide * .46;
    final style = name.codeUnits.fold(0, (a, b) => a + b);
    final hair = grandparent ? const Color(0xFF94A3B8) : _hairs[style % _hairs.length];
    final shirt = alive ? _clothes[style % _clothes.length] : p.muted;

    canvas.drawCircle(c, r, Paint()..color = p.surfaceSunken);
    canvas.save();
    canvas.clipPath(Path()..addOval(Rect.fromCircle(center: c, radius: r - 1)));
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(c.dx - r * .62, c.dy + r * .3, r * 1.24, r * .9), Radius.circular(r * .36)),
      Paint()..color = shirt,
    );
    if (female) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(c.dx - r * .58, c.dy - r * .78, r * 1.16, r * 1.3), Radius.circular(r * .5)),
        Paint()..color = hair,
      );
    }
    canvas.drawCircle(c + Offset(0, -r * .18), r * .46, Paint()..color = _skin);
    canvas.drawArc(
      Rect.fromCircle(center: c + Offset(0, -r * .3), radius: r * .45),
      math.pi,
      math.pi,
      false,
      Paint()
        ..color = hair
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * .22,
    );
    final eye = Paint()..color = _feature;
    canvas.drawCircle(c + Offset(-r * .17, -r * .15), r * .045, eye);
    canvas.drawCircle(c + Offset(r * .17, -r * .15), r * .045, eye);
    canvas.drawArc(
      Rect.fromCircle(center: c + Offset(0, -r * .02), radius: r * .15),
      0,
      math.pi,
      false,
      Paint()
        ..color = _feature
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1.2, r * .05)
        ..strokeCap = StrokeCap.round,
    );
    canvas.restore();
    canvas.drawCircle(
      c,
      r - 1,
      Paint()
        ..color = p.accent.withValues(alpha: alive ? .65 : .25)
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1.8, r * .07),
    );
  }

  @override
  bool shouldRepaint(_MedallionPainter old) =>
      old.p != p || old.name != name || old.female != female || old.alive != alive || old.grandparent != grandparent;
}
