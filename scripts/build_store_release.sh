#!/usr/bin/env bash
# Store-signed release builds for Google Play (AAB) and/or App Store (IPA).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

# Ensure Flutter is in PATH
export PATH="$PATH:$HOME/Documents/flutter/bin:/opt/homebrew/bin"

DO_ANDROID=0
DO_IOS=0
ALSO_APK=0
BUILD_NAME=""
BUILD_NUMBER=""
SKIP_CLEAN=0

usage() {
  echo "Usage: ./scripts/build_store_release.sh [--android|--ios|--all] [--build-name 1.0.4] [--build-number 4]"
  exit "${1:-0}"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --android) DO_ANDROID=1 ;;
    --ios) DO_IOS=1 ;;
    --all) DO_ANDROID=1; DO_IOS=1 ;;
    --apk) ALSO_APK=1 ;;
    --build-name) BUILD_NAME="${2:?}"; shift ;;
    --build-number) BUILD_NUMBER="${2:?}"; shift ;;
    --skip-clean) SKIP_CLEAN=1 ;;
    -h|--help) usage 0 ;;
    *) echo "Unknown option: $1" >&2; usage 1 ;;
  esac
  shift
done

# Default: Android only
if [[ "$DO_ANDROID" -eq 0 && "$DO_IOS" -eq 0 ]]; then
  DO_ANDROID=1
fi

VERSION_LINE="$(grep -E '^version:' pubspec.yaml | head -1 | awk '{print $2}')"
DEFAULT_NAME="${VERSION_LINE%%+*}"
DEFAULT_NUMBER="${VERSION_LINE##*+}"
NAME="${BUILD_NAME:-$DEFAULT_NAME}"
NUMBER="${BUILD_NUMBER:-$DEFAULT_NUMBER}"
STAMP="$(date +%Y%m%d-%H%M%S)"
OUT_DIR="$ROOT/build/store/${NAME}+${NUMBER}_${STAMP}"
DEBUG_INFO="$ROOT/build/debug-info/${NAME}+${NUMBER}_${STAMP}"

VERSION_FLAGS=(--build-name="$NAME" --build-number="$NUMBER")
OBFUSCATE_FLAGS=(--obfuscate --split-debug-info="$DEBUG_INFO")

log() { printf '\n==> %s\n' "$*"; }
die() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || die "'$1' not found in PATH"
}

check_android_signing() {
  local props="$ROOT/android/key.properties"
  [[ -f "$props" ]] || die "Missing android/key.properties"

  local store_file key_alias
  store_file="$(grep -E '^storeFile=' "$props" | head -1 | cut -d= -f2-)"
  key_alias="$(grep -E '^keyAlias=' "$props" | head -1 | cut -d= -f2-)"
  [[ -n "$store_file" ]] || die "key.properties: storeFile is empty"
  [[ -n "$key_alias" ]] || die "key.properties: keyAlias is empty"

  if [[ "$store_file" != /* ]]; then
    store_file="$(cd "$ROOT/android/app" && cd "$(dirname "$store_file")" && pwd)/$(basename "$store_file")"
  fi
  [[ -f "$store_file" ]] || die "Keystore not found: $store_file"

  echo "  keystore: $store_file"
  echo "  alias:    $key_alias"
}

verify_aab_signed() {
  local aab="$1"
  if command -v jarsigner >/dev/null 2>&1; then
    jarsigner -verify -verbose -certs "$aab" >/dev/null 2>&1 \
      || die "AAB signature verification failed: $aab"
    echo "  jarsigner: OK"
  else
    echo "  jarsigner: skipped (not installed)"
  fi
}

build_android() {
  log "Android store AAB ($NAME+$NUMBER)"
  check_android_signing
  need_cmd flutter

  mkdir -p "$OUT_DIR" "$DEBUG_INFO"

  flutter build appbundle --release \
    "${VERSION_FLAGS[@]}" \
    "${OBFUSCATE_FLAGS[@]}"

  local src="$ROOT/build/app/outputs/bundle/release/app-release.aab"
  [[ -f "$src" ]] || die "AAB missing at $src"

  local dest="$OUT_DIR/lifesimulation-${NAME}+${NUMBER}.aab"
  cp "$src" "$dest"
  verify_aab_signed "$dest"

  echo "  AAB → $dest"
  ls -lh "$dest"

  if [[ "$ALSO_APK" -eq 1 ]]; then
    log "Android release APK (optional)"
    flutter build apk --release \
      "${VERSION_FLAGS[@]}" \
      "${OBFUSCATE_FLAGS[@]}"
    local apk_src="$ROOT/build/app/outputs/flutter-apk/app-release.apk"
    [[ -f "$apk_src" ]] || die "APK missing at $apk_src"
    local apk_dest="$OUT_DIR/lifesimulation-${NAME}+${NUMBER}.apk"
    cp "$apk_src" "$apk_dest"
    echo "  APK → $apk_dest"
    ls -lh "$apk_dest"
  fi
}

build_ios() {
  log "iOS App Store IPA ($NAME+$NUMBER)"
  [[ "$(uname -s)" == "Darwin" ]] || die "iOS builds require macOS."
  need_cmd flutter
  [[ -f "$ROOT/ios/ExportOptions.plist" ]] || die "Missing ios/ExportOptions.plist"

  mkdir -p "$OUT_DIR" "$DEBUG_INFO"

  flutter build ipa --release \
    "${VERSION_FLAGS[@]}" \
    "${OBFUSCATE_FLAGS[@]}" \
    --export-options-plist=ios/ExportOptions.plist

  local src
  src="$(find "$ROOT/build/ios/ipa" -name '*.ipa' -type f 2>/dev/null | head -1 || true)"
  [[ -n "$src" && -f "$src" ]] || die "IPA not found under build/ios/ipa"

  local dest="$OUT_DIR/lifesimulation-${NAME}+${NUMBER}.ipa"
  cp "$src" "$dest"
  echo "  IPA → $dest"
  ls -lh "$dest"
}

need_cmd flutter
log "Flutter $(flutter --version 2>/dev/null | head -1)"
echo "  version: $NAME+$NUMBER"
echo "  out:     $OUT_DIR"

if [[ "$SKIP_CLEAN" -eq 0 ]]; then
  log "flutter pub get"
  flutter pub get
fi

mkdir -p "$OUT_DIR"

SUMMARY=()
if [[ "$DO_ANDROID" -eq 1 ]]; then
  build_android
  SUMMARY+=("AAB: $OUT_DIR/lifesimulation-${NAME}+${NUMBER}.aab")
fi
if [[ "$DO_IOS" -eq 1 ]]; then
  build_ios
  SUMMARY+=("IPA: $OUT_DIR/lifesimulation-${NAME}+${NUMBER}.ipa")
fi

log "Build complete"
echo "  debug symbols: $DEBUG_INFO"
for line in "${SUMMARY[@]}"; do
  echo "  $line"
done
