// Mağazadan doğrulanmış/onaylanmış işlemler; çevrimdışı önbellekte yalnızca ürün ID'leri.
import 'dart:async';
import 'dart:convert';

import 'atomic_file.dart';
import 'billing.dart';
import 'features.dart';
import 'session.dart' show ActionResult;

class StoryStore {
  StoryStore(Iterable<String> products, this.file, {this.gateway})
    : _known = {...products.where((p) => p.isNotEmpty), 'remove_ads'};
  final AtomicTextFile file;
  final BillingGateway? gateway;
  final Set<String> _known;
  Set<String> _owned = {};
  StreamSubscription<BillingUpdate>? _subscription;
  Timer? _purchaseTimeout;
  String? _buying;
  int _purchaseGeneration = 0;
  bool _restoring = false, _disposed = false, _initialized = false;
  final Set<String> _verifiedDuringRestore = {};
  String notice = '';
  void Function()? onChanged;
  bool owns(String product) =>
      Features.fullAccess ||
      (_known.contains(product) && _owned.contains(product));
  bool get adsRemoved => Features.fullAccess || owns('remove_ads');
  bool get busy => _buying != null || _restoring;
  bool canPurchase(String product) =>
      !Features.fullAccess &&
      _known.contains(product) &&
      !owns(product) &&
      !busy &&
      (gateway?.available ?? false) &&
      price(product).isNotEmpty;
  String price(String product) => gateway?.prices[product] ?? '';
  String get status => Features.fullAccess
      ? 'Bu sürümde mağaza kapalı; tüm hikâyeler açık. Sonraki sürümde satın alımlar eklenecek.'
      : gateway?.status ??
          'Bu cihazda mağaza kullanılamıyor. Ücretsiz başlangıç bölümlerini okuyabilirsin.';
  void _changed() {
    if (!_disposed) onChanged?.call();
  }

  Future<void> initialize() async {
    if (_initialized || gateway == null) return;
    _initialized = true;
    gateway!.onChanged = _changed;
    _subscription = gateway!.updates.listen(
      _update,
      onError: (_) {
        notice = 'Mağaza bağlantısı kesildi. Mevcut satın alımların korunuyor.';
        _endPurchase();
        _changed();
      },
    );
    try {
      await gateway!.initialize(_known);
    } catch (_) {
      notice = 'Mağazaya bağlanılamadı. Mevcut satın alımların korunuyor.';
    }
    _changed();
  }

  ActionResult purchase(String product) {
    if (!canPurchase(product)) {
      return const ActionResult(
        false,
        'Satın alma şu anda kullanılamıyor. Ücret alınmadı.',
      );
    }
    _buying = product;
    final generation = ++_purchaseGeneration;
    notice = 'Mağaza işlemi başlatılıyor…';
    _changed();
    _purchaseTimeout = Timer(const Duration(minutes: 2), () {
      if (generation != _purchaseGeneration) return;
      _endPurchase();
      notice = 'İşlem henüz sonuçlanmadı. Mağazadan geri yükleyerek kontrol edebilirsin.';
      _changed();
    });
    unawaited(_purchase(product, generation));
    return ActionResult(true, notice);
  }

  Future<void> _purchase(String product, int generation) async {
    try {
      final result = await gateway!.purchase(product);
      if (_disposed || generation != _purchaseGeneration || _buying != product) {
        return;
      }
      if (!result.success) {
        _endPurchase();
        notice = result.message;
        _changed();
      }
    } catch (_) {
      if (_disposed || generation != _purchaseGeneration || _buying != product) {
        return;
      }
      _endPurchase();
      notice =
          'Satın alma başlatılamadı. Mağazadan geri yüklemeyi deneyebilirsin.';
      _changed();
    }
  }

  ActionResult restore() {
    if (gateway == null) {
      return const ActionResult(
        false,
        'Geri yükleme, satın alımın yapıldığı mağazada kullanılabilir.',
      );
    }
    if (busy) {
      return const ActionResult(false, 'Devam eden mağaza işlemini bekle.');
    }
    _restoring = true;
    _verifiedDuringRestore.clear();
    notice = 'Satın alımlar kontrol ediliyor…';
    _changed();
    unawaited(_restore());
    return ActionResult(true, notice);
  }

  Future<void> _restore() async {
    try {
      final result = await gateway!.restore().timeout(
        const Duration(seconds: 30),
      );
      if (_disposed) return;
      notice = result.message;
      // Yalnızca tam ve doğrulanmış sorgu, eskiden alınan ürünleri kaldırabilir.
      if (result.success) {
        _persist(
          {...result.products, ..._verifiedDuringRestore}.intersection(_known),
        );
      }
    } catch (_) {
      notice = 'Satın alımlar kontrol edilemedi. Mevcut kütüphanen korunuyor.';
    }
    _restoring = false;
    _changed();
  }

  void _update(BillingUpdate update) {
    if (_disposed || !_known.contains(update.product)) return;
    notice = update.message;
    if (update.state == BillingState.verified) {
      if (_restoring) _verifiedDuringRestore.add(update.product);
      _persist({..._owned, update.product});
    }
    if (update.state != BillingState.pending && update.product == _buying) {
      _endPurchase();
    }
    _changed();
  }

  void _endPurchase() {
    _purchaseGeneration++;
    _purchaseTimeout?.cancel();
    _purchaseTimeout = null;
    _buying = null;
  }

  void _persist(Set<String> products) {
    if (!file.write(
      jsonEncode({'Version': 1, 'Products': products.toList()}),
    )) {
      notice = 'Satın alımın mağazada duruyor ancak cihaz önbelleği yazılamadı. Depolama alanını kontrol edip geri yükle.';
      // Mağaza doğrulaması bu oturumda geçerli; sonraki açılışta tekrar geri yüklenebilir.
    }
    _owned = products;
  }

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

  void dispose() {
    _disposed = true;
    _endPurchase();
    _subscription?.cancel();
    gateway?.dispose();
    onChanged = null;
  }
}
