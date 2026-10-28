// Godot AchievementService: hayat kaydından bağımsız kalıcı başarımlar.
import 'dart:convert';

import '../content/models.dart';
import 'atomic_file.dart';
import 'conditions.dart';
import 'state.dart';

class AchievementView {
  const AchievementView(this.id, this.title, this.description, this.unlocked);
  final String id, title, description;
  final bool unlocked;
}

class AchievementService {
  AchievementService(
    Iterable<Achievement> definitions,
    this.file, {
    int Function()? now,
  }) : definitions = definitions.toList()..sort((a, b) => a.id.compareTo(b.id)),
       _now = now ?? (() => DateTime.now().millisecondsSinceEpoch ~/ 1000);
  final List<Achievement> definitions;
  final AtomicTextFile file;
  final int Function() _now;
  Map<String, int> _unlocked = {};
  String notice = '';
  int get unlockedCount => _unlocked.length;
  bool isUnlocked(String id) => _unlocked.containsKey(id);
  void load() {
    _unlocked = {};
    notice = '';
    var found = false;
    for (final path in file.readOrder) {
      final text = file.read(path);
      if (text == null) continue;
      found = true;
      try {
        final root = jsonDecode(text);
        if (root is! Map || root['Version'] != 1 || root['Unlocked'] is! Map) {
          continue;
        }
        _unlocked = (root['Unlocked'] as Map).map(
          (k, v) => MapEntry(k as String, (v as num).toInt()),
        );
        if (path != file.path) notice = 'Başarımların yedekten kurtarıldı.';
        return;
      } on FormatException {
        continue;
      } on TypeError {
        continue;
      }
    }
    if (found) notice = 'Başarım kaydı okunamadı. Hayat kaydın korunuyor.';
  }

  List<Achievement> check(GameState s, {required bool atGameOver}) {
    final newly = definitions
        .where(
          (a) =>
              !isUnlocked(a.id) &&
              (!a.onlyAtGameOver || atGameOver) &&
              allMet(s, a.conditions),
        )
        .toList();
    if (newly.isEmpty) return [];
    final next = {..._unlocked, for (final a in newly) a.id: _now()};
    if (!file.write(jsonEncode({'Version': 1, 'Unlocked': next}))) {
      notice = 'Başarımların kaydedilemedi. Depolama alanını kontrol et.';
      return [];
    }
    _unlocked = next;
    notice = '';
    return newly;
  }

  List<AchievementView> get views => [
    for (final a in definitions)
      AchievementView(
        a.id,
        isUnlocked(a.id) || !a.secret ? a.title : 'Gizli başarım',
        isUnlocked(a.id) || !a.secret
            ? a.description
            : 'Bir hayat boyunca keşfedilmeyi bekliyor.',
        isUnlocked(a.id),
      ),
  ];
  String title(String id) =>
      definitions.where((a) => a.id == id).firstOrNull?.title ?? id;
}
