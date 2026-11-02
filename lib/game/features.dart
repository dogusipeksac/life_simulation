/// Yayın bayrakları (derleme anında `--dart-define` ile değiştirilebilir).
abstract final class Features {
  /// Reklamlar (ödüllü + geçiş). İlk sürümde açık; kapatmak için `--dart-define=ADS_LIVE=false`.
  static const adsLive = bool.fromEnvironment('ADS_LIVE', defaultValue: true);

  /// Uygulama içi satın alma. Play Console ürünleri tanımlanınca `PURCHASES_LIVE=true`.
  static const purchasesLive = bool.fromEnvironment('PURCHASES_LIVE', defaultValue: false);

  /// Geriye uyum: eski adlandırma.
  static const monetizationLive = adsLive;

  /// Reklam yokken ödüller ücretsiz verilir.
  static bool get fullAccess => !adsLive;

  /// İlk sürümde okunabilen kitaplar; diğerleri kütüphanede "Yakında" olarak kilitli görünür.
  static const releasedBooks = {'son_vapur'};
  static bool released(String bookId) => releasedBooks.contains(bookId);
}
