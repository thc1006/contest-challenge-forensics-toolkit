#!/usr/bin/env bash
# Usage: ct_lookup.sh DOMAIN CASE_SLUG
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/common.sh
source "$SCRIPT_DIR/common.sh"

DOMAIN="${1:?DOMAIN required}"
CASE_SLUG="${2:?CASE_SLUG}"
export CASE_SLUG

OUT="outputs/${CASE_SLUG}/ct_${DOMAIN}.json"
mkdir -p "outputs/${CASE_SLUG}"

URL="https://crt.sh/?q=%25.${DOMAIN}&output=json"
log "CT: GET $URL"
curl -sS "$URL" -o "$OUT" || true

EARLIEST=$(jq -r 'map(.not_before)|min' "$OUT" 2>/dev/null || echo "")
COUNT=$(jq -r 'length' "$OUT" 2>/dev/null || echo "0")
log "CT: entries=$COUNT earliest_not_before=${EARLIEST} → $OUT"
