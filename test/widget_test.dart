import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:life_simulation/content/game_content.dart';
import 'package:life_simulation/design/components.dart';
import 'package:life_simulation/game/save.dart';
import 'package:life_simulation/game/session.dart';
import 'package:life_simulation/main.dart';
import 'package:life_simulation/ui/game_controller.dart';

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

    testWidgets('açılış ve sihirbaz ${w}dp', (tester) async {
      await sized(tester, size);
      final game = controller();
      await tester.pumpWidget(LifeSimulationApp(loadGame: () => SynchronousFuture(game)));
      await tester.pumpAndSettle();
      // Açılışta yalnızca iki eylem: devam et ya da yeni bir hayata başla.
      expect(find.text('Hikâye kütüphanesi'), findsNothing);
      await tapText(tester, 'Yeni bir hayata başla');
      // Ad önerilmiş gelir; oyuncu değiştirebilir.
      final suggested = tester.widget<TextField>(find.byType(TextField).first).controller!.text;
      expect(suggested, isNotEmpty);
      await tester.enterText(find.byType(TextField).first, 'Deniz Yılmaz');
      // Odaktaki alan imleci görünür tutmak için listeyi geri kaydırır; klavyeyi kapat.
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      await tapText(tester, 'Kaderimi göster');
      expect(find.text('Kaderin'), findsOneWidget);
      expect(find.textContaining('yeniden at'), findsNothing, reason: 'kader yeniden atılamaz');
      await tapText(tester, 'Hayata başla');
      expect(game.state!.playerName, 'Deniz Yılmaz');
      expect(game.inGame, isTrue);
      expect(find.text('NE YAPARSIN?'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('hikâye → sonuç → hikâye ${w}dp', (tester) async {
      await sized(tester, size);
      final game = controller()..startNewGame('Deniz', seed: 9);
      await tester.pumpWidget(LifeSimulationApp(loadGame: () => SynchronousFuture(game)));
      await tester.pumpAndSettle();
      var moments = 0;
      for (var round = 0; round < 6; round++) {
        // Sahnenin başında bir an varsa önce o oynanır (burada geçilir).
        if (find.text('Bu anı geç').evaluate().isNotEmpty) {
          moments++;
          await tapText(tester, 'Bu anı geç');
          expect(find.text('BU ANDA'), findsOneWidget);
        }
        // Süreli anda pumpAndSettle süreyi bitirip kararı kendiliğinden verebilir.
        if (find.text('SONUÇ').evaluate().isEmpty) {
          final card = find.byType(DecisionCard).first;
          await tester.ensureVisible(card);
          await tester.pumpAndSettle();
          if (find.byType(DecisionCard).evaluate().isNotEmpty) {
            await tester.tap(find.byType(DecisionCard).first);
            await tester.pumpAndSettle();
          }
        }
        expect(find.text('SONUÇ'), findsOneWidget);
        // Sakin dönemler de sonuç sayfası gösterir; karar gelene kadar devam.
        while (find.text('SONUÇ').evaluate().isNotEmpty) {
          await tapText(tester, 'Hikâyeye devam et');
        }
      }
      expect(game.state!.totalChoices, 6);
      expect(moments, greaterThan(0), reason: 'ilk yıllarda en az bir an oynanmalı');
      expect(File('${tmp.path}/savegame.json').existsSync(), isTrue);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('bozuk kayıtta Türkçe açıklama', (tester) async {
    File('${tmp.path}/savegame.json').writeAsStringSync('bozuk');
    final game = controller();
    await tester.pumpWidget(LifeSimulationApp(loadGame: () => SynchronousFuture(game)));
    await tester.pumpAndSettle();
    await tapText(tester, 'Kaldığın yerden devam et');
    expect(find.text(corruptedSaveMessage), findsOneWidget);
  });
}
