import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:life_simulation/main.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  // Taşma testi: 320, 360 ve 411 dp genişlikte, iki temada da hata çıkmamalı.
  for (final size in const [Size(320, 640), Size(360, 780), Size(411, 890)]) {
    testWidgets('stil galerisi ${size.width.toInt()}dp taşmıyor', (tester) async {
      tester.view.physicalSize = size * 3;
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(const VitaApp());
      await tester.pumpAndSettle();
      expect(find.text('Mutfaktaki mektup'), findsOneWidget);

      await tester.drag(find.byType(ListView).first, const Offset(0, -3000));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byType(Switch).first);
      await tester.drag(find.byType(ListView).first, const Offset(0, 200));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(Switch).first);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}
