class UpdateInfo {
  final int latestVersionCode;
  final int minRequiredVersionCode;
  final String title;
  final String description;
  final bool forceUpdate;
  final bool isMaintenance;
  final String confirmButtonText;
  final String? cancelButtonText;

  /// Play Store listing URL; uygulama varsayılanına düşebilir.
  final String? androidStoreUrl;

  /// App Store listing URL; uygulama varsayılanına düşebilir.
  final String? iosStoreUrl;

  UpdateInfo({
    required this.latestVersionCode,
    required this.minRequiredVersionCode,
    required this.title,
    required this.description,
    required this.forceUpdate,
    this.isMaintenance = false,
    required this.confirmButtonText,
    this.cancelButtonText,
    this.androidStoreUrl,
    this.iosStoreUrl,
  });
}
