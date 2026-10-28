import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:pointycastle/asn1.dart';
import 'package:pointycastle/export.dart';
import 'package:life_simulation/content/game_content.dart';
import 'package:life_simulation/game/achievements.dart';
import 'package:life_simulation/game/atomic_file.dart';
import 'package:life_simulation/game/billing.dart';
import 'package:life_simulation/game/monetization.dart';
import 'package:life_simulation/game/play_purchase_verifier.dart';
import 'package:life_simulation/game/save.dart';
import 'package:life_simulation/game/session.dart';
import 'package:life_simulation/game/state.dart';
import 'package:life_simulation/game/story_store.dart';
import 'package:life_simulation/ui/game_controller.dart';

import 'content_test.dart' show contentPaths, readFile;

class FakeAds extends NoAds {
  bool ready = true, earned = true;
  int rewards = 0, interstitials = 0;
  Completer<bool>? pending;
  @override
  bool get rewardedAvailable => ready;
  @override
  bool get interstitialAvailable => ready;
  @override
  Future<bool> showRewarded() async {
    rewards++;
    return pending == null ? earned : pending!.future;
  }

  @override
  Future<bool> showInterstitial() async {
    interstitials++;
    return true;
  }
}

class FakeBilling implements BillingGateway {
  final events = StreamController<BillingUpdate>.broadcast(sync: true);
  @override
  bool available = true;
  @override
  String status = 'Test mağazası';
  @override
  Map<String, String> prices = {'remove_ads': '₺10', 'story': '₺20'};
  @override
  Stream<BillingUpdate> get updates => events.stream;
  @override
  void Function()? onChanged;
  RestoreResult restored = const RestoreResult(false, {}, 'Bağlantı yok');
  Completer<RestoreResult>? pendingRestore;
  @override
  Future<void> initialize(Set<String> products) async {}
  @override
  Future<ActionResult> purchase(String product) async =>
      const ActionResult(true, 'Bekleniyor');
  @override
  Future<RestoreResult> restore() async =>
      pendingRestore == null ? restored : pendingRestore!.future;
  @override
  void dispose() {
    events.close();
  }
}

class FailingFile extends AtomicTextFile {
  FailingFile(super.path);
  @override
  bool write(String text) => false;
}

