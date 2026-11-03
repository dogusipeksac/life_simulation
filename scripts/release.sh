#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export LANG="en_US.UTF-8"
export LC_ALL="en_US.UTF-8"

exec python3 "$ROOT/release/automation.py" "$@"
