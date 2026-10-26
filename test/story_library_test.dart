import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:life_simulation/content/game_content.dart';
import 'package:life_simulation/game/atomic_file.dart';
import 'package:life_simulation/game/story_library.dart';
import 'package:life_simulation/game/story_store.dart';
import 'package:life_simulation/game/save.dart';
import 'package:life_simulation/game/session.dart';

import 'content_test.dart' show contentPaths, readFile;

class FailingFile extends AtomicTextFile {
  FailingFile(super.path);
  bool fail = false;
  @override
  bool write(String text) => fail ? false : super.write(text);
}

void main() {
  late GameContent content;
  late Directory dir;
  late StoryLibrary library;
  setUpAll(() async {
    content = await GameContent.load(contentPaths(), readFile);
  });
  setUp(() {
    dir = Directory.systemTemp.createTempSync('vita_p4_');
    library = StoryLibrary(
      content.stories,
      AtomicTextFile('${dir.path}/story-progress.json'),
    );
  });
  tearDown(() => dir.deleteSync(recursive: true));
  StoryProgress clone(StoryProgress p) => StoryProgress.fromJson(
    jsonDecode(jsonEncode(p.toJson())) as Map<String, dynamic>,
  );
  test('three books and four endings each; choices save independently', () {
    expect(library.books.length, 3);
    for (final b in library.books.values) {
      expect(b.nodes.values.where((n) => n.ending.isNotEmpty).length, 4);
      final p = library.open(b.id), node = library.open(b.id).nodeId;
      expect(library.choose(b.id, -1, expectedNode: node).success, isFalse);
      expect(p.decisions, 0);
      expect(library.choose(b.id, 0, expectedNode: node).success, isTrue);
      expect(p.decisions, 1);
      expect(library.choose(b.id, 0, expectedNode: node).success, isFalse);
      expect(p.decisions, 1);
    }
    final loaded = StoryLibrary(content.stories, library.file)..load();
    expect(loaded.toJson(), library.toJson());
  });
  test('paid chapter lock is enforced in service and preserves decision', () {
    for (final b in library.books.values.where((b) => b.productId.isNotEmpty)) {
      var guard = 100;
      final p = library.open(b.id);
      while (library.canRead(b, b.nodes[p.nodeId]!) && guard-- > 0) {
        final node = b.nodes[p.nodeId]!;
        final index = node.choices.indexWhere(
          (c) => library.blocked(b, p, c) == null,
        );
        expect(
          library.choose(b.id, index, expectedNode: p.nodeId).success,
          isTrue,
        );
      }
      expect(guard, greaterThan(0));
      expect(b.nodes[p.nodeId]!.chapter, greaterThan(b.freeChapters));
      final before = jsonEncode(p.toJson());
      expect(library.choose(b.id, 0, expectedNode: p.nodeId).success, isFalse);
      expect(jsonEncode(p.toJson()), before);
      final owned = StoryLibrary(
        content.stories,
        library.file,
        ownsProduct: (id) => id == b.productId,
      )..load();
      expect(owned.canRead(b, b.nodes[owned.open(b.id).nodeId]!), isTrue);
    }
  });
  test('all twelve endings reachable through actual stats and flag rules', () {
    library = StoryLibrary(
      content.stories,
      library.file,
      ownsProduct: (_) => true,
    );
    for (final b in library.books.values) {
      final queue = <StoryProgress>[clone(library.open(b.id))],
          seen = <String>{},
          reached = <String>{};
      var count = 0;
      while (queue.isNotEmpty && count++ < 5000) {
        final p = queue.removeLast();
        final stats = p.stats.entries.toList()
          ..sort((a, b) => a.key.compareTo(b.key));
        final flags = p.flags.toList()..sort();
        final key =
            '${p.nodeId}:${stats.map((e) => '${e.key}=${e.value}').join(',')}:${flags.join(',')}';
        if (!seen.add(key)) continue;
        final node = b.nodes[p.nodeId]!;
        if (node.ending.isNotEmpty) {
          reached.add(p.nodeId);
          continue;
        }
        for (var i = 0; i < node.choices.length; i++) {
          if (library.blocked(b, p, node.choices[i]) != null) continue;
          library.progress[b.id] = clone(p);
          expect(
            library.choose(b.id, i, expectedNode: p.nodeId).success,
            isTrue,
          );
          queue.add(clone(library.open(b.id)));
        }
      }
      expect(count, lessThan(5000));
      expect(
        reached,
        b.nodes.entries
            .where((e) => e.value.ending.isNotEmpty)
            .map((e) => e.key)
            .toSet(),
      );
    }
  });
  test('restart retains discovered endings and other books, life save stays intact', () {
    final life = GameSession(content, SaveService('${dir.path}/savegame.json'))
      ..startNewGame('Deniz', seed: 42);
    final lifeBytes = File(life.saves.savePath).readAsBytesSync();
    for (final b in library.books.values) {
      library
          .open(b.id)
          .endings
          .add(
            b.nodes.entries.firstWhere((e) => e.value.ending.isNotEmpty).key,
          );
    }
    final b = library.books.values.first;
    final before = library.open(b.id).endings.toSet();
    expect(library.restart(b.id).success, isTrue);
    expect(library.open(b.id).endings, before);
    expect(library.open(b.id).nodeId, b.start);
    expect(library.progress.length, 3);
    expect(File(life.saves.savePath).readAsBytesSync(), lifeBytes);
    life.startNewGame('Yeni', seed: 5);
    final restored = StoryLibrary(content.stories, library.file)..load();
    expect(restored.open(b.id).endings, before);
  });
  test('corrupt main recovers backup; entirely corrupt library reports Turkish notice', () {
    final b = library.books.values.first;
    library.open(b.id);
    library.save();
    File(library.file.path).writeAsStringSync('bozuk');
    final loaded = StoryLibrary(content.stories, library.file)..load();
    expect(loaded.loadNotice, 'Hikâye kaydın yedekten kurtarıldı.');
    expect(loaded.progress.length, 1);
    for (final path in library.file.readOrder) {
      File(path).writeAsStringSync('bozuk');
    }
    loaded.load();
    expect(loaded.progress, isEmpty);
    expect(
      loaded.loadNotice,
      contains('Hayat kaydın ve satın almaların korunuyor'),
    );
  });
  test(
    'old node ids repair, stats clamp, unknown books and visits are removed',
    () {
      final b = library.books.values.first;
      final p = library.open(b.id)
        ..nodeId = 'removed'
        ..decisions = -5
        ..lastResult = 'old';
      p.visited.add('removed');
      p.endings.add('ending_kept');
      for (final k in b.statNames.keys) {
        p.stats[k] = 500;
      }
      library.save();
      library.load();
      final repaired = library.open(b.id);
      expect(repaired.nodeId, b.start);
      expect(repaired.stats.values, everyElement(100));
      expect(repaired.visited, isEmpty);
      expect(repaired.decisions, 0);
      expect(repaired.endings, contains('ending_kept'));
      expect(repaired.lastResult, contains('güncellendi'));
    },
  );
  test('failed choice and restart writes roll back progress', () {
    final file = FailingFile('${dir.path}/failed.json');
    library = StoryLibrary(content.stories, file);
    final b = library.books.values.first;
    final p = library.open(b.id),
        before = jsonEncode(library.open(b.id).toJson());
    file.fail = true;
    expect(library.choose(b.id, 0, expectedNode: p.nodeId).success, isFalse);
    expect(jsonEncode(library.open(b.id).toJson()), before);
    expect(library.restart(b.id).success, isFalse);
    expect(jsonEncode(library.open(b.id).toJson()), before);
  });
  test(
    'offline store never grants ownership; cache accepts only known ids',
    () {
      final file = AtomicTextFile('${dir.path}/story-entitlements.json');
      final store = StoryStore(
        content.stories.values.map((b) => b.productId),
        file,
      )..load();
      final product = content.stories.values
          .firstWhere((b) => b.productId.isNotEmpty)
          .productId;
      expect(store.canPurchase(product), isFalse);
      expect(store.owns(product), isFalse);
      expect(store.purchase(product).success, isFalse);
      expect(store.restore().success, isFalse);
      expect(store.owns(product), isFalse);
      file.write(
        jsonEncode({
          'Version': 1,
          'Products': [product, 'unknown'],
        }),
      );
      store.load();
      expect(store.owns(product), isTrue);
      expect(store.owns('unknown'), isFalse);
    },
  );
}
