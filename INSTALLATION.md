# Installation Guide

This guide will help you install and set up the Contest Challenge Forensics Toolkit on your system.

## Prerequisites

This toolkit requires:
- **Bash** (4.0+)
- **Python** (3.9+, 3.10+ recommended)
- **curl** (for HTTP requests)
- **jq** (for JSON processing)
- **yq** (for YAML parsing)

Optional:
- **git** (for version control)
- **gh** (GitHub CLI, for enhanced GitHub operations)

---

## Installation by Platform

### Windows

#### 1. Install Git Bash
Download and install [Git for Windows](https://git-scm.com/download/win), which includes Git Bash.

During installation, select:
- "Use Git and optional Unix tools from the Command Prompt"
- This provides bash, curl, and other Unix tools

#### 2. Install jq
**Option A: Using Chocolatey (recommended)**
```powershell
choco install jq
```

**Option B: Manual installation**
1. Download `jq-windows-amd64.exe` from https://stedolan.github.io/jq/download/
2. Rename it to `jq.exe`
3. Place it in a directory in your PATH (e.g., `C:\Windows\System32` or `C:\Program Files\Git\usr\bin`)

#### 3. Install yq
**Option A: Using Chocolatey**
```powershell
choco install yq
```

**Option B: Using Scoop**
```powershell
scoop install yq
```

**Option C: Manual installation**
1. Download the Windows binary from https://github.com/mikefarah/yq/releases
2. Rename it to `yq.exe`
3. Place it in a directory in your PATH

#### 4. Install Python
1. Download Python 3.10+ from https://www.python.org/downloads/
2. During installation, check "Add Python to PATH"
3. Verify: `python --version`

#### 5. Install Python dependencies
```bash
pip install PyYAML
```

For Python 3.9, you may need:
```bash
pip install PyYAML tzdata backports.zoneinfo
```

---

### Linux (Ubuntu/Debian)

```bash
# Update package list
sudo apt update

# Install core dependencies
sudo apt install -y bash curl jq python3 python3-pip

# Install yq
sudo wget https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 -O /usr/bin/yq
sudo chmod +x /usr/bin/yq

# Install Python dependencies
pip3 install PyYAML
```

---

### macOS

```bash
# Install Homebrew if not already installed
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install dependencies
brew install bash curl jq yq python3

# Install Python dependencies
pip3 install PyYAML
```

---

## Setup

### 1. Clone or download the repository
```bash
cd /path/to/your/projects
git clone <repository-url>
cd contest-challenge-forensics-toolkit
```

### 2. Create configuration file
```bash
cp .env.sample .env
```

### 3. Edit `.env` file
Open `.env` in your favorite text editor and configure:

```bash
# (Optional) GitHub token - highly recommended to avoid rate limits
# Get one at: https://github.com/settings/tokens
GITHUB_TOKEN=your_token_here

# (Optional) urlscan.io API key
# Register at: https://urlscan.io/about-api/
URLSCAN_API_KEY=your_key_here

# (Optional) SecurityTrails API key
# Sign up at: https://securitytrails.com/
SECURITYTRAILS_API_KEY=your_key_here

# Your local timezone (IANA format)
# Examples: Asia/Taipei, America/New_York, Europe/London
LOCAL_TZ=Asia/Taipei
```

**Note:** The toolkit works without API keys, but:
- `GITHUB_TOKEN` is **strongly recommended** to avoid GitHub API rate limits
- Other keys are optional and enable additional data sources

### 4. Verify installation
```bash
bash scripts/check_dependencies.sh
```

This script checks all dependencies and provides helpful installation hints if anything is missing.

---

## API Keys (Optional but Recommended)

### GitHub Token
1. Go to https://github.com/settings/tokens
2. Click "Generate new token (classic)"
3. Give it a name (e.g., "Forensics Toolkit")
4. Select scopes: `public_repo` (read-only is sufficient)
5. Copy the token and paste it in `.env`

**Rate Limits:**
- Without token: 60 requests/hour
- With token: 5,000 requests/hour

### urlscan.io API Key
1. Register at https://urlscan.io/user/signup
2. Go to https://urlscan.io/user/profile/
3. Copy your API key
4. Paste it in `.env`

### SecurityTrails API Key
1. Sign up at https://securitytrails.com/
2. Go to API settings
3. Copy your API key
4. Paste it in `.env`

---

## Verification

After installation, run the dependency checker:

```bash
bash scripts/check_dependencies.sh
```

Expected output:
```
=== Dependency Checker for Contest Challenge Forensics Toolkit ===

--- Core Dependencies ---
✓ bash: GNU bash, version 5.x.x
✓ curl: curl 8.x.x
✓ jq: jq-1.6
✓ python3: Python 3.10.x
✓ Python version: 3.10.x (OK)

--- Python Modules ---
✓ PyYAML: installed
✓ zoneinfo: available

--- YAML Parser ---
✓ yq: yq (https://github.com/mikefarah/yq/) version 4.x.x

--- Configuration ---
✓ .env file exists
✓ GITHUB_TOKEN: configured
✓ LOCAL_TZ: Asia/Taipei

=== Summary ===
✓ All dependencies satisfied! Ready to use.
```

---

## Quick Start

Create your first case:

```bash
# Copy sample case
cp cases/sample_case.yaml cases/my_case.yaml

# Edit it with your case details
nano cases/my_case.yaml

# Run the analysis
bash scripts/run_case.sh cases/my_case.yaml

# View results
cat outputs/<case_slug>/timeline.md
```

---

## Troubleshooting

### "yq: command not found"
- Windows: Install via Chocolatey or manually download yq.exe
- Linux: Follow the Linux installation steps above
- macOS: `brew install yq`

### "curl: not found" on Windows
- Make sure you're running in Git Bash, not PowerShell
- In PowerShell, `curl` is an alias for `Invoke-WebRequest` and won't work

### Python zoneinfo errors
For Python 3.9:
```bash
pip install tzdata backports.zoneinfo
```

Then modify `tools/compile_timeline.py` to use:
```python
try:
    from zoneinfo import ZoneInfo
except ImportError:
    from backports.zoneinfo import ZoneInfo
```

### Permission denied errors
On Linux/macOS, make scripts executable:
```bash
chmod +x scripts/*.sh
```

---

## Next Steps

- Read [README.md](README.md) for usage instructions
- See [TROUBLESHOOTING.md](TROUBLESHOOTING.md) for common issues
- Check [cases/sample_case.yaml](cases/sample_case.yaml) for case file format