void main() {
  late GameContent content;
  late Directory dir;
  late GameSession session;
  setUpAll(() async {
    content = await GameContent.load(contentPaths(), readFile);
  });
  setUp(() {
    dir = Directory.systemTemp.createTempSync('vita_p5_');
    session = GameSession(content, SaveService('${dir.path}/save.json'))
      ..startNewGame('Deniz', seed: 42);
  });
  tearDown(() => dir.deleteSync(recursive: true));
  GameState dead() => session.state!
    ..health = 0
    ..isGameOver = true
    ..gameOverReason = GameOverReason.healthDepleted;
  Future<void> flush() async {
    await Future<void>.delayed(Duration.zero);
  }

  test('breath reward completion, annual limits, save and no duplicate concurrent claims', () async {
    final ads = FakeAds();
    final game = GameController(session, ads: ads);
    addTearDown(game.dispose);
    final s = session.state!, before = s.happiness;
    ads.earned = false;
    expect((await game.rewardedBreath()).success, isFalse);
    expect(s.rewardedBreathsUsed, 0);
    ads.earned = true;
    for (var i = 0; i < 3; i++) {
      expect((await game.rewardedBreath()).success, isTrue);
    }
    expect(s.happiness, before + 18);
    expect((await game.rewardedBreath()).success, isFalse);
    expect(session.saves.load().state!.rewardedBreathsUsed, 3);
    s.rewardedBreathsUsed = 0;
    ads.pending = Completer<bool>();
    final request = game.rewardedBreath();
    expect((await game.rewardedBreath()).success, isFalse);
    ads.pending!.complete(true);
    expect((await request).success, isTrue);
    expect(s.rewardedBreathsUsed, 1);
  });
  test('late ad callback cannot reward a new life', () async {
    final ads = FakeAds()..pending = Completer<bool>();
    final game = GameController(session, ads: ads);
    addTearDown(game.dispose);
    final request = game.rewardedBreath();
    game.startNewGame('Yeni', seed: 7);
    final before = game.state!.happiness;
    ads.pending!.complete(true);
    expect((await request).success, isFalse);
    expect(game.state!.happiness, before);
    expect(game.state!.rewardedBreathsUsed, 0);
  });
  test(
    'second chance only for health death and once, restores 20 health',
    () async {
      dead();
      final ads = FakeAds()..earned = false;
      final game = GameController(session, ads: ads);
      addTearDown(game.dispose);
      expect((await game.secondChance()).success, isFalse);
      expect(session.state!.isGameOver, isTrue);
      ads.earned = true;
      expect((await game.secondChance()).success, isTrue);
      expect(session.state!.health, 20);
      expect(session.state!.secondChanceUsed, isTrue);
      expect(session.state!.isGameOver, isFalse);
      dead();
      expect((await game.secondChance()).success, isFalse);
      session.startNewGame('Diğer', seed: 3);
      session.state!
        ..isGameOver = true
        ..gameOverReason = GameOverReason.oldAge;
      expect((await game.secondChance()).success, isFalse);
    },
  );
  test(
    'interstitial requires ten minutes, twenty choices and three minute gap',
    () {
      var time = Duration.zero;
      final p = InterstitialPolicy(elapsed: () => time);
      final s = session.state!..totalChoices = 20;
      expect(p.due(s, adsRemoved: false, ready: true), isFalse);
      time = const Duration(minutes: 10);
      expect(p.due(s, adsRemoved: false, ready: true), isTrue);
      p.record(s);
      s.totalChoices = 40;
      expect(p.due(s, adsRemoved: false, ready: true), isFalse);
      time = const Duration(minutes: 13);
      expect(p.due(s, adsRemoved: false, ready: true), isTrue);
      expect(p.due(s, adsRemoved: true, ready: true), isFalse);
      expect(p.due(s, adsRemoved: false, ready: false), isFalse);
      s.isGameOver = true;
      expect(p.due(s, adsRemoved: false, ready: true), isFalse);
    },
  );
  test(
    'continue advances once across concurrent interstitial requests',
    () async {
      final ads = FakeAds();
      final p = InterstitialPolicy(elapsed: () => const Duration(minutes: 11));
      final game = GameController(session, ads: ads, interstitialPolicy: p);
      addTearDown(game.dispose);
      session.state!
        ..totalChoices = 20
        ..pendingEventId = null;
      await Future.wait([game.continueAfterAd(), game.continueAfterAd()]);
      expect(ads.interstitials, 1);
    },
  );
  test('achievements persist across lives, secret titles hidden, endings awarded once', () {
    final service = session.achievements;
    expect(
      service.views.firstWhere((a) => a.id == 'ach_phoenix').title,
      'Gizli başarım',
    );
    final s = session.state!..flags.add('recovered_from_bankruptcy');
    expect(
      service.check(s, atGameOver: false).map((a) => a.id),
      contains('ach_phoenix'),
    );
    expect(service.check(s, atGameOver: false), isEmpty);
    expect(service.isUnlocked('ach_first_life'), isFalse);
    s.health = 0;
    s.pendingEventId = null;
    session.advanceToBirthday();
    expect(service.isUnlocked('ach_first_life'), isTrue);
    expect(s.achievementsThisLife, contains('ach_first_life'));
    final summary = session.buildLifeSummary()!;
    expect(summary.achievements, contains('İlk Hayat'));
    expect(summary.memories.length, lessThanOrEqualTo(3));
    session.startNewGame('Yeni', seed: 6);
    final restored = AchievementService(content.achievements, service.file)
      ..load();
    expect(restored.isUnlocked('ach_first_life'), isTrue);
    expect(restored.isUnlocked('ach_phoenix'), isTrue);
    expect(session.state!.achievementsThisLife, isEmpty);
  });
  test(
    'achievement write failure is retryable and backup recovers progress',
    () {
      final s = session.state!..flags.add('returned_wallet');
      final broken = AchievementService(
        content.achievements,
        FailingFile('${dir.path}/bad.json'),
      );
      expect(broken.check(s, atGameOver: false), isEmpty);
      expect(broken.isUnlocked('ach_honest_child'), isFalse);
      final service = session.achievements;
      service.check(s, atGameOver: false);
      s.flags.add('owns_house');
      service.check(s, atGameOver: false);
      File(service.file.path).writeAsStringSync('bad');
      service.load();
      expect(service.isUnlocked('ach_honest_child'), isTrue);
      expect(service.notice, contains('yedekten'));
    },
  );
  test(
    'store never unlocks pending, canceled, failed, or unknown products',
    () async {
      final gateway = FakeBilling();
      final store = StoryStore(
        ['story'],
        AtomicTextFile('${dir.path}/products.json'),
        gateway: gateway,
      );
      addTearDown(store.dispose);
      await store.initialize();
      expect(store.purchase('story').success, isTrue);
      expect(store.canPurchase('story'), isFalse);
      for (final state in [
        BillingState.pending,
        BillingState.failed,
        BillingState.canceled,
      ]) {
        gateway.events.add(BillingUpdate('story', state, 'test'));
        expect(store.owns('story'), isFalse);
      }
      gateway.events.add(
        const BillingUpdate('unknown', BillingState.verified, 'x'),
      );
      expect(store.owns('unknown'), isFalse);
      gateway.events.add(
        const BillingUpdate('story', BillingState.verified, 'ok'),
      );
      expect(store.owns('story'), isTrue);
      gateway.events.add(
        const BillingUpdate('remove_ads', BillingState.verified, 'ok'),
      );
      expect(store.adsRemoved, isTrue);
      final restored = StoryStore(['story'], store.file)..load();
      expect(restored.owns('story'), isTrue);
      expect(restored.adsRemoved, isTrue);
      await flush();
    },
  );
  test(
    'failed restore preserves cache; verified full restore can revoke',
    () async {
      final gateway = FakeBilling();
      final store = StoryStore(
        ['story'],
        AtomicTextFile('${dir.path}/products.json'),
        gateway: gateway,
      );
      addTearDown(store.dispose);
      await store.initialize();
      gateway.events.add(
        const BillingUpdate('story', BillingState.verified, 'ok'),
      );
      store.restore();
      await flush();
      expect(store.owns('story'), isTrue);
      gateway.restored = const RestoreResult(true, {}, 'Tam sorgu');
      store.restore();
      await flush();
      expect(store.owns('story'), isFalse);
    },
  );
  test(
    'concurrent verified purchase survives a successful older restore snapshot',
    () async {
      final gateway = FakeBilling()
        ..pendingRestore = Completer<RestoreResult>();
      final store = StoryStore(
        ['story'],
        AtomicTextFile('${dir.path}/products.json'),
        gateway: gateway,
      );
      addTearDown(store.dispose);
      await store.initialize();
      expect(store.restore().success, isTrue);
      gateway.events.add(
        const BillingUpdate('story', BillingState.verified, 'ok'),
      );
      gateway.pendingRestore!.complete(
        const RestoreResult(true, {}, 'Eski sorgu'),
      );
      await flush();
      expect(store.owns('story'), isTrue);
    },
  );
  test(
    'loading an old finished life records and persists the ending achievement',
    () {
      final old = session.state!
        ..health = 0
        ..isGameOver = true
        ..gameOverReason = GameOverReason.healthDepleted;
      old.pendingEventId = null;
      session.save();
      final upgraded = GameSession(content, session.saves)..continueGame();
      expect(upgraded.state!.achievementsThisLife, contains('ach_first_life'));
      expect(
        upgraded.saves.load().state!.achievementsThisLife,
        contains('ach_first_life'),
      );
    },
  );
  test(
    'RSA receipt validates signature and signed package/product/token/state',
    () {
      final random = FortunaRandom()
        ..seed(
          KeyParameter(Uint8List.fromList(List.generate(32, (i) => i + 1))),
        );
      final generator = RSAKeyGenerator()
        ..init(
          ParametersWithRandom(
            RSAKeyGeneratorParameters(BigInt.from(65537), 2048, 64),
            random,
          ),
        );
      final pair = generator.generateKeyPair();
      final public = pair.publicKey, private = pair.privateKey;
      final sequence = ASN1Sequence(
        elements: [ASN1Integer(public.modulus), ASN1Integer(public.exponent)],
      );
      final verifier = PlayPurchaseVerifier(
        base64Encode(sequence.encode()),
        'app.vita',
      );
      String sign(String text) {
        final signer = Signer('SHA-1/RSA')
          ..init(true, PrivateKeyParameter<RSAPrivateKey>(private));
        return base64Encode(
          (signer.generateSignature(
            Uint8List.fromList(utf8.encode(text)),
          ) as RSASignature).bytes,
        );
      }

      final receipt = jsonEncode({
        'packageName': 'app.vita',
        'productId': 'story',
        'purchaseToken': 'token',
        'purchaseState': 0,
      });
      final signature = sign(receipt);
      expect(verifier.configured, isTrue);
      expect(
        verifier.verify(
          originalJson: receipt,
          signature: signature,
          product: 'story',
          token: 'token',
        ),
        isTrue,
      );
      expect(
        verifier.verify(
          originalJson: receipt.replaceAll('app.vita', 'other'),
          signature: signature,
          product: 'story',
          token: 'token',
        ),
        isFalse,
      );
      expect(
        verifier.verify(
          originalJson: receipt,
          signature: signature,
          product: 'other',
          token: 'token',
        ),
        isFalse,
      );
      expect(
        verifier.verify(
          originalJson: receipt,
          signature: signature,
          product: 'story',
          token: 'wrong',
        ),
        isFalse,
      );
      final pending = receipt.replaceAll(
        '"purchaseState":0',
        '"purchaseState":2',
      );
      expect(
        verifier.verify(
          originalJson: pending,
          signature: sign(pending),
          product: 'story',
          token: 'token',
        ),
        isFalse,
      );
      expect(PlayPurchaseVerifier('', 'app.vita').configured, isFalse);
    },
  );
}
