// Godot AtomicFile: yarıda kesilen yazımdan sonra asıl → .tmp → .bak.
import 'dart:io';

import 'local_crypto.dart';

class AtomicTextFile {
  AtomicTextFile(this.path);
  final String path;
  String _extension(String ext) {
    final dot = path.lastIndexOf('.');
    final slash = path.lastIndexOf(Platform.pathSeparator);
    return (dot > slash ? path.substring(0, dot) : path) + ext;
  }

  List<String> get readOrder => [path, _extension('.tmp'), _extension('.bak')];
  String? read(String file) {
    try {
      return LocalCrypto.open(File(file).readAsStringSync());
    } on FileSystemException {
      return null;
    } on FormatException {
      return null;
    }
  }

  bool write(String text) {
    try {
      final temp = File(readOrder[1]);
      temp.parent.createSync(recursive: true);
      temp.writeAsStringSync(LocalCrypto.seal(text), flush: true);
      final main = File(path);
      if (main.existsSync()) {
        final backup = File(readOrder[2]);
        if (backup.existsSync()) backup.deleteSync();
        main.renameSync(backup.path);
      }
      temp.renameSync(path);
      return true;
    } on FileSystemException {
      return false;
    }
  }
}
