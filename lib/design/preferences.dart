import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class VitaPreferences extends ChangeNotifier {
  SharedPreferences? _store;
  int readingSize = 38;
  bool dark = true, motion = true, sound = true, haptics = true;
  Future<void> load() async {
    _store = await SharedPreferences.getInstance();
    readingSize = (_store!.getInt('readingSize') ?? 38).clamp(32, 50);
    dark = _store!.getBool('dark') ?? true;
    motion = _store!.getBool('motion') ?? true;
    sound = _store!.getBool('sound') ?? true;
    haptics = _store!.getBool('haptics') ?? true;
    notifyListeners();
  }

  Future<void> set(String key, bool value) async {
    switch (key) {
      case 'dark':
        dark = value;
      case 'motion':
        motion = value;
      case 'sound':
        sound = value;
      case 'haptics':
        haptics = value;
      default:
        return;
    }
    notifyListeners();
    await _store?.setBool(key, value);
  }

  Future<void> setReadingSize(int value) async {
    readingSize = value.clamp(32, 50);
    notifyListeners();
    await _store?.setInt('readingSize', readingSize);
  }

  void feedback({bool strong = false}) {
    if (haptics) {
      if (strong) {
        HapticFeedback.mediumImpact();
      } else {
        HapticFeedback.selectionClick();
      }
    }
    if (sound) SystemSound.play(SystemSoundType.click);
  }
}

final preferences = VitaPreferences();
