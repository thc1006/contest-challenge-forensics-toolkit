#!/usr/bin/env bash
# Usage: urlscan_search.sh DOMAIN CASE_SLUG
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/common.sh
source "$SCRIPT_DIR/common.sh"

Q="${1:?domain or query}"
CASE_SLUG="${2:?CASE_SLUG}"
export CASE_SLUG

# shellcheck disable=SC2001
SAFE=$(echo "$Q" | sed 's#[^A-Za-z0-9._-]#_#g')
OUT="outputs/${CASE_SLUG}/urlscan_search_${SAFE}.json"
mkdir -p "outputs/${CASE_SLUG}"

log "urlscan: search $Q"
curl -sS "https://urlscan.io/api/v1/search/?q=domain:${Q}" -o "$OUT" || true
log "urlscan: search results → $OUT"
