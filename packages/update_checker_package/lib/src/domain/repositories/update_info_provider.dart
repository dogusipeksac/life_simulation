import '../models/update_info.dart';
import '../models/update_ui_content.dart';
import '../../utils/update_type.dart';

abstract class UpdateInfoProvider {
  Future<UpdateInfo?> getUpdateInfo({
    required UpdateType updateType,
    required UpdateUiContent uiContent,
  });
}
