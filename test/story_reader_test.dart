import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:life_simulation/content/game_content.dart';
import 'package:life_simulation/design/components.dart';
import 'package:life_simulation/design/palette.dart';
import 'package:life_simulation/design/preferences.dart';
import 'package:life_simulation/design/theme.dart';
import 'package:life_simulation/game/save.dart';
import 'package:life_simulation/game/session.dart';
import 'package:life_simulation/main.dart';
import 'package:life_simulation/ui/game_controller.dart';
import 'package:life_simulation/ui/story_library_screen.dart';

import 'content_test.dart' show contentPaths, readFile;

void main() {
  late GameContent content;
  late Directory dir;
  late GameController game;
  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    content = await GameContent.load(contentPaths(), readFile);
  });
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await preferences.load();
    await preferences.set('motion', false);
    dir = Directory.systemTemp.createTempSync('vita_reader_');
    game = GameController(
      GameSession(content, SaveService('${dir.path}/savegame.json')),
    );
  });
  tearDown(() {
    game.dispose();
    dir.deleteSync(recursive: true);
  });
  Future<void> tap(WidgetTester tester, Finder finder) async {
    if (finder.evaluate().isEmpty) {
      await tester.dragUntilVisible(
        finder,
        find
            .descendant(
              of: find.byType(ListView).last,
              matching: find.byType(Scrollable),
            )
            .first,
        const Offset(0, -200),
        maxIteration: 100,
      );
    }
    await tester.ensureVisible(finder.first);
    await tester.pumpAndSettle();
    await tester.tap(finder.first);
    await tester.pumpAndSettle();
  }

  Future<void> app(WidgetTester tester) async {
    await tester.pumpWidget(LifeSimulationApp(loadGame: () => SynchronousFuture(game)));
    await tester.pumpAndSettle();
    await tap(tester, find.text('Hikâye kütüphanesi'));
  }

  testWidgets(
    'library available from title without life; filters and continue reading',
    (tester) async {
      await app(tester);
      expect(game.inGame, isFalse);
      await tap(tester, find.text('Ücretsiz'));
      final free = content.stories.values.singleWhere(
        (b) => b.productId.isEmpty,
      );
      expect(find.text(free.title), findsOneWidget);
      expect(find.text('Kırık Frekans'), findsNothing);
      await tap(tester, find.text('Hikâyeyi aç'));
      expect(find.byKey(const ValueKey('story-prose')), findsOneWidget);
      await tap(tester, find.byKey(const ValueKey('story-choice-0')));
      expect(game.stories.open(free.id).decisions, 1);
      final current = game.stories.open(free.id).nodeId;
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('Başka bir ihtimal'), findsOneWidget);
      await tap(tester, find.text('Okumaya devam et'));
      expect(game.stories.open(free.id).nodeId, current);
      expect(find.text(free.nodes[current]!.title), findsOneWidget);
      expect(game.inGame, isFalse);
    },
  );
  testWidgets(
    'free story ends, collection and confirmed restart preserve discovered ending',
    (tester) async {
      await app(tester);
      await tap(tester, find.text('Ücretsiz'));
      await tap(tester, find.text('Hikâyeyi aç'));
      final b = content.stories.values.singleWhere((b) => b.productId.isEmpty);
      var guard = 80;
      while (b.nodes[game.stories.open(b.id).nodeId]!.ending.isEmpty &&
          guard-- > 0) {
        final p = game.stories.open(b.id),
            node = b.nodes[game.stories.open(b.id).nodeId]!;
        final i = node.choices.indexWhere(
          (c) => game.stories.blocked(b, p, c) == null,
        );
        await tap(tester, find.byKey(ValueKey('story-choice-$i')));
      }
      expect(guard, greaterThan(0));
      final endings = {...game.stories.open(b.id).endings};
      expect(endings.length, 1);
      await tap(tester, find.text('Başka bir yol dene'));
      expect(find.text('Bu hikâyeyi yeniden başlat?'), findsOneWidget);
      await tap(tester, find.text('Vazgeç'));
      expect(game.stories.open(b.id).endings, endings);
      await tap(tester, find.text('Başka bir yol dene'));
      await tap(tester, find.text('Baştan başlat'));
      expect(game.stories.open(b.id).nodeId, b.start);
      expect(game.stories.open(b.id).endings, endings);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'premium preview reaches paywall with disabled purchase and restore notice',
    (tester) async {
      await app(tester);
      final paid = content.stories.values.firstWhere(
        (b) => b.productId.isNotEmpty,
      );
      // Use the action inside that book card, even when the list builds lazily.
      await tester.dragUntilVisible(
        find.text(paid.title),
        find
            .descendant(
              of: find.byType(ListView).last,
              matching: find.byType(Scrollable),
            )
            .first,
        const Offset(0, -300),
      );
      await tester.ensureVisible(find.text(paid.title));
      await tester.pumpAndSettle();
      final card = find
          .ancestor(of: find.text(paid.title), matching: find.byType(LifeSimulationCard))
          .first;
      await tap(
        tester,
        find.descendant(of: card, matching: find.text('Hikâyeyi aç')),
      );
      var guard = 80;
      while (game.stories.canRead(
            paid,
            paid.nodes[game.stories.open(paid.id).nodeId]!,
          ) &&
          guard-- > 0) {
        final p = game.stories.open(paid.id),
            node = paid.nodes[game.stories.open(paid.id).nodeId]!;
        final i = node.choices.indexWhere(
          (c) => game.stories.blocked(paid, p, c) == null,
        );
        await tap(tester, find.byKey(ValueKey('story-choice-$i')));
      }
      expect(guard, greaterThan(0));
      expect(find.text('Hikâyen burada bitmiyor.'), findsOneWidget);
      expect(find.byKey(const ValueKey('story-prose')), findsNothing);
      final buy = find.widgetWithText(
        VitaButton,
        'Satış bu sürümde henüz açılmadı',
      );
      await tester.ensureVisible(buy);
      await tester.pumpAndSettle();
      expect(tester.widget<VitaButton>(buy).onPressed, isNull);
      final current = game.stories.open(paid.id).nodeId;
      await tap(tester, find.text('Satın alımı geri yükle'));
      expect(game.stories.open(paid.id).nodeId, current);
      expect(game.storyStore.owns(paid.productId), isFalse);
      await tester.drag(find.byType(ListView), const Offset(0, 3000));
      await tester.pumpAndSettle();
      expect(
        find.text(
          'Geri yükleme, satın alımın yapıldığı mağazada kullanılabilir.',
        ),
        findsOneWidget,
      );
    },
  );
  testWidgets('bundled serif fonts load with network fetching disabled', (
    tester,
  ) async {
    GoogleFonts.config.allowRuntimeFetching = false;
    await app(tester);
    await tester.runAsync(() => GoogleFonts.pendingFonts());
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'reading size changes and persists without consuming a decision',
    (tester) async {
      await app(tester);
      await tap(tester, find.text('Ücretsiz'));
      await tap(tester, find.text('Hikâyeyi aç'));
      final before = preferences.readingSize;
      await tap(tester, find.text('A+'));
      expect(preferences.readingSize, before + 3);
      final prefs = VitaPreferences();
      await prefs.load();
      expect(prefs.readingSize, before + 3);
      prefs.dispose();
      expect(game.stories.progress.values.single.decisions, 0);
      await tap(tester, find.text('A−'));
      expect(preferences.readingSize, before);
    },
  );
  for (final width in [320.0, 360.0, 411.0]) {
    testWidgets(
      'library reader and paywall ${width.toInt()}dp both themes large text',
      (tester) async {
        tester.view.physicalSize = Size(width * 3, 780 * 3);
        tester.view.devicePixelRatio = 3;
        addTearDown(tester.view.reset);
        for (final palette in [VitaPalette.dark, VitaPalette.light]) {
          await tester.pumpWidget(
            Motion(
              enabled: false,
              child: MaterialApp(
                theme: buildVitaTheme(palette),
                builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(context)
                      .copyWith(textScaler: TextScaler.linear(1.4)),
                  child: child!,
                ),
                home: StoryLibraryScreen(
                  key: ValueKey(palette.isDark),
                  game: game,
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          await tap(tester, find.text('Ücretsiz'));
          await tap(
            tester,
            find.text(
              game.stories.progress.containsKey(
                    content.stories.values
                        .singleWhere((b) => b.productId.isEmpty)
                        .id,
                  )
                  ? 'Okumaya devam et'
                  : 'Hikâyeyi aç',
            ),
          );
          await tap(tester, find.text('A+'));
          await tap(tester, find.text('A+'));
          await tap(tester, find.text('A+'));
          await tap(tester, find.text('A+'));
          await tester.drag(find.byType(ListView), const Offset(0, -3000));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          await tester.tap(find.byTooltip('Hikâye kütüphanesi'));
          await tester.pumpAndSettle();
          await tap(tester, find.text('Tümü'));
          for (var i = 0; i < 8; i++) {
            await tester.drag(find.byType(ListView), const Offset(0, -400));
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
          }
          final paid = content.stories.values.firstWhere(
            (b) => b.productId.isNotEmpty,
          );
          final p = game.stories.open(paid.id);
          var guard = 100;
          while (game.stories.canRead(paid, paid.nodes[p.nodeId]!) &&
              guard-- > 0) {
            final node = paid.nodes[p.nodeId]!;
            final i = node.choices.indexWhere(
              (c) => game.stories.blocked(paid, p, c) == null,
            );
            game.stories.choose(paid.id, i, expectedNode: p.nodeId);
          }
          await tester.drag(find.byType(ListView), const Offset(0, 10000));
          await tester.pumpAndSettle();
          await tester.dragUntilVisible(
            find.text(paid.title),
            find
                .descendant(
                  of: find.byType(ListView).last,
                  matching: find.byType(Scrollable),
                )
                .first,
            const Offset(0, -300),
          );
          final paidCard = find
              .ancestor(
                of: find.text(paid.title),
                matching: find.byType(LifeSimulationCard),
              )
              .first;
          final open = find.descendant(
            of: paidCard,
            matching: find.byWidgetPredicate(
              (w) =>
                  w is VitaButton &&
                  ['Hikâyeyi aç', 'Okumaya devam et'].contains(w.label),
            ),
          );
          await tap(tester, open);
          expect(find.text('Hikâyen burada bitmiyor.'), findsOneWidget);
          for (var i = 0; i < 4; i++) {
            await tester.drag(find.byType(ListView), const Offset(0, -500));
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
          }
        }
      },
    );
  }
}
