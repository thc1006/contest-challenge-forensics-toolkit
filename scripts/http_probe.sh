#!/usr/bin/env bash
# Usage: http_probe.sh URL CASE_SLUG
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/common.sh
source "$SCRIPT_DIR/common.sh"

TARGET_URL="${1:?URL required}"
CASE_SLUG="${2:?CASE_SLUG}"
export CASE_SLUG
OUT="outputs/${CASE_SLUG}/http_probe.txt"
mkdir -p "outputs/${CASE_SLUG}"

log "HTTP HEAD: $TARGET_URL"
{
  date -u +"== Probe UTC: %Y-%m-%dT%H:%M:%SZ =="
  curl -I -sS --max-time 10 "$TARGET_URL"
} | tee "$OUT" >/dev/null
