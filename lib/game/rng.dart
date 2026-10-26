import 'state.dart';

/// Oyundaki TEK rastgelelik kaynağı. Godot'nun RandomNumberGenerator'ı gibi PCG32;
/// her çağrıdan sonra durumu GameState'e yazar, böylece kayıttan yüklenen oyun aynı
/// diziyle devam eder ve aynı seed ile birebir tekrar oynatılabilir. (Godot: Core/GameRandom.cs)
///
/// Dart int'i 64 bit işaretli ve taşmada sarar; >>> mantıksal kaydırma. Yalnızca native hedefler.
class GameRandom {
  GameRandom(this._state) {
    if (_state.rngState != 0) {
      _pcg = _state.rngState;
    } else {
      // pcg32_srandom_r(seed, inc)
      _pcg = 0;
      _next();
      _pcg += _state.rngSeed;
      _next();
    }
    _capture();
  }

  static const _mult = 6364136223846793005;
  static const _inc = (1442695040888963407 << 1) | 1;

  final GameState _state;
  late int _pcg;

  int _next() {
    final old = _pcg;
    _pcg = old * _mult + _inc;
    final xorshifted = (((old >>> 18) ^ old) >>> 27) & 0xFFFFFFFF;
    final rot = old >>> 59;
    return ((xorshifted >>> rot) | (xorshifted << ((-rot) & 31))) & 0xFFFFFFFF;
  }

  int _bounded(int bound) {
    final threshold = (0x100000000 - bound) % bound;
    while (true) {
      final r = _next();
      if (r >= threshold) return r % bound;
    }
  }

  /// [min, max] kapalı aralık.
  int rangeInt(int min, int max) {
    if (min > max) (min, max) = (max, min);
    final v = _bounded(max - min + 1) + min;
    _capture();
    return v;
  }

  /// [0, 1) aralığında.
  double nextDouble() {
    final v = _next() / 4294967296.0;
    _capture();
    return v;
  }

  void _capture() => _state.rngState = _pcg;
}

/// SplitMix64: oyunun RNG dizisini tüketmeden seed'den türetilen seçimler (aile zarı, isimler).
int splitMix(int x) {
  x += 0x9E3779B97F4A7C15;
  x = (x ^ (x >>> 30)) * 0xBF58476D1CE4E5B9;
  x = (x ^ (x >>> 27)) * 0x94D049BB133111EB;
  return x ^ (x >>> 31);
}

/// İşaretsiz 64 bit mod (C#'taki `ulong % count`).
int unsignedMod(int x, int count) {
  if (x >= 0) return x % count;
  // x = 2^64 + x (işaretsiz). (hi * 2^32 + lo) mod count, taşmadan.
  final hi = x >>> 32, lo = x & 0xFFFFFFFF;
  return ((hi % count) * (0x100000000 % count) % count + lo % count) % count;
}
