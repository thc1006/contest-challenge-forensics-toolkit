#!/usr/bin/env bash
# Usage: gharchive_pull.sh OWNER REPO START_DATE END_DATE CASE_SLUG
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/common.sh
source "$SCRIPT_DIR/common.sh"

OWNER="${1:?OWNER required}"
REPO="${2:?REPO required}"
START="${3:?START_DATE YYYY-MM-DD}"
END="${4:?END_DATE YYYY-MM-DD}"
CASE_SLUG="${5:?CASE_SLUG required}"
export CASE_SLUG

OUT_DIR="outputs/${CASE_SLUG}"
mkdir -p "$OUT_DIR"
OUT_JSONL="${OUT_DIR}/gharchive_push_events.jsonl"
OUT_TSV="${OUT_DIR}/gharchive_push_events.tsv"
: > "$OUT_JSONL"
: > "$OUT_TSV"

log "GHArchive: fetching PushEvent for $OWNER/$REPO from $START to $END (UTC)"
python3 tools/fetch_gharchive.py --owner "$OWNER" --repo "$REPO" --start "$START" --end "$END" \
  | tee -a "$OUT_JSONL" > /dev/null

# Convert to TSV
if [ -s "$OUT_JSONL" ]; then
  jq -r '[ .created_at, .actor_login, .repo_name, .ref, (.size|tostring), (.distinct_size|tostring), .head ] | @tsv' \
    "$OUT_JSONL" > "$OUT_TSV" || true
fi

log "GHArchive: done. Outputs: $OUT_JSONL $OUT_TSV"
