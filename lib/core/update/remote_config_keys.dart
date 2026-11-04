/// Firebase Remote Config parametre anahtarları (force update / soft update / maintenance).
abstract final class RemoteConfigKeys {
  /// Android: en son yayınlanan versionCode (pubspec +N)
  static const androidLatestVersionCode = 'update_android_latest_version_code';
  /// Android: zorunlu minimum versionCode
  static const androidMinRequiredVersionCode =
      'update_android_min_required_version_code';

  /// iOS: en son yayınlanan buildNumber (pubspec +N)
  static const iosLatestVersionCode = 'update_ios_latest_version_code';
  /// iOS: zorunlu minimum buildNumber
  static const iosMinRequiredVersionCode =
      'update_ios_min_required_version_code';

  /// Tam ekran bakım modu (true ise uygulamayı kilitler)
  static const maintenance = 'update_maintenance';

  static const title = 'update_title';
  static const description = 'update_description';
  static const button = 'update_button';
  static const cancel = 'update_cancel';

  /// Özel mağaza URL'leri (boş ise varsayılan mağaza linkleri kullanılır)
  static const androidStoreUrl = 'update_android_store_url';
  static const iosStoreUrl = 'update_ios_store_url';
}
