#!/usr/bin/env bash
# Tek komutla mağaza yayını (YDSKelimeKitApp mimarisi):
# sürümü artırır, kontrolleri çalıştırır, AAB/IPA derler,
# Google Play veya App Store'a yükler, release/history.json ve notları kaydeder.
#
# Kullanım:
#   ./scripts/release.sh 1.0.4               # Android (alpha) + iOS (upload)
#   ./scripts/release.sh 1.0.4 --android     # Yalnızca Android
#   ./scripts/release.sh 1.0.4 --ios         # Yalnızca iOS App Store
#   ./scripts/release.sh 1.0.4 --testflight  # Yalnızca TestFlight
#   ./scripts/release.sh 1.0.4 --track alpha # Kapalı test (alpha) - varsayılan
#   ./scripts/release.sh 1.0.4 --track production # Üretim / Canlı
#   ./scripts/release.sh 1.0.4 --track internal   # Dahili test
#   ./scripts/release.sh 1.0.4 --dry-run     # Derler ve doğrular, mağazaya yüklemez
#
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

export PATH="$PATH:$HOME/Documents/flutter/bin:/opt/homebrew/bin"
export LANG="en_US.UTF-8"
export LC_ALL="en_US.UTF-8"

ENV_FILE="${LIFE_SIM_ENV:-$HOME/.config/life-simulation/release.env}"
HISTORY_FILE="$ROOT/release/history.json"

log() { printf '\n==> %s\n' "$*"; }
die() { printf 'HATA: %s\n' "$*" >&2; exit 1; }

VERSION=""
TRACK=""
TESTFLIGHT=0
DO_ANDROID=1
DO_IOS=1
DRY_RUN=0
SKIP_CHECKS=0
STATUS="completed"
BUILD_ARG=""

while [[ $# -gt 0 ]]; do
  arg="$1"
  case "$arg" in
    --track) TRACK="${2:?--track internal|alpha|beta|production bekler}"; shift ;;
    --android) DO_IOS=0 ;;
    --ios) DO_ANDROID=0 ;;
    --testflight) TESTFLIGHT=1 ;;
    --build) BUILD_ARG="${2:?--build bir tam sayı bekler}"; shift ;;
    --draft) STATUS="draft" ;;
    --skip-checks) SKIP_CHECKS=1 ;;
    --dry-run) DRY_RUN=1 ;;
    -h|--help)
      sed -n '2,15p' "$0" | sed 's/^# \{0,1\}//'
      exit 0
      ;;
    [0-9]*.[0-9]*.[0-9]*) VERSION="$arg" ;;
    [0-9]*)
      if [[ -n "$VERSION" && -z "$BUILD_ARG" ]]; then
        BUILD_ARG="$arg"
      else
        die "Bilinmeyen sayısal argüman: $arg"
      fi
      ;;
    *) die "Bilinmeyen argüman: $arg" ;;
  esac
  shift
done

[[ -n "$VERSION" ]] || die "Kullanım: ./scripts/release.sh <x.y.z> [build] [--android|--ios|--testflight] [--track alpha|production] [--build <sayı>] [--dry-run]"

# —— Sürüm ve Build Numarası Hesaplama (YDS Algoritması) ——
CURRENT="$(grep -E '^version:' pubspec.yaml | head -1 | awk '{print $2}')"
CURRENT_NAME="${CURRENT%%+*}"
CURRENT_NUMBER="${CURRENT##*+}"

if [[ -n "$BUILD_ARG" ]]; then
  BUILD="$BUILD_ARG"
elif [[ "$CURRENT_NAME" == "$VERSION" ]]; then
  BUILD="$CURRENT_NUMBER"
else
  BUILD=$((CURRENT_NUMBER + 1))
fi

NOTES_DIR="release_notes/$VERSION"
ANDROID_NOTES="$NOTES_DIR/android.txt"
IOS_NOTES="$NOTES_DIR/ios.txt"

# Notlar yoksa otomatik oluştur veya önceki sürümden aktar
if [[ ! -d "$NOTES_DIR" ]]; then
  mkdir -p "$NOTES_DIR"
