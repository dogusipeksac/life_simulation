import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:life_simulation/content/game_content.dart';
import 'package:life_simulation/content/models.dart';
import 'package:life_simulation/game/catalog.dart';
import 'package:life_simulation/game/effects.dart';
import 'package:life_simulation/game/event_manager.dart';
import 'package:life_simulation/game/events.dart';
import 'package:life_simulation/game/family.dart';
import 'package:life_simulation/game/rng.dart';
import 'package:life_simulation/game/save.dart';
import 'package:life_simulation/game/session.dart';
import 'package:life_simulation/game/state.dart';
import 'package:life_simulation/game/text.dart';
import 'package:life_simulation/game/voice.dart';

import 'content_test.dart' show contentPaths, readFile;

void main() {
  late GameContent content;
  late Directory tmp;

  setUpAll(() async => content = await GameContent.load(contentPaths(), readFile));
  setUp(() => tmp = Directory.systemTemp.createTempSync('vita_'));
  tearDown(() => tmp.deleteSync(recursive: true));

  GameSession newSession() => GameSession(content, SaveService('${tmp.path}/savegame.json'));

  group('efekt işleyici', () {
    test('statlar 0–100 arasında kalır', () {
      final s = GameState.createNew('Test', 0, 1);
      final fx = EffectProcessor();
      expect(fx.applyStat(s, Stat.health, 500).applied, 20);
      expect(s.health, 100);
      expect(fx.applyStat(s, Stat.happiness, -500).newValue, 0);
    });

    test('para tabanı ve taşma', () {
      final s = GameState.createNew('Test', 0, 1);
      final fx = EffectProcessor(moneyFloor: -150000);
      fx.applyStat(s, Stat.money, -1000000);
      expect(s.money, -150000);
      s.money = 0x7FFFFFFFFFFFFFF0;
      fx.applyStat(s, Stat.money, 1000);
      expect(s.money, 0x7FFFFFFFFFFFFFFF);
    });

    test('ayrıntılı tempoda artıklar birikir', () {
      final s = GameState.createNew('Test', 0, 1)..profile.detailedLife = true;
      final ev = EventDef(id: 'e', title: '', description: '', category: EventCategory.random, choices: []);
      final c = ChoiceDef(id: 'c', text: '', result: '', effects: [const StatEffect(Stat.education, 2)]);
      final fx = EffectProcessor();
      final before = s.education;
      fx.applyChoice(s, ev, c); // 2/3 → 0, artık 2
      expect(s.education, before);
      fx.applyChoice(s, ev, c); // (2+2)/3 → 1, artık 1
      expect(s.education, before + 1);
      expect(s.effectRemainders[Stat.education], 1);
    });
  });

  group('olay seçimi', () {
    test('katalog 6000 olay üretir, ID\'ler benzersiz', () {
      final ids = buildLifeCatalog().map((e) => e.id).toSet();
      expect(ids.length, lifeCatalogEventCount);
    });

    test('cooldown ve tekrar kuralları', () {
      final session = newSession()..startNewGame('Deniz', seed: 42);
      final s = session.state!..age = 30;
      final ev = EventDef(
        id: 'rep', title: '', description: '', category: EventCategory.random, repeatable: true, cooldownDays: 100,
        choices: [ChoiceDef(id: 'a', text: '', result: '')],
      );
      expect(session.events.isEligible(s, ev), isTrue);
      s.eventLastSeenDay['rep'] = s.day;
      expect(session.events.isEligible(s, ev), isFalse);
      s.day += 100;
      expect(session.events.isEligible(s, ev), isTrue);
      final once = EventDef(
        id: 'once', title: '', description: '', category: EventCategory.random,
        choices: [ChoiceDef(id: 'a', text: '', result: '')],
      );
      s.completedEventIds.add('once');
      expect(session.events.isEligible(s, once), isFalse);
    });

    test('aynı seed aynı hayatı üretir', () {
      List<String> play() {
        final session = newSession()..autoSaveEnabled = false;
        session.startNewGame('Deniz', seed: 777);
        final seen = <String>[];
        for (var i = 0; i < 40 && !session.state!.isGameOver; i++) {
          final ev = session.requestNextEvent();
          if (ev == null) continue;
          seen.add(ev.id);
          final pick = session.choiceViews(ev).firstWhere((c) => c.isAvailable);
          session.submitChoice(pick.id);
        }
        return seen;
      }

      final a = play();
      expect(a.first, 'baby_welcome');
      expect(a.length, greaterThan(20));
      expect(play(), a);
    });

    test('bütün hayat çökmeden sona erer', () {
      final session = newSession()..autoSaveEnabled = false;
      session.startNewGame('Deniz', seed: 2026);
      for (var i = 0; i < 5000 && !session.state!.isGameOver; i++) {
        final ev = session.requestNextEvent();
        if (ev == null) continue;
        final views = session.choiceViews(ev);
        final available = views.where((c) => c.isAvailable).toList();
        expect(available, isNotEmpty, reason: ev.id);
        session.submitChoice(available[i % available.length].id);
      }
      final s = session.state!;
      expect(s.isGameOver, isTrue);
      expect(s.endingId, isNotNull);
      expect(s.health, inInclusiveRange(0, 100));
    });
  });

  group('tekrar sınırı', () {
    test('tekrarlanabilir olay bir hayatta en fazla 3 kez sunulur', () {
      final session = newSession()..startNewGame('Deniz', seed: 42);
      final s = session.state!..age = 30;
      final ev = EventDef(
        id: 'rep', title: '', description: '', category: EventCategory.random, repeatable: true,
        choices: [ChoiceDef(id: 'a', text: '', result: '')],
      );
      final fx = EffectProcessor();
      for (var i = 0; i < EventManager.repeatCapPerLife; i++) {
        expect(session.events.isEligible(s, ev), isTrue);
        fx.applyChoice(s, ev, ev.choices.first);
        s.day += 1000;
      }
      expect(s.eventShowCounts['rep'], EventManager.repeatCapPerLife);
      expect(session.events.isEligible(s, ev), isFalse);
    });

    test('tam bir hayatta takip/seçim dışında hiçbir olay 3 kereden fazla gelmez', () {
      final session = newSession()..autoSaveEnabled = false;
      session.startNewGame('Deniz', seed: 2026, profile: CharacterProfile()..detailedLife = true);
      final counts = <String, int>{};
      var calmInRow = 0, maxCalmInRow = 0;
      for (var i = 0; i < 5000 && !session.state!.isGameOver; i++) {
        final ev = session.requestNextEvent();
        if (ev == null) {
          calmInRow++;
          maxCalmInRow = calmInRow > maxCalmInRow ? calmInRow : maxCalmInRow;
          continue;
        }
        calmInRow = 0;
        counts[ev.id] = (counts[ev.id] ?? 0) + 1;
        session.submitChoice(session.choiceViews(ev).firstWhere((c) => c.isAvailable).id);
      }
      final over = counts.entries.where((e) => e.value > 3 && !e.key.startsWith('sim_') && !e.key.startsWith('wedding'));
      final followUps = session.content.scenes.values.where((sc) => sc.followUpOnly).map((sc) => sc.id).toSet();
      expect(over.where((e) => !followUps.contains(e.key)), isEmpty);
      // Boş dönemler en fazla bir yıllık tek sayfada birleşir; arka arkaya ikinci sayfa
      // ancak bütün bir yıl hiçbir olay uygun olmadıysa çıkar.
      expect(maxCalmInRow, lessThanOrEqualTo(2));
    });
  });

  group('anlar', () {
    test('an önce oynanır; etkisi ve cümlesi karar sonucuna eklenir', () {
      final session = newSession()..startNewGame('Deniz', seed: 3);
      final s = session.state!..age = 30;
      final ev = EventDef.fromContent(session.content.events['career_difficult_manager']!);
      session.currentEvent = ev;
      s.currentEventId = ev.id;
      final m = session.activeMoment()!;
      expect(m.interaction.type, 'hold');
      final before = s.health;
      expect(session.resolveMoment('success').success, isTrue);
      expect(s.health, before + 1);
      expect(session.activeMoment(), isNull, reason: 'aynı an iki kez oynanmaz');
      expect(session.resolveMoment('success').success, isFalse);
      final r = session.submitChoice(ev.choices.first.id)!;
      expect(r.resultText, startsWith(fillScene(s, m.successText)));
      expect(r.changes.first.stat, Stat.health);
      expect(s.momentKey, isEmpty);
    });

    test('inceleme anı anahtar noktayla başarılı, bakış hakkı aşılmaz', () {
      final session = newSession()..startNewGame('Deniz', seed: 4);
      final s = session.state!..age = 8;
      final ev = EventDef.fromContent(session.content.events['childhood_found_wallet']!);
      session.currentEvent = ev;
      s.currentEventId = ev.id;
      expect(session.resolveMoment('done', found: {0, 1, 2}).success, isFalse);
      expect(session.resolveMoment('done', found: {2, 3}).success, isTrue);
      expect(s.momentNote, contains('ipucu bulamadın'));
    });

    test('süreli anda süre dolunca belirtilen seçenek uygulanır', () {
      final session = newSession()..startNewGame('Deniz', seed: 5);
      final s = session.state!..age = 30;
      final ev = EventDef.fromContent(session.content.events['career_overtime']!);
      session.currentEvent = ev;
      s.currentEventId = ev.id;
      expect(session.activeMoment()!.timed, isTrue);
      expect(session.resolveMoment('success').success, isFalse);
      session.momentTimeout();
      expect(s.journal.last.choice, fillVoice(s, ev.findChoice('accept')!.text));
    });

    test('oynanmış an kayıttan sonra korunur', () {
      final session = newSession()..startNewGame('Deniz', seed: 6);
      final s = session.state!..age = 30;
      final ev = EventDef.fromContent(session.content.events['career_difficult_manager']!);
      session.currentEvent = ev;
      s.currentEventId = ev.id;
      session.resolveMoment('fail');
      final loaded = SaveService.deserialize(SaveService.serialize(s));
      expect(loaded.momentKey, s.momentKey);
      expect(loaded.momentNote, s.momentNote);
    });

    test('anlarla bütün bir hayat çökmeden oynanır', () {
      final session = newSession()..autoSaveEnabled = false;
      session.startNewGame('Deniz', seed: 77, profile: CharacterProfile()..detailedLife = true);
      var played = 0;
      for (var i = 0; i < 6000 && !session.state!.isGameOver; i++) {
        final ev = session.requestNextEvent();
        if (ev == null) continue;
        final m = session.activeMoment();
        if (m != null) {
          played++;
          if (m.timed) {
            session.momentTimeout();
            continue;
          }
          expect(session.resolveMoment(i.isEven ? 'success' : 'fail', found: {0}).success, isTrue);
        }
        final ok = session.choiceViews(ev).where((c) => c.isAvailable).toList();
        session.submitChoice(ok[i % ok.length].id);
      }
      expect(session.state!.isGameOver, isTrue);
      expect(played, greaterThan(25));
    });
  });

  group('yaşlanma', () {
    test('35 yaşından sonra yıllık kayıp ve 13 yılda bir ek kayıp', () {
      final s = GameState.createNew('Test', 0, 1);
      final life = content.life;
      s.happiness = 80;
      s.age = 34;
      expect(GameSession.yearlyHealthLoss(s, life), 0);
      s.age = 35;
      expect(GameSession.yearlyHealthLoss(s, life), 1);
      s.age = 48;
      expect(GameSession.yearlyHealthLoss(s, life), 2);
      s.flags.add('smoker');
      expect(GameSession.yearlyHealthLoss(s, life), 4);
      s.happiness = 10;
      expect(GameSession.yearlyHealthLoss(s, life), 5);
    });

    test('yeni yaş doğum gününe atlar', () {
      final session = newSession()..startNewGame('Deniz', seed: 5);
      final s = session.state!..pendingEventId = null;
      final r = session.advanceToBirthday();
      expect(r.success, isTrue);
      expect(s.age, 1);
      expect(s.dayOfYear, 0);
      expect(s.pendingMoment, isNotNull);
    });
  });

  group('kader zarı ve rastgelelik', () {
    test('aynı seed aynı aileyi verir, her durum seçilebilir', () {
      expect(rollFamily(content.families, 99)!.id, rollFamily(content.families, 99)!.id);
      final tiers = {for (var seed = 0; seed < 400; seed++) rollFamily(content.families, seed)!.tier};
      expect(tiers, Wealth.values.toSet());
    });

    test('RNG kayıttan aynı diziyle devam eder', () {
      final a = GameState()..rngSeed = 12345;
      final r1 = GameRandom(a);
      r1.rangeInt(0, 100);
      final b = GameState()
        ..rngSeed = a.rngSeed
        ..rngState = a.rngState;
      expect(GameRandom(b).rangeInt(0, 1000000), r1.rangeInt(0, 1000000));
      for (var i = 0; i < 1000; i++) {
        expect(r1.rangeInt(3, 7), inInclusiveRange(3, 7));
        expect(r1.nextDouble(), inInclusiveRange(0, 1));
      }
    });
  });

  group('kayıt', () {
    test('yaz-oku turu aynı durumu verir', () {
      final session = newSession()..startNewGame('Deniz Yılmaz', seed: 31);
      session.requestNextEvent();
      session.submitChoice(session.choiceViews(session.currentEvent!).first.id);
      final before = SaveService.serialize(session.state!);
      final loaded = session.saves.load();
      expect(loaded.status, LoadStatus.loaded);
      expect(SaveService.serialize(loaded.state!), before);
    });

    test('asıl dosya bozuksa yedekten okunur', () {
      final session = newSession()..startNewGame('Deniz', seed: 1);
      session.save(); // ikinci yazım: önceki .bak olur
      File(session.saves.savePath).writeAsStringSync('{bozuk');
      final r = session.saves.load();
      expect(r.status, LoadStatus.loaded);
      expect(r.loadedFrom, session.saves.backupPath);
    });

    test('hepsi bozuksa Türkçe açıklama için Corrupted', () {
      final saves = SaveService('${tmp.path}/savegame.json');
      File(saves.savePath).writeAsStringSync('çöp');
      expect(saves.load().status, LoadStatus.corrupted);
      File(saves.savePath).writeAsStringSync('{"SaveVersion": 99}');
      expect(saves.load().status, LoadStatus.unsupportedVersion);
      expect(corruptedSaveMessage, contains('yeni bir hayata'));
    });

    test('v6 kaydında görülen olaylar bir kez sayılır', () {
      final s = SaveService.deserialize('{"SaveVersion":6,"PlayerName":"Eski","EventLastSeenDay":{"health_flu":400}}');
      expect(s.eventShowCounts, {'health_flu': 1});
    });

    test('v1 kaydı güncel sürüme taşınır', () {
      final s = SaveService.deserialize(
          '{"SaveVersion":1,"PlayerName":"Eski","Age":30,"Health":70,"CareerId":"barista","CompletedEventIds":["a","b"]}');
      expect(s.saveVersion, GameState.currentSaveVersion);
      expect(s.careerLevel, 1);
      expect(s.totalChoices, 2);
      expect(s.simulation.qualities['family'], 50);
    });
  });

  test('para biçimi', () {
    expect(formatMoney(1234567), '₺1.234.567');
    expect(formatMoney(-500), '-₺500');
    expect(lowerInvariant('İş fikri'), 'iş fikri');
  });
}
