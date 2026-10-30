import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:life_simulation/content/game_content.dart';
import 'package:life_simulation/content/models.dart';
import 'package:life_simulation/design/components.dart';
import 'package:life_simulation/design/palette.dart';
import 'package:life_simulation/design/theme.dart';
import 'package:life_simulation/ui/story_interactions.dart';

import 'content_test.dart' show contentPaths, readFile;

void main() {
  late GameContent content;
  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    content = await GameContent.load(contentPaths(), readFile);
  });

  StoryInteraction of(String book, String node) => content.stories[book]!.nodes[node]!.interaction!;

  Future<List<(String, Set<String>)>> pump(WidgetTester tester, Widget Function(OutcomeCallback) build,
      {VitaPalette palette = VitaPalette.dark}) async {
    tester.view.physicalSize = const Size(320 * 3, 720 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final outcomes = <(String, Set<String>)>[];
    await tester.pumpWidget(Motion(
      enabled: false,
      child: MaterialApp(
        theme: buildVitaTheme(palette),
        home: Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: build((o, {found = const {}, indices = const {}}) => outcomes.add((o, found))),
          ),
        ),
      ),
    ));
    await tester.pump();
    return outcomes;
  }

  Future<void> tapText(WidgetTester tester, String text) async {
    await tester.ensureVisible(find.text(text).first);
    await tester.tap(find.text(text).first);
    await tester.pump();
  }

  testWidgets('şifre kilidi: doğru kod açar, ipucu yanlıştan sonra görünür', (tester) async {
    final i = of('son_vapur', 'locker');
    final out = await pump(tester, (cb) => CodeLock(interaction: i, onOutcome: cb));
    await tapText(tester, 'Kilidi dene');
    expect(find.textContaining('İpucu'), findsOneWidget);
    // 2340: her hanede yukarı oku gerektiği kadar bas.
    final ups = find.byIcon(Icons.keyboard_arrow_up);
    for (final (d, n) in [2, 3, 4, 0].indexed) {
      for (var k = 0; k < n; k++) {
        await tester.tap(ups.at(d));
        await tester.pump();
      }
    }
    await tapText(tester, 'Kilidi dene');
    expect(out.single.$1, 'success');
  });

  testWidgets('şifre kilidi: haklar bitince fail', (tester) async {
    final out = await pump(tester, (cb) => CodeLock(interaction: of('son_vapur', 'locker'), onOutcome: cb));
    for (var k = 0; k < 3; k++) {
      await tapText(tester, 'Kilidi dene');
    }
    expect(out.single.$1, 'fail');
  });

  testWidgets('sıralama: düğmelerle doğru sıraya gelince success', (tester) async {
    final i = of('son_vapur', 'sounds');
    final out = await pump(tester, (cb) => OrderPuzzle(interaction: i, onOutcome: cb), palette: VitaPalette.light);
    List<String> current() => [
          for (final t in tester.widgetList<Text>(find.byType(Text)))
            if (RegExp(r'^\d\. ').hasMatch(t.data ?? '')) t.data!.substring(3),
        ];
    for (var target = 0; target < i.items.length; target++) {
      while (current().indexOf(i.items[target]) > target) {
        final at = current().indexOf(i.items[target]);
        await tester.tap(find.byTooltip('Yukarı taşı').at(at));
        await tester.pump();
      }
    }
    expect(current(), i.items);
    await tapText(tester, 'Bu sırayla dene');
    expect(out.single.$1, 'success');
  });

  testWidgets('frekans: hedefte tutunca success, vazgeçince fail', (tester) async {
    final i = of('son_vapur', 'dock');
    var out = await pump(tester, (cb) => TuneDial(interaction: i, onOutcome: cb));
    tester.widget<Slider>(find.byType(Slider)).onChanged!(i.target);
    await tester.pump(const Duration(milliseconds: 100));
    for (var t = 0; t < 20; t++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(out.single.$1, 'success');

    out = await pump(tester, (cb) => TuneDial(key: UniqueKey(), interaction: i, onOutcome: cb));
    await tapText(tester, 'Vazgeç');
    expect(out.single.$1, 'fail');
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('frekans: süre dolunca fail', (tester) async {
    final i = of('kirik_frekans', 'tune_echo');
    final out = await pump(tester, (cb) => TuneDial(interaction: i, onOutcome: cb));
    for (var t = 0; t < i.seconds * 10 + 2; t++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(out.single.$1, 'fail');
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('zamanlama: iki ıska ile fail', (tester) async {
    final out = await pump(tester, (cb) => TimingBar(interaction: of('son_vapur', 'chase'), onOutcome: cb));
    // İşaret 0'dan başlar; ilk bölge 0,7'de: hemen basmak ıskadır.
    await tapText(tester, 'Şimdi!');
    await tapText(tester, 'Şimdi!');
    expect(out.single.$1, 'fail');
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('inceleme: bakış hakkı kadar ipucu ve bayrak', (tester) async {
    final i = of('son_vapur', 'deck_search');
    final out = await pump(tester, (cb) => SearchScene(interaction: i, onOutcome: cb));
    await tapText(tester, i.spots[0].label);
    await tapText(tester, i.spots[1].label);
    expect(find.text(i.spots[0].text), findsOneWidget);
    await tapText(tester, i.spots[2].label);
    expect(find.text(i.spots[2].text), findsNothing, reason: 'iki bakış hakkı var');
    await tapText(tester, 'Devam et');
    expect(out.single.$1, 'done');
    expect(out.single.$2, {i.spots[0].flag, i.spots[1].flag});
  });

  testWidgets('süreli karar: süre dolunca timeout', (tester) async {
    final i = of('son_vapur', 'shipyard');
    var timedOut = 0;
    await pump(tester, (_) => TimedChoiceBar(interaction: i, onTimeout: () => timedOut++));
    await tester.pump(Duration(seconds: i.seconds - 1));
    expect(timedOut, 0);
    await tester.pump(const Duration(seconds: 2));
    expect(timedOut, 1);
  });

  testWidgets('ekran okuyucu açıkken süreli karar durur', (tester) async {
    final i = of('son_vapur', 'shipyard');
    var timedOut = 0;
    await pump(
      tester,
      (_) => Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(context).copyWith(accessibleNavigation: true),
          child: TimedChoiceBar(interaction: i, onTimeout: () => timedOut++),
        ),
      ),
    );
    await tester.pump(Duration(seconds: i.seconds + 5));
    expect(timedOut, 0);
    expect(find.textContaining('süre durduruldu'), findsOneWidget);
  });

  LifeMoment mom(String target) => content.moments[target]!;

  testWidgets('hafıza: bütün çiftler bulununca success', (tester) async {
    final i = mom('baby_colors').interaction;
    final out = await pump(tester, (cb) => MemoryPairs(interaction: i, onOutcome: cb));
    final cards = [...i.items, ...i.items]..shuffle(Random(i.items.join().length));
    final tiles = find.descendant(of: find.byType(Wrap), matching: find.byType(InkWell));
    expect(tiles, findsNWidgets(cards.length));
    for (final item in i.items) {
      final a = cards.indexOf(item), b = cards.lastIndexOf(item);
      await tester.tap(tiles.at(a));
      await tester.pump();
      await tester.tap(tiles.at(b));
      await tester.pump();
    }
    expect(out.single.$1, 'success');
  });

  testWidgets('hafıza: hata hakkı bitince fail', (tester) async {
    final i = mom('baby_colors').interaction;
    final out = await pump(tester, (cb) => MemoryPairs(interaction: i, onOutcome: cb));
    final cards = [...i.items, ...i.items]..shuffle(Random(i.items.join().length));
    // Her seferinde eşleşmeyen iki kart.
    final a = 0, b = cards.indexWhere((c) => c != cards[0]);
    for (var k = 0; k <= i.attempts; k++) {
      final tiles = find.descendant(of: find.byType(Wrap), matching: find.byType(InkWell));
      await tester.tap(tiles.at(a));
      await tester.pump();
      await tester.tap(tiles.at(b));
      await tester.pump(const Duration(milliseconds: 800));
    }
    expect(out.single.$1, 'fail');
  });

  testWidgets('bütçe: alt sınırlar sağlanınca success, eksikse fail', (tester) async {
    final i = mom('lived_family_budget_child').interaction;
    var out = await pump(tester, (cb) => BudgetSplit(interaction: i, onOutcome: cb));
    for (final b in i.buckets) {
      for (var k = 0; k < b.min; k++) {
        await tester.tap(find.byTooltip('${b.label} artır'));
        await tester.pump();
      }
    }
    final rest = i.total - i.buckets.fold<int>(0, (a, b) => a + b.min);
    for (var k = 0; k < rest; k++) {
      await tester.tap(find.byTooltip('${i.buckets[1].label} artır'));
      await tester.pump();
    }
    await tapText(tester, 'Planı onayla');
    expect(out.single.$1, 'success');

    out = await pump(tester, (cb) => BudgetSplit(key: UniqueKey(), interaction: i, onOutcome: cb));
    await tapText(tester, 'Planı onayla');
    expect(out.single.$1, 'fail');
  });

  testWidgets('nefes: basılı tutunca tur sayılır, erken bırakınca hak gider', (tester) async {
    final i = mom('lived_rest').interaction;
    final out = await pump(tester, (cb) => HoldBreath(interaction: i, onOutcome: cb));
    final target = find.text('Al');
    for (var r = 0; r < i.rounds; r++) {
      final g = await tester.startGesture(tester.getCenter(find.byType(CircularProgressIndicator).first));
      await tester.pump(); // ilk karede animasyonun saati başlar
      await tester.pump(Duration(milliseconds: i.holdMs + 50));
      await g.up();
      await tester.pump();
    }
    expect(out.single.$1, 'success');
    expect(target, findsWidgets);

    final out2 = await pump(tester, (cb) => HoldBreath(key: UniqueKey(), interaction: i, onOutcome: cb));
    for (var k = 0; k <= i.attempts; k++) {
      final g = await tester.startGesture(tester.getCenter(find.byType(CircularProgressIndicator).first));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      await g.up();
      await tester.pump();
    }
    expect(out2.single.$1, 'fail');
  });

  testWidgets('soru: doğru şık success, yanlış şık fail', (tester) async {
    final i = mom('baby_why').interaction;
    var out = await pump(tester, (cb) => QuizCard(interaction: i, onOutcome: cb));
    await tapText(tester, i.items[i.answerIndex]);
    expect(out.single.$1, 'success');
    out = await pump(tester, (cb) => QuizCard(key: UniqueKey(), interaction: i, onOutcome: cb));
    await tapText(tester, i.items[(i.answerIndex + 1) % i.items.length]);
    expect(out.single.$1, 'fail');
  });

  for (final palette in [VitaPalette.dark, VitaPalette.light]) {
    testWidgets('etkileşimler ve görünümler erişilebilir · ${palette.isDark ? 'koyu' : 'açık'}', (tester) async {
      final handle = tester.ensureSemantics();
      final b = content.stories['son_vapur']!;
      for (final w in <Widget Function(OutcomeCallback)>[
        (cb) => CodeLock(interaction: of('son_vapur', 'locker'), onOutcome: cb),
        (cb) => OrderPuzzle(interaction: of('son_vapur', 'sounds'), onOutcome: cb),
        (cb) => SearchScene(interaction: of('son_vapur', 'deck_search'), onOutcome: cb),
        (cb) => MemoryPairs(interaction: mom('lived_memory_box').interaction, onOutcome: cb),
        (cb) => BudgetSplit(interaction: mom('lived_first_rent').interaction, onOutcome: cb),
        (cb) => HoldBreath(interaction: mom('lived_rest').interaction, onOutcome: cb),
        (cb) => QuizCard(interaction: mom('lived_hospital_wait').interaction, onOutcome: cb),
        (_) => Column(children: [
              ChatThread(text: b.nodes['ipek_msg']!.text),
              PaperNote(text: b.nodes['mother_letter']!.text),
              RadioTranscript(text: b.nodes['recording']!.text),
            ]),
      ]) {
        await pump(tester, w, palette: palette);
        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
        await expectLater(tester, meetsGuideline(textContrastGuideline));
        expect(tester.takeException(), isNull);
      }
      handle.dispose();
    });
  }
}
