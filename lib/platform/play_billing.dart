import 'dart:async';
import 'dart:io';

import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:in_app_purchase_android/billing_client_wrappers.dart';
import 'package:in_app_purchase_platform_interface/in_app_purchase_platform_interface.dart';

import '../game/billing.dart';
import '../game/play_purchase_verifier.dart';
import '../game/session.dart' show ActionResult;

/// Android öncelikli, cihaz üzerinde RSA doğrulamalı, tüketilmeyen ürünler.
class PlayBilling implements BillingGateway {
  PlayBilling()
    : verifier = PlayPurchaseVerifier(
        const String.fromEnvironment('PLAY_BILLING_PUBLIC_KEY'),
        const String.fromEnvironment(
          'BILLING_PACKAGE_NAME',
          defaultValue: 'com.life.simulation',
        ),
      );
  final PlayPurchaseVerifier verifier;
  final _events = StreamController<BillingUpdate>.broadcast(sync: true);
  final Map<String, ProductDetails> _products = {};
  final Map<String, Future<bool>> _processing = {};
  final Set<String> _acknowledged = {};
  Set<String> _known = {};
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  bool _available = false, _disposed = false;
  @override
  bool get available => _available && verifier.configured && Platform.isAndroid;
  @override
  String status = 'Mağazaya bağlanılıyor…';
  @override
  Map<String, String> get prices => {
    for (final p in _products.values) p.id: p.price,
  };
  @override
  Stream<BillingUpdate> get updates => _events.stream;
  @override
  void Function()? onChanged;
  void _changed() {
    if (!_disposed) onChanged?.call();
  }

  @override
  Future<void> initialize(Set<String> products) async {
    _known = products;
    if (!Platform.isAndroid) {
      status = 'Bu platformda mağaza doğrulaması henüz yapılandırılmadı.';
      _changed();
      return;
    }
    final store = InAppPurchase.instance;
    _subscription = store.purchaseStream.listen(
      (purchases) {
        for (final p in purchases) {
          unawaited(_purchaseUpdate(p));
        }
      },
      onError: (_) {
        _available = false;
        status = 'Mağaza bağlantısı kesildi. Edindiğin hikâyeler çevrimdışı okunabilir.';
        _changed();
      },
    );
    try {
      _available = await store.isAvailable().timeout(
        const Duration(seconds: 15),
      );
      if (!_available) {
        status = 'Mağazaya bağlanılamadı. Ücretsiz bölümleri okumaya devam edebilirsin.';
        _changed();
        return;
      }
      final response = await store
          .queryProductDetails(products)
          .timeout(const Duration(seconds: 15));
      if (_disposed) return;
      if (response.error == null) {
        for (final p in response.productDetails) {
          if (_known.contains(p.id)) _products[p.id] = p;
        }
      }
      status = !verifier.configured
          ? 'Test sürümü: satış henüz açılmadı. Ücretsiz bölümleri okuyabilirsin.'
          : _products.isEmpty
          ? 'Mağazada bu sürüm için ürün bulunamadı.'
          : 'Tek seferlik satın alım · Abonelik yok';
    } catch (_) {
      _available = false;
      status = 'Mağazaya bağlanılamadı. Mevcut satın alımların korunuyor.';
    }
    _changed();
  }

  void _emit(BillingUpdate event) {
    if (!_disposed) _events.add(event);
  }

  Future<void> _purchaseUpdate(PurchaseDetails p) async {
    if (_disposed || !_known.contains(p.productID)) return;
    if (p.status == PurchaseStatus.pending) {
      _emit(
        BillingUpdate(
          p.productID,
          BillingState.pending,
          'Ödeme mağazada bekliyor. Tamamlanmadan içerik açılmaz.',
        ),
      );
      return;
    }
    if (p.status == PurchaseStatus.canceled ||
        p.status == PurchaseStatus.error) {
      _emit(
        BillingUpdate(
          p.productID,
          p.status == PurchaseStatus.canceled
              ? BillingState.canceled
              : BillingState.failed,
          p.status == PurchaseStatus.canceled
              ? 'Satın alma iptal edildi. İçerik değişmedi.'
              : 'Satın alma tamamlanamadı. Mağazadan geri yüklemeyi deneyebilirsin.',
        ),
      );
      return;
    }
    if (p.status != PurchaseStatus.purchased &&
        p.status != PurchaseStatus.restored) {
      return;
    }
    final ok = await _verifiedAndAcknowledged(p);
    _emit(
      BillingUpdate(
        p.productID,
        ok ? BillingState.verified : BillingState.failed,
        ok ? 'Satın alımın açıldı. İyi oyunlar!' : 'Satın alım doğrulanamadı veya mağaza onayı tamamlanmadı. Geri yükleyerek yeniden dene.',
      ),
    );
  }

