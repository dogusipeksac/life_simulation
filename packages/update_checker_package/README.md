# Update Checker Package

Flutter paketi: uygulama güncellemelerini kontrol eder ve güncelleme diyaloğunu gösterir.

Güncelleme verisi Firebase Realtime Database üzerinden değil; uygulamanızın sağladığı bir [UpdateInfoProvider] (ör. Firebase Remote Config) üzerinden okunur.

## Features

- Zorunlu ve isteğe bağlı güncelleme desteği
- Yerelleştirilmiş güncelleme metinleri
- Clean architecture (Domain, Presentation)
- GetX state management

## Installation

```yaml
dependencies:
  update_checker_package:
    path: packages/update_checker_package
```

## Usage

### 1. Implement [UpdateInfoProvider]

```dart
class RemoteConfigUpdateInfoProvider implements UpdateInfoProvider {
  @override
  Future<UpdateInfo?> getUpdateInfo({
    required UpdateType updateType,
    required UpdateUiContent uiContent,
  }) async {
    // Remote Config veya başka bir kaynaktan UpdateInfo döndürün
    return null;
  }
}
```

### 2. Check for updates

```dart
import 'package:update_checker_package/update_checker_package.dart';
import 'package:get/get.dart';

final getUpdateInfoUseCase = GetUpdateInfoUseCase(RemoteConfigUpdateInfoProvider());

final controller = Get.put(UpdateCheckerController(
  getUpdateInfoUseCase: getUpdateInfoUseCase,
));

final uiContent = UpdateUiContent(
  versionCode: 20,
  localizedContentMap: {
    'en': LocalizedUpdateContent(
      updateTitle: 'Update Available',
      updateDescription: 'A new version is available. Please update to continue.',
      updateButtonText: 'Update Now',
      cancelButtonText: 'Later',
    ),
  },
);

await controller.checkForUpdate(
  updateType: UpdateType.auto,
  uiContent: uiContent,
  onNoUpdateNeeded: () {},
);

if (controller.updateInfo.value != null) {
  UpdateBottomSheetDialog.show(
    context,
    updateInfo: controller.updateInfo.value!,
    isForce: controller.isForceUpdate.value,
    onUpdateClick: () {},
    onDismiss: () => Navigator.pop(context),
  );
}
```

## daily-hydrate

Ana uygulama güncellemeleri `lib/services/remote_config_update_info_provider.dart` ve Firebase Remote Config parametreleri ile yönetir.
