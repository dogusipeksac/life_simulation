// Godot StoryBillingBridge._verified: Google Play SHA1/RSA, paket/ürün/token.
import 'dart:convert';
import 'dart:typed_data';

import 'package:pointycastle/asn1.dart';
import 'package:pointycastle/export.dart';

class PlayPurchaseVerifier {
  PlayPurchaseVerifier(String encodedKey, this.packageName) {
    if (encodedKey.trim().isEmpty) return;
    try {
      final body = encodedKey
          .replaceAll(RegExp(r'-----[^-]+-----'), '')
          .replaceAll(RegExp(r'\s'), '');
      var sequence =
          ASN1Parser(base64Decode(body)).nextObject() as ASN1Sequence;
      if (sequence.elements!.first is ASN1Sequence) {
        final bits = sequence.elements![1] as ASN1BitString;
        sequence =
            ASN1Parser(Uint8List.fromList(bits.stringValues!)).nextObject()
                as ASN1Sequence;
      }
      final modulus = (sequence.elements![0] as ASN1Integer).integer!;
      final exponent = (sequence.elements![1] as ASN1Integer).integer!;
      if (modulus.bitLength < 2048 || exponent <= BigInt.one) return;
      _key = RSAPublicKey(modulus, exponent);
    } catch (_) {
      _key = null;
    }
  }
  final String packageName;
  RSAPublicKey? _key;
  bool get configured => _key != null;
  bool verify({
    required String originalJson,
    required String signature,
    required String product,
    required String token,
  }) {
    if (_key == null ||
        originalJson.isEmpty ||
        signature.isEmpty ||
        token.isEmpty) {
      return false;
    }
    try {
      final signer = Signer('SHA-1/RSA')
        ..init(false, PublicKeyParameter<RSAPublicKey>(_key!));
      if (!signer.verifySignature(
        Uint8List.fromList(utf8.encode(originalJson)),
        RSASignature(base64Decode(signature)),
      )) {
        return false;
      }
      final signed = jsonDecode(originalJson);
      if (signed is! Map ||
          signed['packageName'] != packageName ||
          signed['purchaseState'] != 0 ||
          (signed['purchaseToken'] ?? signed['token']) != token) {
        return false;
      }
      final products = <String>{
        if (signed['productId'] is String) signed['productId'] as String,
        ...?(signed['productIds'] as List?)?.whereType<String>(),
      };
      return products.contains(product);
    } catch (_) {
      return false;
    }
  }
}
