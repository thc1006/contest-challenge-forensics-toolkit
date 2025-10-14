#!/usr/bin/env bash
# Usage: urlscan_submit.sh URL CASE_SLUG
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/common.sh
source "$SCRIPT_DIR/common.sh"

TARGET_URL="${1:?URL required}"
CASE_SLUG="${2:?CASE_SLUG}"
export CASE_SLUG
if [ -z "${URLSCAN_API_KEY:-}" ]; then
  log "urlscan: missing URLSCAN_API_KEY; skipping submit for $TARGET_URL"
  exit 0
fi

TS=$(date -u +'%Y%m%dT%H%M%SZ')
OUT="outputs/${CASE_SLUG}/urlscan_submit_${TS}.json"
mkdir -p "outputs/${CASE_SLUG}"

log "urlscan: submit $TARGET_URL"
curl -sS -X POST "https://urlscan.io/api/v1/scan/" \
  -H "API-Key: ${URLSCAN_API_KEY}" \
  -H "Content-Type: application/json" \
  --data "{\"url\": \"${TARGET_URL}\", \"visibility\": \"public\"}" \
  -o "$OUT"

log "urlscan: submit response → $OUT"
