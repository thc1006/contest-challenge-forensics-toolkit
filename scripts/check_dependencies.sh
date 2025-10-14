#!/usr/bin/env bash
# Check all required dependencies and provide helpful error messages

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

ERRORS=0
WARNINGS=0

echo "=== Dependency Checker for Contest Challenge Forensics Toolkit ==="
echo ""

# Function to check command
check_command() {
    local cmd="$1"
    local required="$2"
    local install_hint="$3"
    
    if command -v "$cmd" >/dev/null 2>&1; then
        local version
        version=$($cmd --version 2>&1 | head -n 1 || echo "unknown")
        echo -e "${GREEN}✓${NC} $cmd: $version"
        return 0
    else
        if [ "$required" = "required" ]; then
            echo -e "${RED}✗${NC} $cmd: NOT FOUND (REQUIRED)"
            echo "   Install: $install_hint"
            ((ERRORS++)) || true
            return 1
        else
            echo -e "${YELLOW}⚠${NC} $cmd: NOT FOUND (optional)"
            echo "   Install: $install_hint"
            ((WARNINGS++)) || true
            return 0  # Return 0 for optional tools to not trigger set -e
        fi
    fi
}

# Core dependencies
echo "--- Core Dependencies ---"
check_command "bash" "required" "Already installed (Git Bash detected)"
check_command "curl" "required" "Windows: included in Git Bash | Linux: apt install curl"
check_command "jq" "required" "Windows: https://stedolan.github.io/jq/download/ | Linux: apt install jq"
check_command "python3" "required" "https://www.python.org/downloads/ (need Python >= 3.9)"

# Python version check
if command -v python3 >/dev/null 2>&1; then
    PY_VERSION=$(python3 -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')")
    PY_MAJOR=$(echo "$PY_VERSION" | cut -d. -f1)
    PY_MINOR=$(echo "$PY_VERSION" | cut -d. -f2)
    
    if [ "$PY_MAJOR" -ge 3 ] && [ "$PY_MINOR" -ge 9 ]; then
        echo -e "${GREEN}✓${NC} Python version: $PY_VERSION (OK)"
        if [ "$PY_MINOR" -lt 10 ]; then
            echo -e "   ${YELLOW}Note: Python 3.10+ recommended, but 3.9 should work${NC}"
        fi
    else
        echo -e "${RED}✗${NC} Python version: $PY_VERSION (need >= 3.9)"
        ((ERRORS++))
    fi
fi

# Python modules
echo ""
echo "--- Python Modules ---"
if command -v python3 >/dev/null 2>&1; then
    if python3 -c "import yaml" 2>/dev/null; then
        echo -e "${GREEN}✓${NC} PyYAML: installed"
    else
        echo -e "${RED}✗${NC} PyYAML: NOT FOUND (REQUIRED)"
        echo "   Install: pip install PyYAML"
        ((ERRORS++))
    fi
    
    if python3 -c "from zoneinfo import ZoneInfo" 2>/dev/null; then
        echo -e "${GREEN}✓${NC} zoneinfo: available"
    elif python3 -c "import zoneinfo" 2>/dev/null; then
        echo -e "${GREEN}✓${NC} zoneinfo: available"
    else
        echo -e "${YELLOW}⚠${NC} zoneinfo: not available"
        echo "   Install: pip install tzdata backports.zoneinfo (for Python < 3.9)"
        ((WARNINGS++))
    fi
fi

# YAML parser
echo ""
echo "--- YAML Parser ---"
check_command "yq" "required" "https://github.com/mikefarah/yq#install"

# Optional tools
echo ""
echo "--- Optional Tools ---"
check_command "git" "optional" "https://git-scm.com/downloads"
check_command "gh" "optional" "https://cli.github.com/"

# Environment file check (optional in CI)
echo ""
echo "--- Configuration ---"
if [ -f ".env" ]; then
    echo -e "${GREEN}✓${NC} .env file exists"
    
    # shellcheck disable=SC1091
    source .env 2>/dev/null || true
    
    if [ -n "${GITHUB_TOKEN:-}" ]; then
        echo -e "${GREEN}✓${NC} GITHUB_TOKEN: configured"
    else
        echo -e "${YELLOW}⚠${NC} GITHUB_TOKEN: not set (optional, but recommended to avoid rate limits)"
    fi
    
    if [ -n "${URLSCAN_API_KEY:-}" ]; then
        echo -e "${GREEN}✓${NC} URLSCAN_API_KEY: configured"
    else
        echo -e "${YELLOW}⚠${NC} URLSCAN_API_KEY: not set (optional)"
    fi
    
    if [ -n "${SECURITYTRAILS_API_KEY:-}" ]; then
        echo -e "${GREEN}✓${NC} SECURITYTRAILS_API_KEY: configured"
    else
        echo -e "${YELLOW}⚠${NC} SECURITYTRAILS_API_KEY: not set (optional)"
    fi
    
    if [ -n "${LOCAL_TZ:-}" ]; then
        echo -e "${GREEN}✓${NC} LOCAL_TZ: $LOCAL_TZ"
    else
        echo -e "${YELLOW}⚠${NC} LOCAL_TZ: not set (will default to Asia/Taipei)"
    fi
else
    echo -e "${YELLOW}⚠${NC} .env file NOT FOUND (optional for CI)"
    echo "   Run: cp .env.sample .env"
    ((WARNINGS++)) || true
fi

# Summary
echo ""
echo "=== Summary ==="
if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo -e "${GREEN}✓ All dependencies satisfied! Ready to use.${NC}"
    exit 0
elif [ $ERRORS -eq 0 ]; then
    echo -e "${YELLOW}⚠ $WARNINGS warnings (optional dependencies missing)${NC}"
    echo "The toolkit will work, but some features may be limited."
    exit 0
else
    echo -e "${RED}✗ $ERRORS errors found${NC}"
    if [ $WARNINGS -gt 0 ]; then
        echo -e "${YELLOW}⚠ $WARNINGS warnings${NC}"
    fi
    echo ""
    echo "Please install missing dependencies before running the toolkit."
    exit 1
fi
