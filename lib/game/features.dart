/// Yayın bayrakları. Canlı monetizasyonu açmak için:
/// `--dart-define=MONETIZATION_LIVE=true` veya aşağıdaki varsayılanı `true` yap.
abstract final class Features {
  /// Reklam + uygulama içi satın alma. İlk sürümde kapalı → tam erişim.
  static const monetizationLive = bool.fromEnvironment(
    'MONETIZATION_LIVE',
    defaultValue: false,
  );

  /// Monetizasyon kapalıyken hikâyeler açık, reklam yok, ödüller ücretsiz.
  static bool get fullAccess => !monetizationLive;
}
