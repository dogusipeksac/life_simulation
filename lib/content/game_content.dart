// Bütün içeriğin tek, salt okunur paketi. Saf Dart: dosyaları okuyan fonksiyon dışarıdan verilir
// (uygulamada rootBundle, testlerde dart:io).

import 'dart:convert';

import 'content_validator.dart';
import 'models.dart';

typedef ReadText = Future<String> Function(String path);

/// Doğrulama hatası: açılışta oyuncuya değil geliştiriciye gösterilir.
class ContentException implements Exception {
  ContentException(this.issues);
  final ContentIssues issues;

  @override
  String toString() => 'İçerik doğrulanamadı (${issues.errors.length} hata):\n${issues.errors.join('\n')}';
}

class GameContent {
  GameContent._(RawContent raw, this.issues)
      : flags = {for (final f in raw.flags) f['key'] as String: FlagInfo.fromJson(f)},
        careers = {for (final c in raw.careers) c['id'] as String: Career.fromJson(c)},
        families = List.unmodifiable(raw.families.map(Family.fromJson)),
        events = Map.unmodifiable({
          for (final file in raw.events.keys.toList()..sort())
            for (final e in raw.events[file]!) e['id'] as String: GameEvent.fromJson(e, file: file),
        }),
        goals = List.unmodifiable(raw.goals.map(Goal.fromJson)),
        achievements = List.unmodifiable(raw.achievements.map(Achievement.fromJson)),
        endings = List.unmodifiable(raw.endings.map(Ending.fromJson)),
        life = LifeConfig.fromJson(raw.life),
        scenes = Map.unmodifiable({for (final s in raw.scenes) s['Id'] as String: LifeScene.fromJson(s)}),
        stories = Map.unmodifiable({
          for (final file in raw.stories.keys.toList()..sort())
            raw.stories[file]!['Id'] as String: StoryBook.fromJson(raw.stories[file]!),
        });

  final Map<String, FlagInfo> flags;
  final Map<String, Career> careers;
  final List<Family> families;
  final Map<String, GameEvent> events;
  final List<Goal> goals;
  final List<Achievement> achievements;
  final List<Ending> endings;
  final LifeConfig life;
  final Map<String, LifeScene> scenes;
  final Map<String, StoryBook> stories;

  /// Uyarılar (hata yoksa paket yine de kurulur).
  final ContentIssues issues;

  /// [paths] içerik köküne göre yollar: "careers.json", "events/school.json", "stories/son_vapur.json".
  /// Doğrulama hatası varsa [ContentException] fırlatır — tanımsız bayrakla açılış yapılmaz.
  static Future<GameContent> load(Iterable<String> paths, ReadText read) async {
    final raw = await readRaw(paths, read);
    final issues = validateContent(raw);
    if (!issues.ok) throw ContentException(issues);
    return GameContent._(raw, issues);
  }

  static Future<RawContent> readRaw(Iterable<String> paths, ReadText read) async {
    final all = paths.where((p) => p.endsWith('.json') && !p.split('/').last.startsWith('.')).toList();
    Future<Object?> json(String p) async => jsonDecode(await read(p));
    Future<List<Json>> list(String p) async => (await json(p) as List).cast<Json>();

    final events = <String, List<Json>>{};
    final stories = <String, Json>{};
    for (final p in all) {
      final name = p.split('/').last;
      if (p.startsWith('events/')) events[name] = await list(p);
      if (p.startsWith('stories/')) stories[name] = await json(p) as Json;
    }
    return RawContent(
      flags: await list('flags.json'),
      careers: await list('careers.json'),
      families: await list('families.json'),
      events: events,
      goals: await list('goals.json'),
      achievements: await list('achievements.json'),
      endings: await list('endings.json'),
      life: await json('life.json') as Json,
      scenes: await list('life_scenes.json'),
      stories: stories,
    );
  }
}
