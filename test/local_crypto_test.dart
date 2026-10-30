import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:life_simulation/content/game_content.dart';
import 'package:life_simulation/game/local_crypto.dart';
import 'package:life_simulation/game/save.dart';
import 'package:life_simulation/game/session.dart';

import 'content_test.dart' show contentPaths, readFile;

void main() {
  late GameContent content;
  late Directory dir;
  final key = Uint8List.fromList(List<int>.generate(32, (i) => i + 3));

  setUpAll(() async {
    content = await GameContent.load(contentPaths(), readFile);
  });
  setUp(() {
    LocalCrypto.useKey(key);
    dir = Directory.systemTemp.createTempSync('hs_crypto_');
  });
  tearDown(() {
    LocalCrypto.disable();
    dir.deleteSync(recursive: true);
  });

  test('kilit aç-kapa aynı metni verir', () {
    const text = '{"PlayerName":"Deniz"}';
    final sealed = LocalCrypto.seal(text);
    expect(sealed.startsWith(LocalCrypto.prefix), isTrue);
    expect(sealed.contains('Deniz'), isFalse);
    expect(LocalCrypto.open(sealed), text);
  });

  test('eski düz JSON kayıt okunur', () {
    expect(LocalCrypto.open('{"SaveVersion":1}'), '{"SaveVersion":1}');
  });

  test('hayat kaydı diskte düz ad içermez', () {
    final session = GameSession(content, SaveService('${dir.path}/savegame.json'))
      ..startNewGame('Deniz Yılmaz', seed: 11);
    expect(session.saves.save(session.state!), isTrue);
    final onDisk = File(session.saves.savePath).readAsStringSync();
    expect(onDisk.startsWith(LocalCrypto.prefix), isTrue);
    expect(onDisk.contains('Deniz'), isFalse);
    expect(session.saves.load().state!.playerName, 'Deniz Yılmaz');
  });
}
