import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:life_simulation/content/asset_content_loader.dart';
import 'package:life_simulation/content/content_validator.dart';
import 'package:life_simulation/content/game_content.dart';
import 'package:life_simulation/content/models.dart';

const root = 'assets/content';

Iterable<String> contentPaths() => Directory(root)
    .listSync(recursive: true)
    .whereType<File>()
    .map((f) => f.path.substring(root.length + 1).replaceAll(r'\', '/'));

Future<String> readFile(String p) => File('$root/$p').readAsString();

void main() {
  late GameContent content;

  setUpAll(() async => content = await GameContent.load(contentPaths(), readFile));

  test('bütün içerik doğrulanıyor', () {
    expect(content.issues.errors, isEmpty);
  });

  test('içerik sayıları Godot projesiyle aynı', () {
    expect(content.scenes.length, 87);
    expect(content.careers.length, 103);
    expect(content.families.length, 100);
    expect(content.goals.length, 10);
    expect(content.achievements.length, 15);
    expect(content.endings.length, 8);
    expect(content.flags.length, 200);
    expect(content.stories.length, 3);
    expect(content.events.length, 523);
  });

  test('varsayılanlar ve koşullar doğru çözülüyor', () {
    expect(content.life.declineStartAge, 35);
    expect(content.life.extraLossEveryYears, 13);
    expect(content.life.flagModifiers['smoker'], 2);
    final c = Condition.parse('MinStat:Health:40');
    expect((c.type, c.stat, c.value), (ConditionType.minStat, Stat.health, 40));
    expect(Condition.parse('MinEducation:University').value, Education.university.index);
    expect(content.careers['barista']!.education, Education.none);
    expect(content.stories['son_vapur']!.nodes.containsKey('start'), isTrue);
  });

  testWidgets('paketlenmiş varlıklardan da yükleniyor', (tester) async {
    final bundled = await tester.runAsync(loadBundledContent);
    expect(bundled!.events.length, content.events.length);
    expect(bundled.stories.keys, content.stories.keys);
  });

  group('bozuk içerik testi kırar', () {
    late RawContent raw;
    setUp(() async => raw = await GameContent.readRaw(contentPaths(), readFile));

    Json firstEvent() => raw.events.values.first.first;

    test('tanımsız bayrak', () {
      (firstEvent()['choices'] as List).first['set'] = ['yok_boyle_bayrak'];
      expect(validateContent(raw).errors, contains(contains("'yok_boyle_bayrak'")));
    });

    test('eksik next hedefi', () {
      (firstEvent()['choices'] as List).first['next'] = 'olmayan_olay';
      expect(validateContent(raw).errors, contains(contains("next 'olmayan_olay' bulunamadı")));
    });

    test('geçersiz yaş aralığı', () {
      firstEvent()
        ..['minAge'] = 50
        ..['maxAge'] = 10;
      expect(validateContent(raw).errors, contains(contains('minAge 50 > maxAge 10')));
    });

    test('eksik sahne devamı', () {
      ((raw.scenes.first['Choices'] as List).first as Json)['Next'] = 'lived_yok';
      expect(validateContent(raw).errors, contains(contains("'lived_yok'")));
    });

    test('kitapta kırık Next', () {
      final book = raw.stories.values.first;
      final start = (book['Nodes'] as Map)[book['Start']] as Json;
      ((start['Choices'] as List).first as Json)['Next'] = 'kayip_dugum';
      expect(validateContent(raw).errors, contains(contains("'kayip_dugum'")));
    });

    test('yükleyici hatada açılmıyor', () async {
      final broken = jsonDecode(await readFile('flags.json')) as List;
      broken.removeWhere((f) => f['key'] == 'studying');
      expect(
        GameContent.load(contentPaths(), (p) async => p == 'flags.json' ? jsonEncode(broken) : readFile(p)),
        throwsA(isA<ContentException>()),
      );
    });
  });
}
