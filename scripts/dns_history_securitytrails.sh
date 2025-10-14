#!/usr/bin/env bash
# Usage: dns_history_securitytrails.sh DOMAIN CASE_SLUG
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/common.sh
source "$SCRIPT_DIR/common.sh"

DOMAIN="${1:?DOMAIN required}"
CASE_SLUG="${2:?CASE_SLUG}"
export CASE_SLUG

if [ -z "${SECURITYTRAILS_API_KEY:-}" ]; then
  log "SecurityTrails API key missing; skipping DNS history for $DOMAIN"
  exit 0
fi

OUT="outputs/${CASE_SLUG}/dns_${DOMAIN}.json"
mkdir -p "outputs/${CASE_SLUG}"

log "DNS history (SecurityTrails): $DOMAIN"
curl -sS "https://api.securitytrails.com/v1/history/${DOMAIN}/dns/a" \
  -H "APIKEY: ${SECURITYTRAILS_API_KEY}" -o "$OUT" || true
log "DNS history saved → $OUT"
