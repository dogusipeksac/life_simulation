import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:life_simulation/content/game_content.dart';
import 'package:life_simulation/content/models.dart';
import 'package:life_simulation/design/components.dart';
import 'package:life_simulation/design/palette.dart';
import 'package:life_simulation/design/preferences.dart';
import 'package:life_simulation/design/theme.dart';
import 'package:life_simulation/game/save.dart';
import 'package:life_simulation/game/session.dart';
import 'package:life_simulation/main.dart';
import 'package:life_simulation/ui/game_controller.dart';
import 'package:life_simulation/ui/life_pages.dart';
import 'package:life_simulation/ui/mini_game.dart';

import 'content_test.dart' show contentPaths, readFile;

void main() {
  late GameContent content;
  late Directory dir;
  late GameController game;
  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    content = await GameContent.load(contentPaths(), readFile);
  });
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    dir = Directory.systemTemp.createTempSync('vita_p3_ui_');
    game = GameController(
      GameSession(content, SaveService('${dir.path}/save.json')),
    )..startNewGame('Deniz Yılmaz', seed: 42);
    game.state!
      ..age = 25
      ..day = 9125
      ..money = 100000
      ..education = 80
      ..educationLevel = Education.university;
    preferences.dark = true;
    preferences.motion = false;
  });
  tearDown(() {
    dir.deleteSync(recursive: true);
    game.dispose();
  });

  Future<void> tap(WidgetTester tester, String label) async {
    if (find.text(label).evaluate().isEmpty)
      await tester.dragUntilVisible(
        find.text(label),
        find.byType(Scrollable).last,
        const Offset(0, -250),
        maxIteration: 80,
      );
    await tester.ensureVisible(find.text(label).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text(label).first);
    await tester.pumpAndSettle();
  }

  for (final width in [320.0, 360.0, 411.0]) {
    testWidgets('P3 pages ${width.toInt()}dp in both themes and large text', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width * 3, 780 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      for (final palette in [VitaPalette.dark, VitaPalette.light]) {
        for (final page in [
          'career',
          'profile',
          'relationships',
          'person',
          'activities',
          'menu',
          'finance',
          'bank',
          'world',
          'journal',
          'life',
        ]) {
          await tester.pumpWidget(
            Motion(
              enabled: false,
              child: MaterialApp(
                theme: buildVitaTheme(palette),
                home: MediaQuery(
                  data: MediaQueryData(
                    size: Size(width, 780),
                    textScaler: TextScaler.linear(1.4),
                  ),
                  child: Scaffold(
                    body: LifePage(
                      key: ValueKey('$page:${palette.isDark}'),
                      game: game,
                      page: page,
                      personId: 'mother',
                      navigate: (_) {},
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          // Visit every lazily built item and report overflow/painting errors.
          for (var i = 0; i < 20; i++) {
            await tester.drag(
              find.byType(ListView).first,
              const Offset(0, -500),
            );
            await tester.pumpAndSettle();
            expect(
              tester.takeException(),
              isNull,
              reason: '$page, $width, dark=${palette.isDark}',
            );
          }
        }
      }
    });
  }
  testWidgets(
    'tabs, relationship action, menu bank and back preserve pending story',
    (tester) async {
      final eventId = game.event!.id;
      await tester.pumpWidget(VitaApp(loadGame: () => SynchronousFuture(game)));
      await tester.pumpAndSettle();
      await tap(tester, 'Kariyer');
      expect(find.text('Geleceğini şekillendir'), findsOneWidget);
      await tap(tester, 'İlişkiler');
      await tap(tester, game.state!.relationships.first.name);
      final bond = game.state!.relationships.first.bond;
      await tap(tester, 'Birlikte vakit geçir');
      expect(game.state!.relationships.first.bond, bond + 8);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('Hayatındaki insanlar'), findsOneWidget);
      await tester.tap(find.byTooltip('Menü'));
      await tester.pumpAndSettle();
      await tap(tester, 'Finans & banka');
      await tap(tester, 'Banka hesabı');
      await tester.enterText(find.byType(TextField), '1000');
      await tap(tester, 'Bankaya yatır');
      expect(game.state!.bankBalance, 1000);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(tester.widget<LifePage>(find.byType(LifePage)).page, 'finance');
      await tap(tester, 'Hikâye');
      expect(game.event!.id, eventId);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(tester.widget<LifePage>(find.byType(LifePage)).page, 'menu');
    },
  );
  testWidgets('mini game plays five rounds and cannot grant a second reward', (
    tester,
  ) async {
    final token = game.startMiniGame('balls').message;
    final before = game.state!.happiness;
    await tester.pumpWidget(
      MaterialApp(
        theme: buildVitaTheme(VitaPalette.dark),
        home: MiniGameScreen(game: game, kind: 'balls', token: token),
      ),
    );
    await tester.pumpAndSettle();
    for (var round = 0; round < 5; round++) {
      await tap(tester, 'Mor kutu');
      if (round < 4) await tap(tester, 'Sonraki tur');
    }
    expect(game.state!.happiness, before + 2);
    expect(game.finishMiniGame(token, 5).success, isFalse);
  });
  test('preferences persist across a fresh instance', () async {
    final a = VitaPreferences();
    await a.load();
    for (final key in ['dark', 'motion', 'haptics', 'sound']) {
      await a.set(key, false);
    }
    final b = VitaPreferences();
    await b.load();
    expect([b.dark, b.motion, b.haptics, b.sound], everyElement(isFalse));
    a.dispose();
    b.dispose();
  });
}
