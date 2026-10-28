import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:life_simulation/content/game_content.dart';
import 'package:life_simulation/design/components.dart';
import 'package:life_simulation/design/palette.dart';
import 'package:life_simulation/design/theme.dart';
import 'package:life_simulation/game/billing.dart';
import 'package:life_simulation/game/save.dart';
import 'package:life_simulation/game/session.dart';
import 'package:life_simulation/game/state.dart';
import 'package:life_simulation/main.dart';
import 'package:life_simulation/ui/achievements_screen.dart';
import 'package:life_simulation/ui/game_controller.dart';
import 'package:life_simulation/ui/life_pages.dart';
import 'package:life_simulation/ui/life_summary_panel.dart';
import 'package:life_simulation/ui/story_library_screen.dart';

import 'content_test.dart' show contentPaths, readFile;
import 'monetization_test.dart' show FakeAds, FakeBilling;

void main() {
  late GameContent content;
  late Directory dir;
  late GameSession session;
  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    content = await GameContent.load(contentPaths(), readFile);
  });
  setUp(() {
    dir = Directory.systemTemp.createTempSync('vita_p5_ui_');
    session = GameSession(content, SaveService('${dir.path}/savegame.json'));
  });
  tearDown(() => dir.deleteSync(recursive: true));
  Future<void> tap(WidgetTester tester, Finder finder) async {
    if (finder.evaluate().isEmpty) {
      final scroll = find
          .descendant(
            of: find.byType(ListView).last,
            matching: find.byType(Scrollable),
          )
          .first;
      await tester.dragUntilVisible(
        finder,
        scroll,
        const Offset(0, -220),
        maxIteration: 100,
      );
    }
    await tester.ensureVisible(finder.first);
    await tester.pumpAndSettle();
    await tester.tap(finder.first);
    await tester.pumpAndSettle();
  }

  testWidgets('finished life offers a rewarded second chance and resumes', (
    tester,
  ) async {
    final ads = FakeAds();
    final game = GameController(session, ads: ads)
      ..startNewGame('Deniz', seed: 42);
    addTearDown(game.dispose);
    game.state!
      ..health = 0
      ..isGameOver = true
      ..gameOverReason = GameOverReason.healthDepleted;
    game.acknowledgeMoment();
    await tester.pumpWidget(VitaApp(loadGame: () => SynchronousFuture(game)));
    await tester.pumpAndSettle();
    expect(find.text('BİR HAYATIN ÖZETİ'), findsOneWidget);
    await tap(tester, find.text('İkinci şans · bir reklam'));
    expect(game.state!.health, 20);
    expect(game.state!.secondChanceUsed, isTrue);
    expect(game.state!.isGameOver, isFalse);
    expect(ads.rewards, 1);
    expect(session.saves.load().state!.secondChanceUsed, isTrue);
  });
  testWidgets('menu purchase unlocks only after verified store update', (
    tester,
  ) async {
    final billing = FakeBilling();
    final game = GameController(session, billing: billing)
      ..startNewGame('Deniz', seed: 42);
    addTearDown(game.dispose);
    await game.storyStore.initialize();
    await tester.pumpWidget(VitaApp(loadGame: () => SynchronousFuture(game)));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Menü'));
    await tester.pumpAndSettle();
    await tap(tester, find.text('Reklamları kaldır · ₺10'));
    expect(game.storyStore.adsRemoved, isFalse);
    billing.events.add(
      const BillingUpdate('remove_ads', BillingState.pending, 'Ödeme bekliyor'),
    );
    await tester.pumpAndSettle();
    expect(game.storyStore.adsRemoved, isFalse);
    billing.events.add(
      const BillingUpdate('remove_ads', BillingState.verified, 'Doğrulandı'),
    );
    await tester.pumpAndSettle();
    expect(game.storyStore.adsRemoved, isTrue);
    await tap(tester, find.text('Reklamlar kapalı'));
    expect(tester.takeException(), isNull);
  });
  testWidgets('verified purchase opens the locked story at its saved chapter', (
    tester,
  ) async {
    final billing = FakeBilling();
    final game = GameController(session, billing: billing);
    addTearDown(game.dispose);
    final book = content.stories.values.firstWhere(
      (b) => b.productId.isNotEmpty,
    );
    billing.prices[book.productId] = '₺20';
    await game.storyStore.initialize();
    final progress = game.stories.open(book.id);
    var guard = 100;
    while (game.stories.canRead(book, book.nodes[progress.nodeId]!) &&
        guard-- > 0) {
      final node = book.nodes[progress.nodeId]!;
      final i = node.choices.indexWhere(
        (c) => game.stories.blocked(book, progress, c) == null,
      );
      expect(
        game.stories.choose(book.id, i, expectedNode: progress.nodeId).success,
        isTrue,
      );
    }
    expect(guard, greaterThan(0));
    final saved = progress.nodeId;
    await tester.pumpWidget(
      Motion(
        enabled: false,
        child: MaterialApp(
          theme: buildVitaTheme(VitaPalette.dark),
          home: StoryLibraryScreen(game: game),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.dragUntilVisible(
      find.text(book.title),
      find
          .descendant(
            of: find.byType(ListView).first,
            matching: find.byType(Scrollable),
          )
          .first,
      const Offset(0, -240),
    );
    final card = find
        .ancestor(of: find.text(book.title), matching: find.byType(VitaCard))
        .first;
    await tap(
      tester,
      find.descendant(of: card, matching: find.text('Okumaya devam et')),
    );
    expect(find.text('Hikâyen burada bitmiyor.'), findsOneWidget);
    await tap(tester, find.text('Tam hikâyeyi aç · ₺20'));
    expect(game.storyStore.owns(book.productId), isFalse);
    billing.events.add(
      BillingUpdate(book.productId, BillingState.verified, 'Hikâye açıldı'),
    );
    await tester.pumpAndSettle();
    expect(game.storyStore.owns(book.productId), isTrue);
    expect(progress.nodeId, saved);
    expect(find.byKey(const ValueKey('story-prose')), findsOneWidget);
  });
  for (final width in [320.0, 360.0, 411.0]) {
    testWidgets(
      'P5 screens fit ${width.toInt()} dp in both themes with larger text',
      (tester) async {
        tester.view.physicalSize = Size(width * 3, 780 * 3);
        tester.view.devicePixelRatio = 3;
        addTearDown(tester.view.reset);
        final game = GameController(session)..startNewGame('Deniz', seed: 42);
        addTearDown(game.dispose);
        for (final palette in [VitaPalette.dark, VitaPalette.light]) {
          for (final page in ['menu', 'achievements', 'summary']) {
            game.state!
              ..isGameOver = page == 'summary'
              ..gameOverReason = page == 'summary'
                  ? GameOverReason.healthDepleted
                  : null;
            final child = page == 'menu'
                ? Scaffold(
                    body: LifePage(game: game, page: 'menu', navigate: (_) {}),
                  )
                : page == 'achievements'
                ? AchievementsScreen(game: game)
                : Scaffold(
                    body: ListView(children: [LifeSummaryPanel(game: game)]),
                  );
            await tester.pumpWidget(
              Motion(
                enabled: false,
                child: MaterialApp(
                  key: ValueKey('$page:$width:${palette.isDark}'),
                  theme: buildVitaTheme(palette),
                  builder: (context, child) => MediaQuery(
                    data: MediaQuery.of(context)
                        .copyWith(textScaler: const TextScaler.linear(1.4)),
                    child: child!,
                  ),
                  home: child,
                ),
              ),
            );
            await tester.pumpAndSettle();
            for (var i = 0; i < 12; i++) {
              await tester.drag(
                find.byType(ListView).first,
                const Offset(0, -450),
              );
              await tester.pumpAndSettle();
              expect(
                tester.takeException(),
                isNull,
                reason: '$page $width ${palette.isDark}',
              );
            }
          }
        }
      },
    );
  }
}
