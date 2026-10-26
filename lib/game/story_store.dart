// P4: kaynak projedeki mağaza bulunamayan cihaz davranışı. Mağaza köprüsü P5'te.
import 'dart:convert';

import 'atomic_file.dart';
import 'session.dart' show ActionResult;

class StoryStore {
  StoryStore(Iterable<String> products, this.file)
    : _known = products.where((p) => p.isNotEmpty).toSet();
  final AtomicTextFile file;
  final Set<String> _known;
  Set<String> _owned = {};
  bool owns(String product) =>
      _known.contains(product) && _owned.contains(product);
  bool canPurchase(String product) => false;
  String price(String product) => '';
  String get status =>
      'Bu cihazda mağaza kullanılamıyor. Ücretsiz başlangıç bölümlerini okuyabilirsin.';
  ActionResult purchase(String product) => const ActionResult(
    false,
    'Satın alma şu anda kullanılamıyor. Ücret alınmadı.',
  );
  ActionResult restore() => const ActionResult(
    false,
    'Geri yükleme, satın alımın yapıldığı mağazada kullanılabilir.',
  );
  void load() {
    _owned = {};
    for (final path in file.readOrder) {
      final json = file.read(path);
      if (json == null) continue;
      try {
        final root = jsonDecode(json);
        if (root is! Map || root['Version'] != 1 || root['Products'] is! List) {
          continue;
        }
        _owned = (root['Products'] as List)
            .whereType<String>()
            .where(_known.contains)
            .toSet();
        return;
      } on FormatException {
        continue;
      }
    }
  }
}
