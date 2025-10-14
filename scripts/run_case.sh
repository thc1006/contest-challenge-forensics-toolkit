#!/usr/bin/env bash
# Usage: run_case.sh cases/<name>.yaml
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/common.sh
source "$SCRIPT_DIR/common.sh"

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Dependency checks
echo -e "${BLUE}=== Contest Challenge Forensics Toolkit ===${NC}"
echo ""

if ! command -v yq >/dev/null 2>&1; then
  echo -e "${RED}ERROR: yq is not installed${NC}" >&2
  echo "Install from: https://github.com/mikefarah/yq#install" >&2
  echo "" >&2
  echo "Quick install:" >&2
  echo "  Linux: sudo wget https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 -O /usr/bin/yq && sudo chmod +x /usr/bin/yq" >&2
  echo "  macOS: brew install yq" >&2
  echo "  Windows: choco install yq" >&2
  exit 1
fi

if ! command -v jq >/dev/null 2>&1; then
  echo -e "${RED}ERROR: jq is not installed${NC}" >&2
  echo "Install: https://stedolan.github.io/jq/download/" >&2
  exit 1
fi

if ! command -v curl >/dev/null 2>&1; then
  echo -e "${RED}ERROR: curl is not installed${NC}" >&2
  exit 1
fi

if ! command -v python3 >/dev/null 2>&1; then
  echo -e "${RED}ERROR: python3 is not installed${NC}" >&2
  exit 1
fi

