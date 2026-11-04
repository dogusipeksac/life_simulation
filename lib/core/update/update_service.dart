import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:update_checker_package/update_checker_package.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:life_simulation/core/update/remote_config_update_info_provider.dart';

/// Uygulama içi güncelleme kontrolü ve diyalog yönetimi servisi.
class UpdateService {
  UpdateService._();
  static final instance = UpdateService._();

  final _provider = RemoteConfigUpdateInfoProvider();
  late final _useCase = GetUpdateInfoUseCase(_provider);
  bool _dialogShowing = false;

  /// Güncelleme kontrolü yapar; güncelleme gerekiyorsa [UpdateInfo] döner, yoksa null.
  Future<UpdateInfo?> checkUpdate() async {
    // Firebase başlatılmamışsa (örn. testlerde) güncelleme kontrolünü atla
    if (Firebase.apps.isEmpty) {
      return null;
    }
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final versionCode = int.tryParse(packageInfo.buildNumber) ?? 0;

      final info = await _useCase(
        updateType: UpdateType.auto,
        uiContent: UpdateUiContent(
          versionCode: versionCode,
          localizedContentMap: {
            'tr': LocalizedUpdateContent(
              updateTitle: RemoteConfigUpdateInfoProvider.defaultTitle,
              updateDescription:
                  RemoteConfigUpdateInfoProvider.defaultDescription,
              updateButtonText: RemoteConfigUpdateInfoProvider.defaultButton,
              cancelButtonText: RemoteConfigUpdateInfoProvider.defaultCancel,
            ),
          },
        ),
      );

      if (kDebugMode) {
        debugPrint(
          '[update] Kontrol yapıldı. Build: $versionCode '
          '→ ${info == null ? "Güncel" : (info.forceUpdate ? "Force Update" : "Soft Update")}',
        );
      }

      return info;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[update] Güncelleme kontrolünde hata: $e');
      }
      return null;
    }
  }

  /// Güncelleme varsa kullanıcıya uygun diyaloğu / bakım ekranını gösterir.
  Future<void> checkAndShowUpdate(BuildContext context) async {
    if (_dialogShowing) return;

    final info = await checkUpdate();
    if (info == null || !context.mounted) return;

    _dialogShowing = true;

    if (info.isMaintenance) {
      await Navigator.of(context, rootNavigator: true).push(
        PageRouteBuilder<void>(
          opaque: true,
          barrierDismissible: false,
          pageBuilder: (context, animation, secondaryAnimation) =>
              MaintenanceScreen(updateInfo: info),
        ),
      );
      _dialogShowing = false;
      return;
    }

    UpdateBottomSheetDialog.show(
      context,
      updateInfo: info,
      isForce: info.forceUpdate,
      onUpdateClick: () => _openStore(info),
      onDismiss: () {
        if (!info.forceUpdate) {
          _dialogShowing = false;
          Navigator.of(context, rootNavigator: true).pop();
        }
      },
    );
  }

  Future<void> _openStore(UpdateInfo info) async {
    final rawUrl = (!kIsWeb && Platform.isIOS)
        ? (info.iosStoreUrl ?? RemoteConfigUpdateInfoProvider.defaultAppStoreUrl)
        : (info.androidStoreUrl ??
            RemoteConfigUpdateInfoProvider.defaultPlayStoreUrl);

    final uri = Uri.tryParse(rawUrl);
    if (uri != null) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
