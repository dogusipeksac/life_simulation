// Yerel kayıt ve sürüm geçişleri. Atomik yazım: X.tmp yaz → mevcut dosya X.bak olur →
// X.tmp asıl dosyanın yerine taşınır. Okuma sırası: asıl → .tmp → .bak.
// (Godot: Systems/SaveService.cs, Systems/AtomicFile.cs)

import 'dart:convert';
import 'dart:io';

import 'local_crypto.dart';
import 'state.dart';

enum LoadStatus { loaded, noSave, corrupted, unsupportedVersion }

class LoadResult {
  const LoadResult(this.status, {this.state, this.loadedFrom, this.problems = const []});
  final LoadStatus status;
  final GameState? state;
  final String? loadedFrom;
  final List<String> problems;
}

class UnsupportedSaveVersion implements Exception {
  UnsupportedSaveVersion(this.version);
  final int version;
  @override
  String toString() => 'Kayıt sürümü $version, bu uygulama en fazla ${GameState.currentSaveVersion} okuyabilir.';
}

/// Oyuncuya gösterilen metinler (Godot: UI/Main.cs).
const unsupportedSaveMessage =
    'Bu kayıt uygulamanın daha yeni bir sürümüyle yapılmış. Uygulamayı güncelle ya da yeni bir hayata başla.';
const corruptedSaveMessage = 'Kayıt dosyan ve yedeği okunamadı. Üzgünüz; yeni bir hayata başlayabilirsin.';

class SaveService {
  SaveService(this.savePath);

  final String savePath;
  String get tempPath => _withExt('.tmp');
  String get backupPath => _withExt('.bak');
  List<String> get readOrder => [savePath, tempPath, backupPath];

  String _withExt(String ext) {
    final dot = savePath.lastIndexOf('.');
    final slash = savePath.lastIndexOf(Platform.pathSeparator);
    return (dot > slash ? savePath.substring(0, dot) : savePath) + ext;
  }

  bool hasSave() => readOrder.any((p) => File(p).existsSync());

  bool save(GameState state) {
    try {
      final temp = File(tempPath);
      temp.parent.createSync(recursive: true);
      temp.writeAsStringSync(LocalCrypto.seal(serialize(state)), flush: true);
      final main = File(savePath);
      if (main.existsSync()) {
        final backup = File(backupPath);
        if (backup.existsSync()) backup.deleteSync();
        main.renameSync(backupPath);
      }
      temp.renameSync(savePath);
      return true;
    } on FileSystemException {
      // Asıl dosya yoksa da .tmp tam ve .bak sağlam; okuyan taraf ikisini de dener.
      return false;
    }
  }

  void deleteAll() {
    for (final p in readOrder) {
      final f = File(p);
      if (f.existsSync()) f.deleteSync();
    }
  }

  LoadResult load() {
    final problems = <String>[];
    var anyFile = false, unsupported = false;
    for (final path in readOrder) {
      final f = File(path);
      if (!f.existsSync()) continue;
      anyFile = true;
      try {
        return LoadResult(LoadStatus.loaded, state: deserialize(LocalCrypto.open(f.readAsStringSync())), loadedFrom: path, problems: problems);
      } on UnsupportedSaveVersion catch (e) {
        unsupported = true;
        problems.add('$path: $e');
      } catch (e) {
        problems.add('$path: $e');
      }
    }
    if (!anyFile) return LoadResult(LoadStatus.noSave, problems: problems);
    return LoadResult(unsupported ? LoadStatus.unsupportedVersion : LoadStatus.corrupted, problems: problems);
  }

  static String serialize(GameState s) => jsonEncode(s.toJson());

  static GameState deserialize(String json) {
    final root = jsonDecode(json);
    if (root is! Map<String, dynamic>) throw const FormatException('Kök JSON nesnesi değil.');
    final version = root['SaveVersion'] is int ? root['SaveVersion'] as int : 0;
    if (version < 1) throw const FormatException('SaveVersion eksik veya geçersiz.');
    if (version > GameState.currentSaveVersion) throw UnsupportedSaveVersion(version);
    migrate(root, version);
    return GameState.fromJson(root)..ensureValid();
  }

  /// Kayıt sürümünü adım adım güncel sürüme taşır.
  static void migrate(Map<String, dynamic> root, int fromVersion) {
    for (var v = fromVersion; v < GameState.currentSaveVersion; v++) {
      switch (v) {
        case 1:
          root['CareerApplicationDay'] ??= <String, dynamic>{};
          root['PensionMonthly'] ??= 0;
          root['StudyLevel'] = null;
          root['CareerLevel'] = ((root['CareerId'] as String?) ?? '').isEmpty ? 0 : 1;
        case 2:
          root['ActiveGoalIds'] ??= <dynamic>[];
          root['CompletedGoalIds'] ??= <dynamic>[];
          root['AchievementsThisLife'] ??= <dynamic>[];
        case 3:
          // Eski hayatlar yaşını ve klasik temposunu korur; kayıt asla baştan başlamaz.
          root['Profile'] ??= <String, dynamic>{};
          root['Journal'] ??= <dynamic>[];
          root['TotalChoices'] ??= (root['CompletedEventIds'] as List?)?.length ?? 0;
        case 4:
          root['Relationships'] ??= <dynamic>[];
          root['ActionLastDay'] ??= <String, dynamic>{};
        case 5:
          root['Simulation'] ??= <String, dynamic>{};
        case 6:
          // Gerçek sayılar bilinmez; görülmüş her olay en az bir kez sayılır.
          root['EventShowCounts'] ??= <String, dynamic>{
            for (final id in ((root['EventLastSeenDay'] as Map?) ?? const {}).keys) id as String: 1,
          };
        case 7:
          root['MomentKey'] ??= '';
        default:
          throw FormatException('v$v → v${v + 1} için migration tanımlı değil.');
      }
      root['SaveVersion'] = v + 1;
    }
  }
}
