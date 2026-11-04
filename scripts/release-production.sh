#!/usr/bin/env bash
# Google Play Production (Üretim / Canlı) sürüm çıkışı.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
exec "$ROOT/scripts/release-prod.sh" "$@"
