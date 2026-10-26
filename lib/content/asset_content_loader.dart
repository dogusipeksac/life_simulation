import 'package:flutter/services.dart';

import 'game_content.dart';

const contentRoot = 'assets/content/';

/// Uygulama içi yükleyici: paketlenmiş JSON'ları rootBundle ile okur.
Future<GameContent> loadBundledContent([AssetBundle? bundle]) async {
  final b = bundle ?? rootBundle;
  final manifest = await AssetManifest.loadFromAssetBundle(b);
  final paths = manifest.listAssets().where((p) => p.startsWith(contentRoot)).map((p) => p.substring(contentRoot.length));
  return GameContent.load(paths, (p) => b.loadString('$contentRoot$p', cache: false));
}
