#!/usr/bin/env bash
# Play için imzalı AAB üretir; çıktı adı + sürümle dist/android/ altına kopyalar.
#
# Kullanım (proje kökünden):
#   ./tools/build_android_release.sh
#   ./tools/build_android_release.sh --apk          # ek olarak APK
#   BUILD_NAME=1.0.1 BUILD_NUMBER=2 ./tools/build_android_release.sh
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

APP_SLUG="${APP_SLUG:-HayatSimulasyonu}"
BUILD_NAME="${BUILD_NAME:-}"
BUILD_NUMBER="${BUILD_NUMBER:-}"
ALSO_APK=0
for arg in "$@"; do
  case "$arg" in
    --apk) ALSO_APK=1 ;;
    -h|--help)
      sed -n '2,10p' "$0"
      exit 0
      ;;
  esac
done

if [[ ! -f android/key.properties ]]; then
  echo "android/key.properties yok. Önce: STORE_PASS=... KEY_PASS=... ./android/create_keystore.sh"
  exit 1
fi
if [[ ! -f android/keystore/life_simulation.jks ]]; then
  echo "android/keystore/life_simulation.jks yok."
  exit 1
fi

if [[ -z "$BUILD_NAME" || -z "$BUILD_NUMBER" ]]; then
  ver_line="$(grep -E '^version:' pubspec.yaml | head -1 | awk '{print $2}')"
  BUILD_NAME="${BUILD_NAME:-${ver_line%%+*}}"
  BUILD_NUMBER="${BUILD_NUMBER:-${ver_line##*+}}"
fi

OUT_DIR="$ROOT/dist/android"
SYMBOLS_DIR="$ROOT/build/symbols/${APP_SLUG}-${BUILD_NAME}+${BUILD_NUMBER}"
mkdir -p "$OUT_DIR" "$SYMBOLS_DIR"

echo "==> AAB: $APP_SLUG $BUILD_NAME ($BUILD_NUMBER) [AdMob canlı]"
flutter build appbundle --release \
  --build-name="$BUILD_NAME" \
  --build-number="$BUILD_NUMBER" \
  --dart-define=AD_TEST_MODE=false \
  --obfuscate \
  --split-debug-info="$SYMBOLS_DIR"

AAB_SRC="build/app/outputs/bundle/release/app-release.aab"
AAB_DST="$OUT_DIR/${APP_SLUG}-${BUILD_NAME}+${BUILD_NUMBER}.aab"
cp "$AAB_SRC" "$AAB_DST"
echo "AAB → $AAB_DST"

if [[ "$ALSO_APK" -eq 1 ]]; then
  echo "==> APK (aynı imza / sürüm)"
  flutter build apk --release \
    --build-name="$BUILD_NAME" \
    --build-number="$BUILD_NUMBER" \
    --dart-define=AD_TEST_MODE=false \
    --obfuscate \
    --split-debug-info="$SYMBOLS_DIR"
  APK_SRC="build/app/outputs/flutter-apk/app-release.apk"
  APK_DST="$OUT_DIR/${APP_SLUG}-${BUILD_NAME}+${BUILD_NUMBER}.apk"
  cp "$APK_SRC" "$APK_DST"
  echo "APK → $APK_DST"
fi

echo "Semboller → $SYMBOLS_DIR"
ls -lh "$AAB_DST" ${APK_DST:-} 2>/dev/null || true
echo "Play'e yükle: $AAB_DST"
