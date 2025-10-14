#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export ROOT
cd "$ROOT"

# Load .env if present
if [ -f ".env" ]; then
  set -a
  # shellcheck disable=SC1091
  source ".env"
  set +a
fi

mkdir -p outputs data/gharchive data/github data/urlscan data/ct data/dns data/wayback

log() {
  local case_dir="outputs/${CASE_SLUG:-default}"
  mkdir -p "$case_dir"
  echo "[$(date -u +'%Y-%m-%dT%H:%M:%SZ')] $*" | tee -a "$case_dir/LOG.md"
}