fi
if [[ ! -f "$ANDROID_NOTES" ]]; then
  PREV_ANDROID="$(ls -dt release_notes/*/android.txt 2>/dev/null | head -1 || true)"
  if [[ -n "$PREV_ANDROID" && -f "$PREV_ANDROID" ]]; then
    cp "$PREV_ANDROID" "$ANDROID_NOTES"
  else
    echo "Hayat Simülasyonu sürüm $VERSION ($BUILD) güncellemeleri ve hata düzeltmeleri." > "$ANDROID_NOTES"
  fi
fi
if [[ ! -f "$IOS_NOTES" ]]; then
  PREV_IOS="$(ls -dt release_notes/*/ios.txt 2>/dev/null | head -1 || true)"
  if [[ -n "$PREV_IOS" && -f "$PREV_IOS" ]]; then
    cp "$PREV_IOS" "$IOS_NOTES"
  else
    echo "Hayat Simülasyonu sürüm $VERSION ($BUILD) güncellemeleri ve hata düzeltmeleri." > "$IOS_NOTES"
  fi
fi

log "Sürüm: $VERSION (Build: $BUILD) | Android: $DO_ANDROID | iOS: $DO_IOS | TestFlight: $TESTFLIGHT | Dry-run: $DRY_RUN"

# —— Ön Kontroller ——
if [[ "$DO_ANDROID" -eq 1 ]]; then
  [[ -s "$ANDROID_NOTES" ]] || die "Sürüm notu boş: $ANDROID_NOTES"
  chars=$(python3 -c 'import sys; print(len(open(sys.argv[1], encoding="utf-8").read().strip()))' "$ANDROID_NOTES")
  (( chars <= 500 )) || die "Android notu $chars karakter; Google Play sınırı 500."
fi

if [[ "$DO_IOS" -eq 1 ]]; then
  [[ "$(uname -s)" == "Darwin" ]] || die "iOS release macOS gerektirir."
  [[ -s "$IOS_NOTES" ]] || die "Sürüm notu boş: $IOS_NOTES"
  chars=$(python3 -c 'import sys; print(len(open(sys.argv[1], encoding="utf-8").read().strip()))' "$IOS_NOTES")
  (( chars <= 4000 )) || die "iOS notu $chars karakter; App Store sınırı 4000."
fi

command -v fastlane >/dev/null 2>&1 || die "fastlane bulunamadı (brew install fastlane)"

if [[ -f "$ENV_FILE" ]]; then
  set -a
  source "$ENV_FILE"
  set +a
elif [[ "$DRY_RUN" -eq 0 ]]; then
  die "Ayar dosyası eksik: $ENV_FILE"
fi

TRACK="${TRACK:-${PLAY_TRACK:-alpha}}"
case "$TRACK" in
  internal|alpha|beta|production) ;;
  *) die "Geçersiz Play kanalı: $TRACK (internal|alpha|beta|production)" ;;
esac

[[ "$DO_ANDROID" -eq 1 ]] && echo "  Google Play Kanalı: $TRACK (Durum: $STATUS)"

# —— pubspec.yaml Sürüm Güncelleme ——
log "pubspec.yaml güncelleniyor -> version: $VERSION+$BUILD"
sed -i '' -E "s/^version: .*/version: $VERSION+$BUILD/" pubspec.yaml

# —— Kalite Kontrolleri ——
if [[ "$SKIP_CHECKS" -eq 0 ]]; then
  log "Kalite kontrolleri çalıştırılıyor (flutter analyze & flutter test)..."
  flutter analyze --no-fatal-infos
  flutter test
fi

# —— Derleme (scripts/build_store_release.sh) ——
BUILD_FLAGS=()
[[ "$DO_ANDROID" -eq 1 ]] && BUILD_FLAGS+=(--android)
[[ "$DO_IOS" -eq 1 ]] && BUILD_FLAGS+=(--ios)

./scripts/build_store_release.sh "${BUILD_FLAGS[@]}" --build-name "$VERSION" --build-number "$BUILD" --skip-clean

OUT_DIR="$(ls -dt build/store/"$VERSION+$BUILD"_* | head -1)"
AAB="$OUT_DIR/lifesimulation-$VERSION+$BUILD.aab"
IPA="$OUT_DIR/lifesimulation-$VERSION+$BUILD.ipa"

