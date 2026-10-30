import 'dart:io';

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
import 'package:life_simulation/ui/game_controller.dart';
import 'package:life_simulation/ui/life_pages.dart';
import 'package:life_simulation/ui/start_screen.dart';
import 'package:life_simulation/ui/story_library_screen.dart';
import 'package:life_simulation/ui/story_screen.dart';

import 'content_test.dart' show contentPaths, readFile;

/// P6 erişilebilirlik geçişi: her ekran, iki temada, 48 dp dokunma hedefi, etiketli
/// dokunulabilir öğe ve metin kontrastı yönergelerini sağlamalı (TalkBack ve WCAG AA).
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
    dir = Directory.systemTemp.createTempSync('vita_a11y_');
    game = GameController(GameSession(content, SaveService('${dir.path}/save.json')))
      ..startNewGame('Deniz Yılmaz', seed: 42);
    game.state!
      ..age = 25
      ..day = 9125
      ..money = 100000
      ..education = 80
      ..educationLevel = Education.university;
    preferences.motion = false;
  });
  tearDown(() {
    dir.deleteSync(recursive: true);
    game.dispose();
  });

  final screens = <String, Widget Function(GameController)>{
    'title': (g) => TitleScreen(game: g),
    'wizard': (g) => CreationWizard(game: g),
    'story': (g) => StoryScreen(game: g),
    'library': (g) => StoryLibraryScreen(game: g),
    for (final page in ['career', 'profile', 'relationships', 'person', 'activities', 'menu', 'finance', 'bank', 'world', 'journal', 'life'])
      page: (g) => Scaffold(body: LifePage(game: g, page: page, personId: 'mother', navigate: (_) {})),
  };

  for (final palette in [VitaPalette.dark, VitaPalette.light]) {
    for (final entry in screens.entries) {
      testWidgets('${entry.key} · ${palette.isDark ? 'koyu' : 'açık'}', (tester) async {
        tester.view.physicalSize = const Size(360 * 3, 780 * 3);
        tester.view.devicePixelRatio = 3;
        addTearDown(tester.view.reset);
        final handle = tester.ensureSemantics();
        await tester.pumpWidget(Motion(
          enabled: false,
          child: MaterialApp(theme: buildVitaTheme(palette), home: entry.value(game)),
        ));
        await tester.pumpAndSettle();
        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
        await expectLater(tester, meetsGuideline(textContrastGuideline));
        handle.dispose();
      });
    }
  }
}
