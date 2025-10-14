#!/usr/bin/env bash
# Usage: save_sources_manifest.sh CASE_SLUG
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/common.sh
source "$SCRIPT_DIR/common.sh"

CASE_SLUG="${1:?CASE_SLUG}"
export CASE_SLUG

OUT="outputs/${CASE_SLUG}/sources_manifest.txt"
: > "$OUT"
log "Building sources manifest for $CASE_SLUG"
find "outputs/${CASE_SLUG}" -type f -maxdepth 1 ! -name "LOG.md" -print0 | while IFS= read -r -d '' f; do
  if command -v sha256sum >/dev/null 2>&1; then
    sha=$(sha256sum "$f" | awk '{print $1}')
  else
    sha=$(python3 - <<'EOF'
import hashlib,sys
p=sys.argv[1]
h=hashlib.sha256(open(p,'rb').read()).hexdigest()
print(h)
EOF
"$f")
  fi
  printf "%s  %s\n" "$sha" "$f" >> "$OUT"
done
log "Manifest written → $OUT"
