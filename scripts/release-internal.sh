#!/usr/bin/env bash
# Google Play Internal (Dahili Test) sürüm çıkışı.
# Kullanım:
#   ./scripts/release-internal.sh 1.0.4
#   ./scripts/release-internal.sh 1.0.4 4
#   ./scripts/release-internal.sh 1.0.4 --build 4
#   ./scripts/release-internal.sh 1.0.4 --skip-checks
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
exec "$ROOT/scripts/release.sh" --android --track internal "$@"
