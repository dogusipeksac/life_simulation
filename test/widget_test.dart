import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:life_simulation/content/game_content.dart';
import 'package:life_simulation/design/components.dart';
import 'package:life_simulation/design/palette.dart';
import 'package:life_simulation/design/theme.dart';
import 'package:life_simulation/game/save.dart';
import 'package:life_simulation/game/session.dart';
import 'package:life_simulation/main.dart';
import 'package:life_simulation/ui/game_controller.dart';
import 'package:life_simulation/ui/style_gallery.dart';

import 'content_test.dart' show contentPaths, readFile;

void main() {
  late GameContent content;
  late Directory tmp;

  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    content = await GameContent.load(contentPaths(), readFile);
  });
  setUp(() => tmp = Directory.systemTemp.createTempSync('vita_ui_'));
  tearDown(() => tmp.deleteSync(recursive: true));

  GameController controller() => GameController(GameSession(content, SaveService('${tmp.path}/savegame.json')));

  Future<void> sized(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
  }

  Future<void> tapText(WidgetTester tester, String text) async {
    // ListView öğeleri tembel kurulur; küçük ekranda önce kaydırmak gerekir.
    if (find.text(text).evaluate().isEmpty) {
      await tester.dragUntilVisible(find.text(text), find.byType(Scrollable).last, const Offset(0, -200));
    }
    await tester.ensureVisible(find.text(text).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text(text).first);
    await tester.pumpAndSettle();
  }

  // Taşma testi: 320, 360 ve 411 dp genişlikte hiçbir ekranda hata çıkmamalı.
  for (final size in const [Size(320, 640), Size(360, 780), Size(411, 890)]) {
    final w = size.width.toInt();

    testWidgets('stil galerisi ${w}dp', (tester) async {
      await sized(tester, size);
      for (final palette in [VitaPalette.dark, VitaPalette.light]) {
        await tester.pumpWidget(MaterialApp(
          theme: buildVitaTheme(palette),
          home: StyleGallery(dark: palette.isDark, motion: true, onDarkChanged: (_) {}, onMotionChanged: (_) {}),
        ));
        await tester.pumpAndSettle();
        await tester.drag(find.byType(ListView).first, const Offset(0, -3000));
        await tester.pumpAndSettle();
      }
      expect(tester.takeException(), isNull);
    });

    testWidgets('açılış ve sihirbaz ${w}dp', (tester) async {
      await sized(tester, size);
      final game = controller();
      await tester.pumpWidget(LifeSimulationApp(loadGame: () => SynchronousFuture(game)));
      await tester.pumpAndSettle();
      await tapText(tester, 'Yeni bir hayat');
      await tester.enterText(find.byType(TextField).first, 'Deniz Yılmaz');
      for (var i = 0; i < 3; i++) {
        await tapText(tester, 'Devam');
      }
      expect(find.text('4 / 4'), findsOneWidget);
      await tapText(tester, 'Hayata başla');
      expect(game.inGame, isTrue);
      expect(find.text('NE YAPARSIN?'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('hikâye → sonuç → hikâye ${w}dp', (tester) async {
      await sized(tester, size);
      final game = controller()..startNewGame('Deniz', seed: 9);
      await tester.pumpWidget(LifeSimulationApp(loadGame: () => SynchronousFuture(game)));
      await tester.pumpAndSettle();
      for (var round = 0; round < 6; round++) {
        final card = find.byType(DecisionCard).first;
        await tester.ensureVisible(card);
        await tester.pumpAndSettle();
        await tester.tap(card);
        await tester.pumpAndSettle();
        expect(find.text('SONUÇ'), findsOneWidget);
        // Sakin dönemler de sonuç sayfası gösterir; karar gelene kadar devam.
        while (find.text('SONUÇ').evaluate().isNotEmpty) {
          await tapText(tester, 'Hikâyeye devam et');
        }
      }
      expect(game.state!.totalChoices, 6);
      expect(File('${tmp.path}/savegame.json').existsSync(), isTrue);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('bozuk kayıtta Türkçe açıklama', (tester) async {
    File('${tmp.path}/savegame.json').writeAsStringSync('bozuk');
    final game = controller();
    await tester.pumpWidget(LifeSimulationApp(loadGame: () => SynchronousFuture(game)));
    await tester.pumpAndSettle();
    await tapText(tester, 'Kayıtlı hayata devam et');
    expect(find.text(corruptedSaveMessage), findsOneWidget);
  });
}