# Check case file argument
if [ $# -eq 0 ]; then
  echo -e "${RED}ERROR: No case file specified${NC}" >&2
  echo "" >&2
  echo "Usage: $0 cases/<name>.yaml" >&2
  echo "" >&2
  echo "Example:" >&2
  echo "  $0 cases/sample_case.yaml" >&2
  exit 1
fi

CASE_FILE="$1"

# Check if case file exists
if [ ! -f "$CASE_FILE" ]; then
  echo -e "${RED}ERROR: Case file not found: $CASE_FILE${NC}" >&2
  echo "" >&2
  echo "Available case files:" >&2
  ls -1 cases/*.yaml 2>/dev/null || echo "  (none)" >&2
  exit 1
fi

echo -e "${GREEN}✓${NC} Dependencies OK"
echo -e "${GREEN}✓${NC} Case file: $CASE_FILE"
echo ""
CASE_SLUG=$(yq '.case_slug' "$CASE_FILE" 2>/dev/null)
if [ -z "$CASE_SLUG" ] || [ "$CASE_SLUG" = "null" ]; then
  echo -e "${RED}ERROR: Invalid case file - missing or empty 'case_slug'${NC}" >&2
  echo "Check your YAML syntax: yq eval '$CASE_FILE'" >&2
  exit 1
fi

export CASE_SLUG

OUT_DIR="outputs/${CASE_SLUG}"
mkdir -p "$OUT_DIR"
echo "# Logs for case: $CASE_SLUG" > "${OUT_DIR}/LOG.md"
echo "" >> "${OUT_DIR}/LOG.md"

# Read values via yq
DEADLINE_LOCAL=$(yq '.deadline_local' "$CASE_FILE" 2>/dev/null)
RULES_URL=$(yq '.rules_url // ""' "$CASE_FILE" 2>/dev/null)
START=$(yq '.targets.date_window_utc.start // ""' "$CASE_FILE" 2>/dev/null)
END=$(yq '.targets.date_window_utc.end // ""' "$CASE_FILE" 2>/dev/null)

if [ -z "$DEADLINE_LOCAL" ] || [ "$DEADLINE_LOCAL" = "null" ]; then
  echo -e "${YELLOW}WARNING: No deadline_local specified in case file${NC}" >&2
fi

echo -e "${BLUE}--- Case Details ---${NC}"
echo "  Case slug: $CASE_SLUG"
echo "  Rules URL: ${RULES_URL:-N/A}"
echo "  Deadline (local): ${DEADLINE_LOCAL:-N/A}"
echo "  Date window: ${START:-N/A} to ${END:-N/A}"
echo ""

log "=== Starting case: $CASE_SLUG ==="
log "Case file: $CASE_FILE"
log "Rules: ${RULES_URL:-N/A}"
log "Deadline (local): ${DEADLINE_LOCAL:-N/A}"
log "Date window (UTC): ${START} to ${END}"

# Repos
echo -e "${BLUE}--- Collecting Repository Evidence ---${NC}"
REPO_COUNT=$(yq '.targets.repos | length' "$CASE_FILE" 2>/dev/null)
if [ "$REPO_COUNT" = "null" ] || [ "$REPO_COUNT" = "" ]; then REPO_COUNT=0; fi

if [ "$REPO_COUNT" -eq 0 ]; then
  echo -e "${YELLOW}No repositories specified in case file${NC}"
  log "No repositories to process"
else
  echo "Found $REPO_COUNT repository(ies)"
  log "Processing $REPO_COUNT repositories"
  
  for i in $(seq 0 $((REPO_COUNT-1))); do
    OWNER=$(yq ".targets.repos[$i].owner" "$CASE_FILE")
    NAME=$(yq ".targets.repos[$i].name" "$CASE_FILE")
    
    echo -e "  ${GREEN}▸${NC} Repository: $OWNER/$NAME"
    
    # GH Archive
    if [ -n "$START" ] && [ -n "$END" ] && [ "$START" != "null" ] && [ "$END" != "null" ]; then
      echo "    - Fetching GH Archive data..."
      scripts/gharchive_pull.sh "$OWNER" "$NAME" "$START" "$END" "$CASE_SLUG" || log "ERROR: gharchive_pull.sh failed for $OWNER/$NAME"
    else
      echo -e "    ${YELLOW}- Skipping GH Archive (no date window)${NC}"
    fi
    
    # Commits
    COMMIT_COUNT=$(yq ".targets.repos[$i].commits | length" "$CASE_FILE" 2>/dev/null)
    if [ "$COMMIT_COUNT" = "null" ] || [ "$COMMIT_COUNT" = "" ]; then COMMIT_COUNT=0; fi
    
    if [ "$COMMIT_COUNT" -gt 0 ]; then
      echo "    - Processing $COMMIT_COUNT commit(s)..."
      for j in $(seq 0 $((COMMIT_COUNT-1))); do
        SHA=$(yq ".targets.repos[$i].commits[$j]" "$CASE_FILE")
        echo "      • Commit: ${SHA:0:7}..."
        scripts/github_commit_time.sh "$OWNER" "$NAME" "$SHA" "$CASE_SLUG" || log "ERROR: github_commit_time.sh failed for $SHA"
        scripts/wayback_save.sh "https://github.com/${OWNER}/${NAME}/commit/${SHA}" "$CASE_SLUG" || log "ERROR: wayback_save.sh failed for commit $SHA"
      done
    fi
  done
fi
echo ""

# Websites
echo -e "${BLUE}--- Collecting Website Evidence ---${NC}"
WS_COUNT=$(yq '.targets.websites | length' "$CASE_FILE" 2>/dev/null)
if [ "$WS_COUNT" = "null" ] || [ "$WS_COUNT" = "" ]; then WS_COUNT=0; fi

if [ "$WS_COUNT" -eq 0 ]; then
  echo -e "${YELLOW}No websites specified in case file${NC}"
  log "No websites to process"
else
  echo "Found $WS_COUNT website(s)"
  log "Processing $WS_COUNT websites"
  
  for i in $(seq 0 $((WS_COUNT-1))); do
    URL=$(yq ".targets.websites[$i].url" "$CASE_FILE")
    DOMAIN=$(yq ".targets.websites[$i].domain" "$CASE_FILE")
    
    echo -e "  ${GREEN}▸${NC} Website: $URL"
    echo "    - HTTP probe..."
    scripts/http_probe.sh "$URL" "$CASE_SLUG" || log "ERROR: http_probe.sh failed for $URL"
    
    echo "    - urlscan.io submit..."
    scripts/urlscan_submit.sh "$URL" "$CASE_SLUG" || log "WARNING: urlscan_submit.sh failed (may need API key)"
    
    echo "    - urlscan.io search..."
    scripts/urlscan_search.sh "$DOMAIN" "$CASE_SLUG" || log "ERROR: urlscan_search.sh failed for $DOMAIN"
    
    echo "    - Certificate Transparency..."
    scripts/ct_lookup.sh "$DOMAIN" "$CASE_SLUG" || log "ERROR: ct_lookup.sh failed for $DOMAIN"
    
    echo "    - DNS history (SecurityTrails)..."
    scripts/dns_history_securitytrails.sh "$DOMAIN" "$CASE_SLUG" || log "WARNING: dns_history.sh failed (may need API key)"
  done
fi
echo ""

# Compile timeline
echo -e "${BLUE}--- Compiling Timeline Report ---${NC}"
if python3 tools/compile_timeline.py --case "$CASE_FILE"; then
  echo -e "${GREEN}✓${NC} Timeline compiled successfully"
  log "Timeline compiled successfully"
else
  echo -e "${RED}ERROR: Failed to compile timeline${NC}" >&2
  log "ERROR: compile_timeline.py failed"
fi
echo ""

# Manifest
echo -e "${BLUE}--- Generating Evidence Manifest ---${NC}"
if scripts/save_sources_manifest.sh "$CASE_SLUG"; then
  echo -e "${GREEN}✓${NC} Evidence manifest created"
  log "Evidence manifest created"
else
  echo -e "${RED}ERROR: Failed to create manifest${NC}" >&2
  log "ERROR: save_sources_manifest.sh failed"
fi
echo ""

# Summary
echo -e "${GREEN}=== Case Complete ===${NC}"
echo ""
echo -e "Output directory: ${BLUE}outputs/${CASE_SLUG}/${NC}"
echo ""
echo "Generated files:"
echo "  📊 timeline.md          - Main timeline report"
echo "  🔒 sources_manifest.txt - SHA256 checksums"
echo "  📝 LOG.md               - Execution log"
echo ""
echo "View timeline:"
echo "  cat outputs/${CASE_SLUG}/timeline.md"
echo ""

log "=== Case $CASE_SLUG finished successfully ==="
