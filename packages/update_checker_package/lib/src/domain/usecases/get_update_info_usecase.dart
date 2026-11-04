import '../models/update_info.dart';
import '../models/update_ui_content.dart';
import '../repositories/update_info_provider.dart';
import '../../utils/update_type.dart';

class GetUpdateInfoUseCase {
  final UpdateInfoProvider updateInfoProvider;

  GetUpdateInfoUseCase(this.updateInfoProvider);

  Future<UpdateInfo?> call({
    required UpdateType updateType,
    required UpdateUiContent uiContent,
  }) async {
    return await updateInfoProvider.getUpdateInfo(
      updateType: updateType,
      uiContent: uiContent,
    );
  }
}
