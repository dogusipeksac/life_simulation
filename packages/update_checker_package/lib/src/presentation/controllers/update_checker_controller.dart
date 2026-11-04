import 'package:get/get.dart';
import '../../domain/models/update_info.dart';
import '../../domain/models/update_ui_content.dart';
import '../../domain/usecases/get_update_info_usecase.dart';
import '../../utils/update_type.dart';

class UpdateCheckerController extends GetxController {
  UpdateCheckerController({
    required this.getUpdateInfoUseCase,
  });

  final GetUpdateInfoUseCase getUpdateInfoUseCase;

  final Rx<UpdateInfo?> updateInfo = Rx<UpdateInfo?>(null);
  final RxBool isForceUpdate = false.obs;
  final RxBool isChecking = false.obs;
  final RxString updateError = ''.obs;

  Future<void> checkForUpdate({
    required UpdateType updateType,
    required UpdateUiContent uiContent,
    required Function() onNoUpdateNeeded,
  }) async {
    isChecking.value = true;
    updateError.value = '';

    try {
      final result = await getUpdateInfoUseCase(
        updateType: updateType,
        uiContent: uiContent,
      );

      if (result == null) {
        onNoUpdateNeeded();
      } else {
        updateInfo.value = result;
        isForceUpdate.value = result.forceUpdate;
      }
    } catch (e) {
      updateError.value = e.toString();
    } finally {
      isChecking.value = false;
    }
  }

  void clearUpdateInfo() {
    updateInfo.value = null;
    isForceUpdate.value = false;
    updateError.value = '';
  }
}
