#!/usr/bin/env bash
# Quick start script for Contest Challenge Forensics Toolkit
# One-command setup and demo

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}"
cat << "EOF"
   ____            _            _     ____  _           _ _                       
  / ___|___  _ __ | |_ ___  ___| |_  / ___|| |__   __ _| | | ___ _ __   __ _  ___ 
 | |   / _ \| '_ \| __/ _ \/ __| __| | |   | '_ \ / _` | | |/ _ \ '_ \ / _` |/ _ \
 | |__| (_) | | | | ||  __/\__ \ |_  | |___| | | | (_| | | |  __/ | | | (_| |  __/
  \____\___/|_| |_|\__\___||___/\__|  \____|_| |_|\__,_|_|_|\___|_| |_|\__, |\___|
                                                                        |___/      
  Forensics Toolkit - Quick Start
EOF
echo -e "${NC}"
echo ""

# Check if Docker is available
if command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1; then
    echo -e "${GREEN}✓ Docker detected${NC}"
    echo ""
    echo "Choose installation method:"
    echo "  1) Docker (recommended - zero setup)"
    echo "  2) Native installation (requires dependencies)"
    echo ""
    read -p "Enter choice [1]: " choice
    choice=${choice:-1}
    
    if [ "$choice" = "1" ]; then
        echo -e "${BLUE}Building Docker image...${NC}"
        docker-compose build
        
        echo ""
        echo -e "${GREEN}✓ Docker setup complete!${NC}"
        echo ""
        echo "Run a case with Docker:"
        echo "  docker-compose run --rm run-case"
        echo ""
        echo "Or interactive shell:"
        echo "  docker-compose run --rm forensics-toolkit"
        echo ""
        exit 0
    fi
fi

# Native installation
echo -e "${BLUE}Starting native installation...${NC}"
echo ""

# Run dependency installer
if [ -f "scripts/install_dependencies.sh" ]; then
    bash scripts/install_dependencies.sh
else
    echo -e "${RED}Error: install_dependencies.sh not found${NC}"
    exit 1
fi

# Check if installation succeeded
echo ""
echo -e "${BLUE}Verifying installation...${NC}"
if bash scripts/check_dependencies.sh; then
    echo ""
    echo -e "${GREEN}=== Quick Start Complete! ===${NC}"
    echo ""
    echo "Try the sample case:"
    echo -e "  ${YELLOW}bash scripts/run_case.sh cases/sample_case.yaml${NC}"
    echo ""
    echo "Or create your own:"
    echo "  cp cases/sample_case.yaml cases/my_case.yaml"
    echo "  nano cases/my_case.yaml"
    echo "  bash scripts/run_case.sh cases/my_case.yaml"
    echo ""
else
    echo ""
    echo -e "${YELLOW}Installation incomplete. Please check errors above.${NC}"
    echo ""
    echo "For manual installation, see:"
    echo "  cat INSTALLATION.md"
    echo ""
fi
