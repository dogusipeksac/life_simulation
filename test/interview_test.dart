import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:life_simulation/content/content_validator.dart';
import 'package:life_simulation/content/game_content.dart';
import 'package:life_simulation/content/models.dart';
import 'package:life_simulation/design/components.dart';
import 'package:life_simulation/design/palette.dart';
import 'package:life_simulation/design/theme.dart';
import 'package:life_simulation/game/interview.dart';
import 'package:life_simulation/game/save.dart';
import 'package:life_simulation/game/session.dart';
import 'package:life_simulation/game/state.dart';
import 'package:life_simulation/ui/interview_screen.dart';
import 'package:life_simulation/ui/intro_screen.dart';

import 'content_test.dart' show contentPaths, readFile;

void main() {
  late GameContent content;
  late Directory dir;
  late GameSession game;
  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    content = await GameContent.load(contentPaths(), readFile);
  });
  setUp(() {
    dir = Directory.systemTemp.createTempSync('vita_interview_');
    game = GameSession(content, SaveService('${dir.path}/save.json'))..startNewGame('Deniz', seed: 42);
  });
  tearDown(() => dir.deleteSync(recursive: true));
  GameState adult() => game.state!
    ..age = 25
    ..day = 9125
    ..pendingEventId = null
    ..educationLevel = Education.university
    ..education = 80
    ..social = 70
    ..health = 80;
  Career career(String id) => content.careers[id]!;

  int best(InterviewQuestion q) =>
      q.answers.indexed.reduce((a, b) => b.$2.score > a.$2.score ? b : a).$1;
  int worst(InterviewQuestion q) =>
      q.answers.indexed.reduce((a, b) => b.$2.score < a.$2.score ? b : a).$1;

  test('every career theme has its own questions; one general plus two themed', () {
    expect(content.interviews.length, greaterThanOrEqualTo(36));
    for (final c in content.careers.values) {
      final iv = Interview.create(content, adult(), c);
      expect(iv.questions.length, 3);
      expect(iv.questions.first.theme, '');
      expect(iv.questions.skip(1).every((q) => q.theme == c.theme), isTrue, reason: c.id);
      expect(Interview.create(content, game.state!, c).questions.map((q) => q.id),
          iv.questions.map((q) => q.id), reason: 'aynı dönemde aynı sorular');
    }
  });

  test('good interview raises chance, bad one rejects and sets cooldown', () {
    final s = adult();
    final c = content.careers.values.firstWhere((c) => game.progression.blockers(s, c).isEmpty);
    final good = Interview.create(content, s, c);
    while (!good.done) {
      good.answer(s, best(good.current!));
    }
    expect(good.bonus, greaterThan(0));
    final bad = Interview.create(content, s, c);
    while (!bad.done) {
      bad.answer(s, worst(bad.current!));
    }
    expect(bad.rejected, isTrue);
    final r = game.applyCareer(c.id, interview: bad);
    expect(r.success, isFalse);
    expect(s.careerId, isNull);
    expect(s.careerApplicationDay[c.id], s.day);
  });

  test('stat-gated answer is caught as a bluff when the stat is too low', () {
    final s = adult()..education = 0;
    final q = content.interviews.firstWhere((q) => q.answers.any((a) => a.statName == 'Education'));
    final i = q.answers.indexWhere((a) => a.statName == 'Education');
    final iv = Interview(career('barista'), [q]);
    final r = iv.answer(s, i);
    expect(r.bluff, isTrue);
    expect(r.score, -1);
    expect(r.text, q.answers[i].failReply);
  });

  test('validator rejects unknown theme and missing safe answer', () async {
    final raw = await GameContent.readRaw(contentPaths(), readFile);
    raw.interviews.first['Theme'] = 'Uzay Korsanlığı';
    (raw.interviews[1]['Answers'] as List)
      ..clear()
      ..addAll([
        {'Text': 'a', 'Score': -1, 'Reply': 'r'},
        {'Text': 'b', 'Score': 2, 'Reply': 'r', 'Stat': 'Education', 'Min': 50, 'FailReply': 'f'},
      ]);
    final errors = validateContent(raw).errors;
    expect(errors, contains(contains("'Uzay Korsanlığı' hiçbir meslekte yok")));
    expect(errors, contains(contains('koşulsuz, zarar vermeyen')));
  });

  testWidgets('interview screen: answer, see reaction, finish with verdict', (tester) async {
    final s = adult();
    final c = career('barista');
    Interview? result;
    await tester.pumpWidget(Motion(
      enabled: false,
      child: MaterialApp(
        theme: buildVitaTheme(VitaPalette.dark),
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async => result = await runInterview(context, Interview.create(content, s, c), s),
            child: const Text('Başvur'),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('Başvur'));
    await tester.pumpAndSettle();
    for (var i = 0; i < 3; i++) {
      expect(find.text('SORU ${i + 1} / 3'), findsOneWidget);
      await tester.tap(find.byType(DecisionCard).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text(i == 2 ? 'Görüşmeyi bitir' : 'Sonraki soru'));
      await tester.pumpAndSettle();
    }
    expect(find.text('GÖRÜŞME BİTTİ'), findsOneWidget);
    await tester.tap(find.text('Sonucu öğren'));
    await tester.pumpAndSettle();
    expect(result?.done, isTrue);
    expect(tester.takeException(), isNull);
  });

  test('intro deck: first launch shows all pages, update shows only new ones', () {
    final raw = jsonDecode(File('assets/intro/intro.json').readAsStringSync()) as Map<String, Object?>;
    final deck = IntroDeck([
      for (final p in raw['Pages'] as List) IntroPage.fromJson((p as Map).cast<String, Object?>()),
      IntroPage.fromJson({'Id': 'yeni', 'Since': 99, 'Title': 'Yeni', 'Body': 'b'}),
    ]);
    expect(deck.pages.map((p) => p.id).toSet().length, deck.pages.length);
    expect(deck.pages.every((p) => p.title.isNotEmpty && p.body.isNotEmpty), isTrue);
    expect(deck.pendingFor(0).length, deck.pages.length);
    expect(deck.pendingFor(1).map((p) => p.id), ['yeni']);
    expect(deck.pendingFor(deck.latest), isEmpty);
  });

  testWidgets('intro screen pages through to done at small width', (tester) async {
    tester.view.physicalSize = const Size(320 * 3, 640 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final raw = jsonDecode(File('assets/intro/intro.json').readAsStringSync()) as Map<String, Object?>;
    final pages = [for (final p in raw['Pages'] as List) IntroPage.fromJson((p as Map).cast<String, Object?>())];
    var done = false;
    await tester.pumpWidget(Motion(
      enabled: false,
      child: MaterialApp(
        theme: buildVitaTheme(VitaPalette.light),
        home: IntroScreen(pages: pages, onDone: () => done = true),
      ),
    ));
    for (var i = 0; i < pages.length - 1; i++) {
      expect(find.text(pages[i].title), findsOneWidget);
      await tester.tap(find.text('Devam'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
    await tester.tap(find.text('Başla'));
    expect(done, isTrue);
  });
}
