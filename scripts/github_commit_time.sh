#!/usr/bin/env bash
# Usage: github_commit_time.sh OWNER REPO COMMIT_SHA CASE_SLUG
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/common.sh
source "$SCRIPT_DIR/common.sh"

OWNER="${1:?OWNER}"
REPO="${2:?REPO}"
SHA="${3:?COMMIT_SHA}"
CASE_SLUG="${4:?CASE_SLUG}"
export CASE_SLUG

OUT="outputs/${CASE_SLUG}/github_commit_${SHA}.json"
mkdir -p "outputs/${CASE_SLUG}"

AUTH=()
if [ -n "${GITHUB_TOKEN:-}" ]; then
  AUTH=(-H "Authorization: Bearer ${GITHUB_TOKEN}")
fi

URL="https://api.github.com/repos/${OWNER}/${REPO}/commits/${SHA}"
log "GitHub API: GET $URL"
set +e
curl -sS -H "Accept: application/vnd.github+json" "${AUTH[@]}" "$URL" -o "$OUT"
RC=$?
set -e

if [ $RC -ne 0 ]; then
  log "GitHub API failed (rc=$RC). See $OUT"
else
  AUTHOR_TIME=$(jq -r '.commit.author.date' "$OUT" 2>/dev/null || echo "")
  COMMITTER_TIME=$(jq -r '.commit.committer.date' "$OUT" 2>/dev/null || echo "")
  log "GitHub API: author.date=$AUTHOR_TIME, committer.date=$COMMITTER_TIME → $OUT"
fi
