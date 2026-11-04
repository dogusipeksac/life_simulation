import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:life_simulation/content/game_content.dart';
import 'package:life_simulation/design/palette.dart';
import 'package:life_simulation/design/preferences.dart';
import 'package:life_simulation/design/theme.dart';
import 'package:life_simulation/game/save.dart';
import 'package:life_simulation/game/session.dart';
import 'package:life_simulation/ui/game_controller.dart';
import 'package:life_simulation/ui/life_pages.dart';
import 'package:life_simulation/ui/settings_sheet.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    dir = Directory.systemTemp.createTempSync('vita_settings_test_');
    game = GameController(
      GameSession(content, SaveService('${dir.path}/save.json')),
    )..startNewGame('Deniz Yılmaz', seed: 42);
  });

  tearDown(() {
    try {
      dir.deleteSync(recursive: true);
    } catch (_) {}
  });

  testWidgets('SettingsSheet renders all setting sections, review, and share', (tester) async {
    tester.view.physicalSize = const Size(400 * 3, 900 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final prefs = VitaPreferences();

    await tester.pumpWidget(
      MaterialApp(
        theme: buildVitaTheme(VitaPalette.dark),
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => SettingsSheet.show(
                context,
                game: game,
                preferences: prefs,
              ),
              child: const Text('Open Settings'),
            ),
          ),
        ),
      ),
    );

    // Open sheet
    await tester.tap(find.text('Open Settings'));
    await tester.pumpAndSettle();

    // Verify sections and options
    expect(find.text('Ayarlar'), findsWidgets);
    expect(find.text('Dokunma sesleri'), findsOneWidget);
    expect(find.text('Titreşim'), findsOneWidget);
    expect(find.text('Animasyonlar'), findsOneWidget);
    expect(find.text('Karanlık tema'), findsOneWidget);
    expect(find.text('Bizi Değerlendir'), findsOneWidget);
    expect(find.text('Arkadaşlarınla Paylaş'), findsOneWidget);

    // Scroll down if needed to check remaining items
    await tester.scrollUntilVisible(find.text('Açılış ekranına dön'), 100);
    await tester.pumpAndSettle();

    expect(find.text('Gizlilik ve bağlantılar'), findsOneWidget);
    expect(find.text('Açılış ekranına dön'), findsOneWidget);

    // Toggle sound
    await tester.scrollUntilVisible(find.text('Dokunma sesleri'), -100);
    await tester.pumpAndSettle();
    expect(prefs.sound, isTrue);
    await tester.tap(find.text('Dokunma sesleri'));
    await tester.pumpAndSettle();
    expect(prefs.sound, isFalse);
  });

  testWidgets('Profile page has settings button in top right opening SettingsSheet', (tester) async {
    tester.view.physicalSize = const Size(400 * 3, 900 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: buildVitaTheme(VitaPalette.dark),
        home: Scaffold(
          body: LifePage(
            game: game,
            page: 'profile',
            navigate: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify settings icon exists
    final settingsButtons = find.byTooltip('Ayarlar');
    expect(settingsButtons, findsWidgets);

    // Tap the settings button on player card
    await tester.tap(settingsButtons.first);
    await tester.pumpAndSettle();

    // Sheet should be opened
    expect(find.text('Bizi Değerlendir'), findsOneWidget);
    expect(find.text('Arkadaşlarınla Paylaş'), findsOneWidget);
  });
}
