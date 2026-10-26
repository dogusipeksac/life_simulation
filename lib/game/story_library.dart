// Godot StoryLibrary / StoryProgress. Ana hayat kaydıyla bağımsız, çevrimdışı.
import 'dart:convert';

import '../content/models.dart';
import 'atomic_file.dart';
import 'session.dart' show ActionResult;

class StoryProgress {
  StoryProgress({
    this.nodeId = '',
    Map<String, int>? stats,
    Set<String>? endings,
  }) : stats = stats ?? {},
       endings = endings ?? {};
  String nodeId;
  Map<String, int> stats;
  Set<String> flags = {}, endings;
  List<String> visited = [];
  String lastResult = '';
  int decisions = 0;
  StoryProgress.fromJson(Map<String, dynamic> j)
    : nodeId = j['NodeId'] as String? ?? '',
      stats = {
        ...?(j['Stats'] as Map?)?.map(
          (k, v) => MapEntry(k as String, (v as num).toInt()),
        ),
      },
      endings = {...?(j['Endings'] as List?)?.whereType<String>()} {
    flags = {...?(j['Flags'] as List?)?.whereType<String>()};
    visited = [...?(j['Visited'] as List?)?.whereType<String>()];
    lastResult = j['LastResult'] as String? ?? '';
    decisions = (j['Decisions'] as num?)?.toInt() ?? 0;
  }
  Map<String, dynamic> toJson() => {
    'NodeId': nodeId,
    'Stats': stats,
    'Flags': flags.toList(),
    'Visited': visited,
    'Endings': endings.toList(),
    'LastResult': lastResult,
    'Decisions': decisions,
  };
}

class StoryLibrary {
  StoryLibrary(
    Map<String, StoryBook> books,
    this.file, {
    bool Function(String)? ownsProduct,
  }) : books = Map.unmodifiable(books),
       ownsProduct = ownsProduct ?? ((_) => false);
  final Map<String, StoryBook> books;
  final AtomicTextFile file;
  final bool Function(String) ownsProduct;
  final Map<String, StoryProgress> progress = {};
  String loadNotice = '';
  Map<String, dynamic> toJson() => {
    'Version': 1,
    'Books': progress.map((id, p) => MapEntry(id, p.toJson())),
  };
  bool save() => file.write(jsonEncode(toJson()));
  void load() {
    loadNotice = '';
    progress.clear();
    var found = false;
    for (final path in file.readOrder) {
      final json = file.read(path);
      if (json == null) continue;
      found = true;
      try {
        final root = jsonDecode(json);
        if (root is! Map || root['Version'] != 1 || root['Books'] is! Map) {
          continue;
        }
        final loaded = <String, StoryProgress>{};
        for (final entry in (root['Books'] as Map).entries) {
          final book = books[entry.key];
          if (book == null || entry.value is! Map) continue;
          final p = StoryProgress.fromJson(
            (entry.value as Map).cast<String, dynamic>(),
          );
          if (!book.nodes.containsKey(p.nodeId)) {
            p.nodeId = book.start;
            p.lastResult = 'Hikâye güncellendi; başlangıç sahnesine döndün. Bulduğun sonlar korundu.';
          }
          for (final key in book.statNames.keys) {
            p.stats[key] = (p.stats[key] ?? 50).clamp(0, 100);
          }
          p.visited.removeWhere((id) => !book.nodes.containsKey(id));
          if (p.decisions < 0) p.decisions = 0;
          loaded[book.id] = p;
        }
        progress.addAll(loaded);
        if (path != file.path) {
          loadNotice = 'Hikâye kaydın yedekten kurtarıldı.';
        }
        return;
      } on FormatException {
        continue;
      } on TypeError {
        continue;
      }
    }
    if (found) loadNotice = 'Hikâye ilerlemesi okunamadı. Hayat kaydın ve satın almaların korunuyor.';
  }

  StoryProgress open(String bookId) {
    final book = books[bookId]!;
    final existing = progress[bookId];
    if (existing != null) return existing;
    final p = StoryProgress(
      nodeId: book.start,
      stats: {for (final key in book.statNames.keys) key: 50},
    );
    progress[bookId] = p;
    if (!save()) loadNotice = 'Hikâye ilerlemesi kaydedilemedi. Depolama alanını kontrol edip yeniden dene.';
    return p;
  }

  bool canRead(StoryBook b, StoryNode n) =>
      b.productId.isEmpty ||
      n.chapter <= b.freeChapters ||
      ownsProduct(b.productId);
  String? blocked(StoryBook b, StoryProgress p, StoryOption c) {
    if (c.needFlag.isNotEmpty && !p.flags.contains(c.needFlag)) {
      return 'Önceki seçimlerinde bu yolu açmadın.';
    }
    if (c.needStat.isNotEmpty && (p.stats[c.needStat] ?? 0) < c.minValue) {
      return '${b.statNames[c.needStat]} ${c.minValue}+ gerekli.';
    }
    return null;
  }

  ActionResult choose(
    String bookId,
    int index, {
    required String expectedNode,
  }) {
    final b = books[bookId];
    if (b == null) return const ActionResult(false, 'Hikâye bulunamadı.');
    final p = open(bookId), node = b.nodes[open(bookId).nodeId]!;
    if (p.nodeId != expectedNode) {
      return const ActionResult(false, 'Bu karar zaten uygulandı.');
    }
    if (!canRead(b, node)) {
      return const ActionResult(
        false,
        'Bu bölümü okumak için tam hikâyenin kilidini açmalısın.',
      );
    }
    if (index < 0 || index >= node.choices.length) {
      return const ActionResult(false, 'Seçenek bulunamadı.');
    }
    final c = node.choices[index], reason = blocked(b, p, node.choices[index]);
    if (reason != null) return ActionResult(false, reason);
    final previous = jsonEncode(p.toJson());
    p.visited.add(p.nodeId);
    if (p.visited.length > 1000) p.visited.removeAt(0);
    p.decisions++;
    for (final e in c.effects.entries) {
      p.stats[e.key] = ((p.stats[e.key] ?? 50) + e.value).clamp(0, 100);
    }
    p.flags.addAll(c.setFlags);
    p.nodeId = c.next;
    p.lastResult = c.result;
    final next = b.nodes[c.next]!;
    if (next.ending.isNotEmpty && canRead(b, next)) p.endings.add(c.next);
    if (!save()) {
      progress[bookId] = StoryProgress.fromJson(
        jsonDecode(previous) as Map<String, dynamic>,
      );
      return const ActionResult(
        false,
        'Kararın kaydedilemedi. Depolama alanını kontrol edip yeniden dene.',
      );
    }
    return ActionResult(true, c.result);
  }

  ActionResult restart(String bookId) {
    final book = books[bookId];
    if (book == null) return const ActionResult(false, 'Hikâye bulunamadı.');
    final previous = open(bookId);
    progress[bookId] = StoryProgress(
      nodeId: book.start,
      stats: {for (final key in book.statNames.keys) key: 50},
      endings: {...previous.endings},
    );
    if (!save()) {
      progress[bookId] = previous;
      return const ActionResult(
        false,
        'Hikâye yeniden başlatılamadı; depolama alanını kontrol et.',
      );
    }
    return const ActionResult(
      true,
      'Hikâye yeniden başladı. Keşfettiğin sonlar korundu.',
    );
  }
}
