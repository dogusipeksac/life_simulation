import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:update_checker_package/update_checker_package.dart';
import 'package:life_simulation/core/update/remote_config_keys.dart';

/// Firebase Remote Config verilerini [UpdateInfo] nesnesine dönüştüren sağlayıcı.
class RemoteConfigUpdateInfoProvider implements UpdateInfoProvider {
  RemoteConfigUpdateInfoProvider({FirebaseRemoteConfig? remoteConfig})
      : _customRemoteConfig = remoteConfig;

  final FirebaseRemoteConfig? _customRemoteConfig;
  FirebaseRemoteConfig? get _remoteConfig {
    if (_customRemoteConfig != null) return _customRemoteConfig;
    if (Firebase.apps.isEmpty) return null;
    return FirebaseRemoteConfig.instance;
  }

  var _ready = false;

  static const defaultPlayStoreUrl =
      'https://play.google.com/store/apps/details?id=com.dogusipeksac.lifesimulation';
  static const defaultAppStoreUrl =
      'https://apps.apple.com/app/id6754897042';

  static const defaultTitle = 'Yeni Bir Güncelleme Mevcut';
  static const defaultDescription =
      'Daha iyi bir deneyim ve yeni özellikler için lütfen uygulamanızı en son sürüme güncelleyin.';
  static const defaultButton = 'Güncelle';
  static const defaultCancel = 'Daha Sonra';

  Future<void> ensureReady() async {
    final rc = _remoteConfig;
    if (rc == null) return;
    if (_ready && !kDebugMode) {
      return;
    }

    try {
      await rc.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 10),
          minimumFetchInterval:
              kDebugMode ? Duration.zero : const Duration(hours: 1),
        ),
      );

      if (!_ready) {
        await rc.setDefaults(const {
          RemoteConfigKeys.androidLatestVersionCode: 1,
          RemoteConfigKeys.androidMinRequiredVersionCode: 1,
          RemoteConfigKeys.iosLatestVersionCode: 1,
          RemoteConfigKeys.iosMinRequiredVersionCode: 1,
          RemoteConfigKeys.maintenance: false,
          RemoteConfigKeys.title: defaultTitle,
          RemoteConfigKeys.description: defaultDescription,
          RemoteConfigKeys.button: defaultButton,
          RemoteConfigKeys.cancel: defaultCancel,
          RemoteConfigKeys.androidStoreUrl: defaultPlayStoreUrl,
          RemoteConfigKeys.iosStoreUrl: defaultAppStoreUrl,
        });
      }

      await rc.fetchAndActivate();
      _ready = true;
    } catch (error) {
      if (kDebugMode) {
        debugPrint('[update] Remote Config fetch hatası (varsayılanlar kullanılacak): $error');
      }
    }
  }

  @override
  Future<UpdateInfo?> getUpdateInfo({
    required UpdateType updateType,
    required UpdateUiContent uiContent,
  }) async {
    final rc = _remoteConfig;
    if (rc == null) return null;

    await ensureReady();

    final current = uiContent.versionCode;
    final localized = uiContent.localizedContentMap;
    final locale = localized['tr'] ??
        (localized.isEmpty ? null : localized.values.first);

    final isIos = !kIsWeb && Platform.isIOS;
    final latestKey = isIos
        ? RemoteConfigKeys.iosLatestVersionCode
        : RemoteConfigKeys.androidLatestVersionCode;
    final minKey = isIos
        ? RemoteConfigKeys.iosMinRequiredVersionCode
        : RemoteConfigKeys.androidMinRequiredVersionCode;

    final latest = _readInt(rc, latestKey);
    final minRequired = _readInt(rc, minKey);
    final maintenance = rc.getBool(RemoteConfigKeys.maintenance);

    if (kDebugMode) {
      debugPrint(
        '[update] Platform: ${isIos ? "iOS" : "Android"} | '
        'Mevcut Build: $current | En Son: $latest | Zorunlu Min: $minRequired | '
        'Bakım: $maintenance',
      );
    }

    final title = _nonEmpty(
      rc.getString(RemoteConfigKeys.title),
      locale?.updateTitle ?? defaultTitle,
    );
    final description = _nonEmpty(
      rc.getString(RemoteConfigKeys.description),
      locale?.updateDescription ?? defaultDescription,
    );
    final confirm = _nonEmpty(
      rc.getString(RemoteConfigKeys.button),
      locale?.updateButtonText ?? defaultButton,
    );
    final cancel = _nonEmpty(
      rc.getString(RemoteConfigKeys.cancel),
      locale?.cancelButtonText ?? defaultCancel,
    );

    final androidUrl = _optionalUrl(
      rc.getString(RemoteConfigKeys.androidStoreUrl),
      defaultPlayStoreUrl,
    );
    final iosUrl = _optionalUrl(
      rc.getString(RemoteConfigKeys.iosStoreUrl),
      defaultAppStoreUrl,
    );

    if (maintenance) {
      return UpdateInfo(
        latestVersionCode: latest,
        minRequiredVersionCode: minRequired,
        title: title,
        description: description,
        forceUpdate: true,
        isMaintenance: true,
        confirmButtonText: confirm,
        cancelButtonText: null,
        androidStoreUrl: androidUrl,
        iosStoreUrl: iosUrl,
      );
    }

    final needsForce = current < minRequired;
    final needsSoft = current < latest && !needsForce;

    final UpdateInfo? info;
    if (needsForce) {
      info = UpdateInfo(
        latestVersionCode: latest,
        minRequiredVersionCode: minRequired,
        title: title,
        description: description,
        forceUpdate: true,
        confirmButtonText: confirm,
        cancelButtonText: null,
        androidStoreUrl: androidUrl,
        iosStoreUrl: iosUrl,
      );
    } else if (needsSoft) {
      info = UpdateInfo(
        latestVersionCode: latest,
        minRequiredVersionCode: minRequired,
        title: title,
        description: description,
        forceUpdate: false,
        confirmButtonText: confirm,
        cancelButtonText: cancel,
        androidStoreUrl: androidUrl,
        iosStoreUrl: iosUrl,
      );
    } else {
      info = null;
    }

    if (info == null) {
      return null;
    }

    switch (updateType) {
      case UpdateType.force:
        return info.forceUpdate ? info : null;
      case UpdateType.soft:
        return info.forceUpdate ? null : info;
      case UpdateType.auto:
        return info;
    }
  }

  int _readInt(FirebaseRemoteConfig rc, String key) {
    try {
      final fromInt = rc.getInt(key);
      if (fromInt != 0) {
        return fromInt;
      }
      final parsed = int.tryParse(rc.getString(key).trim());
      if (parsed != null) {
        return parsed;
      }
      return fromInt;
    } catch (_) {
      return 0;
    }
  }

  static String _nonEmpty(String remote, String fallback) {
    final trimmed = remote.trim();
    return trimmed.isEmpty ? fallback : trimmed;
  }

  static String? _optionalUrl(String remote, String fallback) {
    final trimmed = remote.trim();
    if (trimmed.isNotEmpty) {
      return trimmed;
    }
    return fallback.isEmpty ? null : fallback;
  }
}
