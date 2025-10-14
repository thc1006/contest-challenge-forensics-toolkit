#!/usr/bin/env bash
# Automatic dependency installer for Contest Challenge Forensics Toolkit
# Supports: Windows (Git Bash + Chocolatey), Linux (apt/yum), macOS (Homebrew)

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=== Dependency Installer for Contest Challenge Forensics Toolkit ===${NC}"
echo ""

# Detect OS
detect_os() {
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        echo "linux"
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        echo "macos"
    elif [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]]; then
        echo "windows"
    else
        echo "unknown"
    fi
}

OS=$(detect_os)
echo -e "Detected OS: ${BLUE}$OS${NC}"
echo ""

# Check if running as root (needed for some installations)
check_sudo() {
    if [[ "$OS" != "windows" ]] && [[ $EUID -ne 0 ]]; then
        echo -e "${YELLOW}Note: Some installations may require sudo password${NC}"
        echo ""
    fi
}

# Install jq
install_jq() {
    echo -e "${BLUE}Installing jq...${NC}"
    case $OS in
        linux)
            if command -v apt-get >/dev/null 2>&1; then
                sudo apt-get update && sudo apt-get install -y jq
            elif command -v yum >/dev/null 2>&1; then
                sudo yum install -y jq
            elif command -v dnf >/dev/null 2>&1; then
                sudo dnf install -y jq
            else
                echo -e "${RED}Unable to install jq automatically. Please install manually.${NC}"
                return 1
            fi
            ;;
        macos)
            if ! command -v brew >/dev/null 2>&1; then
                echo -e "${RED}Homebrew not found. Installing Homebrew first...${NC}"
                /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
            fi
            brew install jq
            ;;
        windows)
            if command -v choco >/dev/null 2>&1; then
                choco install jq -y
            else
                echo -e "${YELLOW}Chocolatey not found.${NC}"
                echo "Please install jq manually:"
                echo "  1. Download from: https://stedolan.github.io/jq/download/"
                echo "  2. Rename to jq.exe"
                echo "  3. Place in: C:\\Program Files\\Git\\usr\\bin\\"
                return 1
            fi
            ;;
        *)
            echo -e "${RED}Unsupported OS${NC}"
            return 1
            ;;
    esac
    echo -e "${GREEN}✓ jq installed${NC}"
}

# Install yq
install_yq() {
    echo -e "${BLUE}Installing yq...${NC}"
    case $OS in
        linux)
            sudo curl -L https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 -o /usr/local/bin/yq
            sudo chmod +x /usr/local/bin/yq
            ;;
        macos)
            if ! command -v brew >/dev/null 2>&1; then
                echo -e "${RED}Homebrew not found. Installing Homebrew first...${NC}"
                /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
            fi
            brew install yq
            ;;
        windows)
            if command -v choco >/dev/null 2>&1; then
                choco install yq -y
            else
                echo -e "${YELLOW}Chocolatey not found.${NC}"
                echo "Please install yq manually:"
                echo "  1. Download from: https://github.com/mikefarah/yq/releases"
                echo "  2. Rename to yq.exe"
                echo "  3. Place in: C:\\Program Files\\Git\\usr\\bin\\"
                return 1
            fi
            ;;
        *)
            echo -e "${RED}Unsupported OS${NC}"
            return 1
            ;;
    esac
    echo -e "${GREEN}✓ yq installed${NC}"
}

# Install Python dependencies
install_python_deps() {
    echo -e "${BLUE}Installing Python dependencies...${NC}"
    
    if ! command -v python3 >/dev/null 2>&1 && ! command -v python >/dev/null 2>&1; then
        echo -e "${RED}Python not found. Please install Python 3.9+ first.${NC}"
        case $OS in
            linux)
                echo "  sudo apt-get install python3 python3-pip"
                ;;
            macos)
                echo "  brew install python3"
                ;;
            windows)
                echo "  Download from: https://www.python.org/downloads/"
                ;;
        esac
        return 1
    fi
    
    # Try pip3 first, then pip
    if command -v pip3 >/dev/null 2>&1; then
        pip3 install -r requirements.txt
    elif command -v pip >/dev/null 2>&1; then
        pip install -r requirements.txt
    else
        python3 -m pip install -r requirements.txt || python -m pip install -r requirements.txt
    fi
    
    echo -e "${GREEN}✓ Python dependencies installed${NC}"
}

# Main installation
main() {
    check_sudo
    
    ERRORS=0
    
    # Check what's missing
    NEED_JQ=false
    NEED_YQ=false
    
    if ! command -v jq >/dev/null 2>&1; then
        NEED_JQ=true
    fi
    
    if ! command -v yq >/dev/null 2>&1; then
        NEED_YQ=true
    fi
    
    if [[ "$NEED_JQ" == false ]] && [[ "$NEED_YQ" == false ]]; then
        echo -e "${GREEN}✓ All command-line tools already installed!${NC}"
    else
        echo "Installing missing dependencies..."
        echo ""
        
        if [[ "$NEED_JQ" == true ]]; then
            install_jq || ((ERRORS++))
            echo ""
        fi
        
        if [[ "$NEED_YQ" == true ]]; then
            install_yq || ((ERRORS++))
            echo ""
        fi
    fi
    
    # Install Python dependencies
    if [ -f "requirements.txt" ]; then
        install_python_deps || ((ERRORS++))
        echo ""
    fi
    
    # Setup .env if not exists
    if [ ! -f ".env" ]; then
        echo -e "${BLUE}Creating .env file...${NC}"
        cp .env.sample .env
        echo -e "${GREEN}✓ .env created from .env.sample${NC}"
        echo -e "${YELLOW}Please edit .env to add your API keys${NC}"
        echo ""
    fi
    
    # Create necessary directories
    echo -e "${BLUE}Creating output directories...${NC}"
    mkdir -p outputs data/{gharchive,github,urlscan,ct,dns,wayback}
    echo -e "${GREEN}✓ Directories created${NC}"
    echo ""
    
    # Final check
    echo -e "${BLUE}=== Verification ===${NC}"
    bash scripts/check_dependencies.sh
    
    if [ $? -eq 0 ]; then
        echo ""
        echo -e "${GREEN}=== Installation Complete! ===${NC}"
        echo ""
        echo "Next steps:"
        echo "  1. Edit .env to add API keys (optional)"
        echo "  2. Run: bash scripts/run_case.sh cases/sample_case.yaml"
        echo ""
    else
        echo ""
        echo -e "${YELLOW}Some dependencies may still be missing.${NC}"
        echo "Please check the output above and install manually if needed."
        echo ""
    fi
}

main "$@"
