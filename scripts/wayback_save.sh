#!/usr/bin/env bash
# Usage: wayback_save.sh URL CASE_SLUG
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/common.sh
source "$SCRIPT_DIR/common.sh"

TARGET_URL="${1:?URL required}"
CASE_SLUG="${2:?CASE_SLUG}"
export CASE_SLUG

SAFE_NAME=$(echo "$TARGET_URL" | sed 's#[^A-Za-z0-9._-]#_#g')
OUT="outputs/${CASE_SLUG}/wayback_${SAFE_NAME}.json"
mkdir -p "outputs/${CASE_SLUG}" "data/wayback/${CASE_SLUG}"

log "Wayback SavePageNow: $TARGET_URL"
curl -sS -X POST "https://web.archive.org/save/${TARGET_URL}" -D - \
  -o "data/wayback/${CASE_SLUG}/${SAFE_NAME}.html" | tee "data/wayback/${CASE_SLUG}/${SAFE_NAME}.headers.txt" >/dev/null || true

printf '{ "saved": "%s", "target": "%s" }\n' "$(date -u +'%Y-%m-%dT%H:%M:%SZ')" "$TARGET_URL" > "$OUT"
log "Wayback: saved → $OUT"
