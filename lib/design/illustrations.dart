import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'palette.dart';

/// Her ekranın arkasındaki zemin: dikey degrade, sağ üstte soluk ışık, birkaç duran toz zerresi.
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
    final glowCenter = Offset(size.width * .9, size.height * .04);
    canvas.drawCircle(
      glowCenter,
      size.width * .8,
      Paint()
        ..shader = RadialGradient(colors: [
          p.accent.withValues(alpha: p.isDark ? .10 : .12),
          p.accent.withValues(alpha: 0),
        ]).createShader(Rect.fromCircle(center: glowCenter, radius: size.width * .8)),
    );
    final rnd = math.Random(7);
    final dust = Paint()..color = p.ink.withValues(alpha: p.isDark ? .07 : .05);
    for (var i = 0; i < 14; i++) {
      canvas.drawCircle(
        Offset(rnd.nextDouble() * size.width, rnd.nextDouble() * size.height),
        .8 + rnd.nextDouble() * 1.6,
        dust,
      );
    }
  }

  @override
  bool shouldRepaint(_BackdropPainter old) => old.p != p;
}

/// Hikâyenin üstündeki atmosfer şeridi: yaşa göre gökyüzü, ay ya da güneş,
/// üç katman tepe ve sağda soluk büyük yaş rakamı. (Godot: UI/LifeIllustration.cs)
class AtmosphereStrip extends StatelessWidget {
  const AtmosphereStrip({super.key, this.stage = 2, this.numeral = '', this.height = 132});

  /// 0 bebeklik, 1 gençlik, 2 yetişkinlik, 3 olgunluk.
  final int stage;
  final String numeral;
  final double height;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
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
  _AtmospherePainter(this.p, this.stage, this.numeral, this.serif);
  final VitaPalette p;
  final int stage;
  final String numeral;
  final String? serif;

  (Color, Color) get sky => switch ((p.isDark, stage)) {
        (true, 0) => (const Color(0xFF2B2342), const Color(0xFF191427)),
        (true, 1) => (const Color(0xFF242A46), const Color(0xFF161628)),
        (true, 3) => (const Color(0xFF342438), const Color(0xFF1A1522)),
        (true, _) => (const Color(0xFF25213C), const Color(0xFF151325)),
        (false, 0) => (const Color(0xFFFFE9D2), const Color(0xFFFDF6EA)),
        (false, 1) => (const Color(0xFFE7EEFB), const Color(0xFFFBF6EC)),
        (false, 3) => (const Color(0xFFF3E2E4), const Color(0xFFFBF4EA)),
        _ => (const Color(0xFFFFECCD), const Color(0xFFFDF6E9)),
      };

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final (top, bottom) = sky;
    final rect = Offset.zero & size;
    canvas.drawRect(rect, Paint()..color = bottom);
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, h * .74),
      Paint()
        ..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [top, bottom])
            .createShader(Rect.fromLTWH(0, 0, w, h * .74)),
    );

    final disc = Offset(w * .74, h * .30);
    final r = h * .13;
    if (p.isDark) {
      for (var i = 4; i >= 1; i--) {
        canvas.drawCircle(disc, r + i * r * .5, Paint()..color = const Color(0xFFFFF0CF).withValues(alpha: .035));
      }
      canvas.drawCircle(disc, r, Paint()..color = const Color(0xFFFDF2D6));
      // Hilal: gök renginde bir daire ayın bir yanını kapatır.
      canvas.drawCircle(disc + Offset(r * .44, -r * .25), r * .85, Paint()..color = Color.lerp(top, bottom, .35)!);
      for (var i = 0; i < 16; i++) {
        final x = w * (.05 + i * .062);
        final y = h * (.10 + (i % 4) * .085);
        canvas.drawCircle(Offset(x, y), .9 + (i % 3) * .5, Paint()..color = Colors.white.withValues(alpha: .28 + (i % 3) * .08));
      }
    } else {
      for (var i = 4; i >= 1; i--) {
        canvas.drawCircle(disc, r + i * r * .55, Paint()..color = const Color(0xFFF2B35E).withValues(alpha: .05));
      }
      canvas.drawCircle(disc, r * 1.05, Paint()..color = const Color(0xFFF6C272));
    }

    _ridge(canvas, size, h * .62, h * .20, 1.0, p.accent.withValues(alpha: p.isDark ? .10 : .14));
    _ridge(canvas, size, h * .72, h * .16, 1.7, p.isDark ? const Color(0xFF221D33) : const Color(0xFFD9CDB8));
    _ridge(canvas, size, h * .84, h * .12, 2.6, p.isDark ? const Color(0xFF15121F) : const Color(0xFFC6B79E));

    if (numeral.isNotEmpty) {
      final tp = TextPainter(
        text: TextSpan(
          text: numeral,
          style: TextStyle(fontFamily: serif, fontSize: h * .62, height: 1, color: p.ink.withValues(alpha: .10)),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(w - tp.width - 18, h - tp.height + h * .04));
    }
  }

  void _ridge(Canvas canvas, Size size, double baseY, double amp, double freq, Color color) {
    const steps = 26;
    final path = Path()..moveTo(0, size.height);
    for (var i = 0; i <= steps; i++) {
      final t = i / steps;
      final y = baseY -
          math.sin(t * math.pi * freq + freq) * amp * .5 -
          math.cos(t * math.pi * freq * 1.7) * amp * .2;
      path.lineTo(t * size.width, y);
    }
    path
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_AtmospherePainter old) =>
      old.p != p || old.stage != stage || old.numeral != numeral || old.serif != serif;
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
  static const _clothes = [Color(0xFFB9766F), Color(0xFF5D907F), Color(0xFF7E68AB), Color(0xFFB08A4E)];
  static const _skin = Color(0xFFE8C3A6);
  static const _feature = Color(0xFF3B3348);

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide * .46;
    final style = name.codeUnits.fold(0, (a, b) => a + b);
    final hair = grandparent ? const Color(0xFFA9A2B8) : _hairs[style % _hairs.length];
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
        ..color = p.accent.withValues(alpha: alive ? .45 : .2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1.5, r * .06),
    );
  }

  @override
  bool shouldRepaint(_MedallionPainter old) =>
      old.p != p || old.name != name || old.female != female || old.alive != alive || old.grandparent != grandparent;
}
