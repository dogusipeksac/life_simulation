class LocalizedUpdateContent {
  final String updateTitle;
  final String updateDescription;
  final String updateButtonText;
  final String? cancelButtonText;

  LocalizedUpdateContent({
    required this.updateTitle,
    required this.updateDescription,
    required this.updateButtonText,
    this.cancelButtonText,
  });
}

class UpdateUiContent {
  final int versionCode;
  final Map<String, LocalizedUpdateContent> localizedContentMap;

  UpdateUiContent({
    required this.versionCode,
    required this.localizedContentMap,
  });
}