  Future<bool> _verifiedAndAcknowledged(PurchaseDetails p) async {
    if (p is! GooglePlayPurchaseDetails || !_known.contains(p.productID)) {
      return false;
    }
    final purchase = p.billingClientPurchase;
    if (purchase.purchaseState != PurchaseStateWrapper.purchased ||
        !verifier.verify(
          originalJson: purchase.originalJson,
          signature: purchase.signature,
          product: p.productID,
          token: purchase.purchaseToken,
        )) {
      return false;
    }
    final token = purchase.purchaseToken;
    if (purchase.isAcknowledged || _acknowledged.contains(token)) return true;
    final existing = _processing[token];
    if (existing != null) return existing;
    final future = _acknowledge(p);
    _processing[token] = future;
    final ok = await future;
    _processing.remove(token);
    if (ok) _acknowledged.add(token);
    return ok;
  }

  Future<bool> _acknowledge(GooglePlayPurchaseDetails p) async {
    try {
      final platform = InAppPurchasePlatform.instance;
      if (platform is! InAppPurchaseAndroidPlatform) return false;
      final response = await platform
          .completePurchase(p)
          .timeout(const Duration(seconds: 15));
      return response.responseCode == BillingResponse.ok;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<ActionResult> purchase(String product) async {
    final details = _products[product];
    if (!available || details == null) {
      return const ActionResult(
        false,
        'Satın alma şu anda kullanılamıyor. Ücret alınmadı.',
      );
    }
    try {
      final started = await InAppPurchase.instance.buyNonConsumable(
        purchaseParam: PurchaseParam(productDetails: details),
      );
      return ActionResult(
        started,
        started
            ? 'Mağaza işlemi bekleniyor…'
            : 'Mağaza işlemi başlatılamadı. Ücret alınmadı.',
      );
    } catch (_) {
      return const ActionResult(
        false,
        'Satın alma başlatılamadı. Mağaza kaydını geri yükleyerek kontrol edebilirsin.',
      );
    }
  }

  @override
  Future<RestoreResult> restore() async {
    if (!available) {
      return const RestoreResult(
        false,
        {},
        'Geri yükleme şu anda kullanılamıyor. Mevcut satın alımların korunuyor.',
      );
    }
    try {
      final addition = InAppPurchase.instance
          .getPlatformAddition<InAppPurchaseAndroidPlatformAddition>();
      final response = await addition.queryPastPurchases().timeout(
        const Duration(seconds: 20),
      );
      if (response.error != null) {
        return const RestoreResult(
          false,
          {},
          'Satın alımlar kontrol edilemedi. Mevcut kütüphanen korunuyor.',
        );
      }
      final products = <String>{};
      for (final p in response.pastPurchases.where(
        (p) => _known.contains(p.productID),
      )) {
        if (p.status == PurchaseStatus.pending) {
          return const RestoreResult(
            false,
            {},
            'Ödeme mağazada bekliyor. Mevcut satın alımların korunuyor.',
          );
        }
        if (!await _verifiedAndAcknowledged(p)) {
          return const RestoreResult(
            false,
            {},
            'Bazı satın alımlar doğrulanamadı. Mevcut kütüphanen korunuyor.',
          );
        }
        products.add(p.productID);
      }
      return RestoreResult(
        true,
        products,
        'Satın alımlar kontrol edildi. ${products.length} ürün hesabında bulundu.',
      );
    } catch (_) {
      return const RestoreResult(
        false,
        {},
        'Mağaza yanıt vermedi. Mevcut satın alımların korunuyor.',
      );
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _subscription?.cancel();
    _events.close();
    onChanged = null;
  }
}
