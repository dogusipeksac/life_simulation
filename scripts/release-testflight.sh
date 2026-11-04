#!/usr/bin/env bash
# iOS TestFlight sürüm çıkışı.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
exec "$ROOT/scripts/release-tf.sh" "$@"