# —— Yükleme & Dağıtım ——
record_history() {
  local p="$1" t="$2" s="$3" n="$4"
  python3 - "$HISTORY_FILE" "$VERSION" "$BUILD" "$p" "$t" "$s" "$n" <<'PY'
import json, sys, os, subprocess
hist_file, version, build, platform, track, status, notes_path = sys.argv[1], sys.argv[2], int(sys.argv[3]), sys.argv[4], sys.argv[5], sys.argv[6], sys.argv[7]
notes_text = open(notes_path, encoding="utf-8").read().strip() if os.path.exists(notes_path) else ""
data = {"android": [], "ios": []}
if os.path.exists(hist_file):
    try:
        content = json.loads(open(hist_file, encoding="utf-8").read())
        if isinstance(content, dict):
            if "android" in content or "ios" in content:
                data["android"] = content.get("android", [])
                data["ios"] = content.get("ios", [])
    except Exception:
        pass
data[platform].append({
    "version": version,
    "build": build,
    "target": track,
    "status": status,
    "uploaded_at": subprocess.check_output(["date", "-u", "+%Y-%m-%dT%H:%M:%SZ"]).decode().strip(),
    "notes": notes_text
})
with open(hist_file, "w", encoding="utf-8") as f:
    json.dump(data, f, indent=2, ensure_ascii=False)
    f.write("\n")
PY
  echo "  release/history.json güncellendi ($p -> $t, sürüm $VERSION ($BUILD))."
}

if [[ "$DO_ANDROID" -eq 1 ]]; then
  log "Google Play Yüklemesi ($TRACK)..."
  CHANGELOG="fastlane/metadata/android/tr-TR/changelogs/$BUILD.txt"
  mkdir -p "$(dirname "$CHANGELOG")"
  cp "$ANDROID_NOTES" "$CHANGELOG"

  if [[ "$DRY_RUN" -eq 1 ]]; then
    echo "  [Dry-run] Google Play doğrulaması yapılıyor..."
    fastlane android release aab:"$AAB" track:"$TRACK" status:"$STATUS" validate_only:true
  else
    fastlane android release aab:"$AAB" track:"$TRACK" status:"$STATUS"
    record_history "android" "$TRACK" "$STATUS" "$ANDROID_NOTES"
  fi
fi

if [[ "$DO_IOS" -eq 1 ]]; then
  if [[ "$DRY_RUN" -eq 1 ]]; then
    echo "  [Dry-run] iOS yüklemesi atlandı."
  elif [[ "$TESTFLIGHT" -eq 1 ]]; then
    log "TestFlight Yüklemesi..."
    fastlane ios beta ipa:"$IPA" notes:"$ROOT/$IOS_NOTES"
    record_history "ios" "testflight" "completed" "$IOS_NOTES"
  else
    log "App Store Connect Yüklemesi..."
    fastlane ios release ipa:"$IPA" version:"$VERSION" notes:"$ROOT/$IOS_NOTES"
    record_history "ios" "appstore" "uploaded" "$IOS_NOTES"
  fi
fi

if [[ "$DRY_RUN" -eq 1 ]]; then
  log "Dry-run tamamlandı. Paket $OUT_DIR klasöründe hazır."
  exit 0
fi

# —— Git Kaydı (Commit & Tag) ——
git add pubspec.yaml fastlane/metadata release_notes "$HISTORY_FILE"
git diff --cached --quiet || git commit -m "Release $VERSION ($BUILD)"
git rev-parse -q --verify "refs/tags/v$VERSION" >/dev/null || git tag "v$VERSION"

log "Tamamlandı!"
[[ "$DO_ANDROID" -eq 1 ]] && echo "  Google Play ($TRACK): Sürüm $VERSION ($BUILD) yüklendi."
[[ "$DO_IOS" -eq 1 && "$TESTFLIGHT" -eq 1 ]] && echo "  TestFlight: Sürüm $VERSION ($BUILD) yüklendi."
[[ "$DO_IOS" -eq 1 && "$TESTFLIGHT" -eq 0 ]] && echo "  App Store: Sürüm $VERSION ($BUILD) yüklendi."
echo "  Yerel commit ve v$VERSION etiketi oluşturuldu."
