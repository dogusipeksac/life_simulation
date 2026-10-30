import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pointycastle/export.dart';

/// Cihazdaki kayıtları AES-256-GCM ile kilitler.
/// Anahtar Android Keystore / iOS Keychain'de durur; dosya düz JSON değildir.
class LocalCrypto {
  static const prefix = 'HS1.';
  static const _storageKey = 'hs_vault_key_v1';
  static const _macBits = 128;
  static const _nonceBytes = 12;
  static const _keyBytes = 32;

  static Uint8List? _key;
  static bool get enabled => _key != null && _key!.length == _keyBytes;

  /// Testler için bellek anahtarı. Üretimde [unlock] kullanılır.
  static void useKey(Uint8List key) {
    if (key.length != _keyBytes) {
      throw ArgumentError('Kayıt anahtarı $_keyBytes bayt olmalı.');
    }
    _key = Uint8List.fromList(key);
  }

  static void disable() => _key = null;

  static Future<void> unlock({FlutterSecureStorage? storage}) async {
    final store = storage ??
        const FlutterSecureStorage(
          aOptions: AndroidOptions(encryptedSharedPreferences: true),
          iOptions: IOSOptions(
            accessibility: KeychainAccessibility.first_unlock_this_device,
          ),
        );
    var encoded = await store.read(key: _storageKey);
    if (encoded == null || encoded.isEmpty) {
      final key = _randomBytes(_keyBytes);
      encoded = base64UrlEncode(key);
      await store.write(key: _storageKey, value: encoded);
      _key = key;
      return;
    }
    _key = Uint8List.fromList(base64Url.decode(encoded));
    if (_key!.length != _keyBytes) {
      throw const FormatException('Kayıt anahtarı bozuk.');
    }
  }

  /// Yazılacak metni kilitler. Anahtar yoksa (test) düz bırakır.
  static String seal(String plaintext) {
    if (!enabled) return plaintext;
    final nonce = _randomBytes(_nonceBytes);
    final cipher = GCMBlockCipher(AESEngine())
      ..init(
        true,
        AEADParameters(KeyParameter(_key!), _macBits, nonce, Uint8List(0)),
      );
    final sealed = cipher.process(Uint8List.fromList(utf8.encode(plaintext)));
    return prefix + base64UrlEncode(Uint8List.fromList([...nonce, ...sealed]));
  }

  /// Kilitli metni açar. Eski düz JSON kayıtları olduğu gibi döner.
  static String open(String stored) {
    if (!stored.startsWith(prefix)) return stored;
    if (!enabled) {
      throw const FormatException('Kayıt kilitli; bu oturumda anahtar yok.');
    }
    final packed = Uint8List.fromList(base64Url.decode(stored.substring(prefix.length)));
    if (packed.length < _nonceBytes + _macBits ~/ 8) {
      throw const FormatException('Kilitli kayıt eksik.');
    }
    final nonce = packed.sublist(0, _nonceBytes);
    final body = packed.sublist(_nonceBytes);
    final cipher = GCMBlockCipher(AESEngine())
      ..init(
        false,
        AEADParameters(KeyParameter(_key!), _macBits, nonce, Uint8List(0)),
      );
    try {
      return utf8.decode(cipher.process(body));
    } catch (_) {
      throw const FormatException('Kayıt açılamadı. Anahtar bu cihaza ait değil veya dosya bozulmuş.');
    }
  }

  static Uint8List _randomBytes(int n) {
    final rnd = Random.secure();
    return Uint8List.fromList(List<int>.generate(n, (_) => rnd.nextInt(256)));
  }
}
