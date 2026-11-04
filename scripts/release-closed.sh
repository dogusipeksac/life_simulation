#!/usr/bin/env bash
# Google Play Kapalı Test (Alpha) sürüm çıkışı.
# Kullanım:
#   ./scripts/release-closed.sh 1.0.4
#   ./scripts/release-closed.sh 1.0.4 4
#   ./scripts/release-closed.sh 1.0.4 --build 4
#   ./scripts/release-closed.sh 1.0.4 --skip-checks
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
exec "$ROOT/scripts/release.sh" --android --track alpha "$@"
