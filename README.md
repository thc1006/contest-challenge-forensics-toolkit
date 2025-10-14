
# Contest Challenge Forensics Toolkit

> **Automated evidence collection & timeline generation for verifying contest submissions**

**Build evidence-based timelines to verify contest submissions using public, reproducible data sources.**

This toolkit collects and analyzes data from multiple authoritative sources (GH Archive, GitHub API, CT logs, urlscan, Wayback Machine, DNS history) to create a comprehensive timeline comparing **deadline vs. actual behavior**, helping you challenge contest results with facts.

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![CI](https://github.com/thc1006/contest-challenge-forensics-toolkit/actions/workflows/ci.yml/badge.svg)](https://github.com/thc1006/contest-challenge-forensics-toolkit/actions/workflows/ci.yml)
[![Docker](https://img.shields.io/badge/docker-ready-blue.svg)](https://hub.docker.com)
[![Python](https://img.shields.io/badge/python-3.9%2B-blue.svg)](https://www.python.org)
[![Bash](https://img.shields.io/badge/bash-4.0%2B-green.svg)](https://www.gnu.org/software/bash/)
[![GitHub Release](https://img.shields.io/github/v/release/thc1006/contest-challenge-forensics-toolkit)](https://github.com/thc1006/contest-challenge-forensics-toolkit/releases)

---

## 🎯 Features

- **📊 Multi-Source Data Collection**: Automatically gathers evidence from 6+ public sources
- **⏰ Dual-Timezone Display**: Shows all timestamps in both UTC and your local timezone
- **✅ Deadline Verification**: Automatically flags late submissions with ❌ markers
- **🔒 Tamper-Proof Evidence**: All source files include SHA256 checksums
- **📝 Comprehensive Logging**: Every operation is logged for audit trails
- **🚀 Fully Automated**: One command to collect, analyze, and generate reports
- **💾 CLI-Only**: No GUI required, perfect for automation and CI/CD

---

## 📋 Requirements

### Core Dependencies
- **Bash** 4.0+ (Git Bash on Windows)
- **curl** (HTTP requests)
- **jq** (JSON processing)
- **yq** (YAML parsing) - [Install guide](https://github.com/mikefarah/yq#install)
- **Python** 3.9+ (3.10+ recommended)
- **PyYAML** (`pip install PyYAML`)

### Optional (but recommended)
- **GitHub Personal Access Token** (avoid rate limits)
- **urlscan.io API key** (web scanning history)
- **SecurityTrails API key** (DNS history)

**Quick check:** Run `bash scripts/check_dependencies.sh` to verify all dependencies.

**Auto-install:** Run `bash scripts/install_dependencies.sh` to install missing dependencies automatically.

---

## 🚀 Quick Start

### Option 1: One-Command Setup (Recommended)

```bash
bash quick-start.sh
```

This interactive script will:
- Detect your OS and install dependencies automatically
- Or set up Docker if available
- Create necessary directories
- Verify installation

### Option 2: Docker (Zero Setup)

**Prerequisites:** Docker and Docker Compose installed

```bash
# Build and run with Docker
docker-compose build
docker-compose run --rm run-case

# Or interactive shell
docker-compose run --rm forensics-toolkit
bash scripts/run_case.sh cases/sample_case.yaml
```

**Advantages:**
- ✅ No dependency installation needed
- ✅ Consistent environment across all platforms
- ✅ Isolated from host system
- ✅ Production-ready

### Option 3: Manual Installation

See [INSTALLATION.md](INSTALLATION.md) for detailed platform-specific instructions.

**Automatic Installation (all platforms):**
```bash
bash scripts/install_dependencies.sh
```

**Manual Installation:**

<details>
<summary>Click to expand manual installation instructions</summary>

**Linux (Ubuntu/Debian):**
```bash
sudo apt install bash curl jq python3 python3-pip
sudo wget https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 -O /usr/bin/yq
sudo chmod +x /usr/bin/yq
pip3 install -r requirements.txt
```

**macOS:**
```bash
brew install bash curl jq yq python3
pip3 install -r requirements.txt
```

**Windows:**
1. Install [Git for Windows](https://git-scm.com/download/win) (includes Git Bash)
2. Install jq and yq (via Chocolatey: `choco install jq yq`)
3. Install Python 3.9+ from [python.org](https://www.python.org/downloads/)
4. Run `pip install -r requirements.txt`

</details>

### 2. Verify Installation

```bash
bash scripts/check_dependencies.sh
```

### 3. Setup Configuration

```bash
# Copy sample config
cp .env.sample .env

# Edit with your settings
nano .env
```

Minimal `.env` configuration:
```bash
GITHUB_TOKEN=your_token_here    # Get from: https://github.com/settings/tokens
LOCAL_TZ=Asia/Taipei            # Your timezone
```

### 4. Create Your First Case

```bash
# Copy sample case
cp cases/sample_case.yaml cases/my_case.yaml

# Edit with your case details
nano cases/my_case.yaml
```

Example case file:
```yaml
case_slug: my_contest_case
rules_url: https://example.org/contest/rules
deadline_local: 2025-10-06T00:00:00+08:00  # Include timezone!

targets:
  date_window_utc:
    start: 2025-10-01  # A few days before deadline
    end:   2025-10-07  # A few days after deadline
  repos:
    - owner: username
      name: repository-name
      commits:
        - abc1234567890abcdef1234567890abcdef1234  # Full commit SHA
  websites:
    - url: https://example.com/
      domain: example.com
```

### 5. Run Analysis

```bash
# Using Makefile
make case CASE=cases/my_case.yaml

# Or directly
bash scripts/run_case.sh cases/my_case.yaml
```

### 6. View Results

```bash
# View timeline report
cat outputs/my_contest_case/timeline.md

# Check all collected evidence
ls -la outputs/my_contest_case/

# Verify checksums
cat outputs/my_contest_case/sources_manifest.txt
```

---

## 📊 Data Sources

| Source | Purpose | Auth Required | Reliability |
|--------|---------|---------------|-------------|
| **GH Archive** | GitHub PushEvent server-side timestamps | No | ⭐⭐⭐⭐⭐ Most reliable |
| **GitHub API** | Commit author/committer timestamps | Recommended | ⭐⭐⭐⭐ (can be manipulated) |
| **Certificate Transparency** | SSL certificate issuance dates | No | ⭐⭐⭐⭐⭐ Append-only logs |
| **urlscan.io** | Historical website scans | Optional | ⭐⭐⭐ Third-party observations |
| **Wayback Machine** | Website snapshots | No | ⭐⭐⭐⭐ Timestamped archives |
| **SecurityTrails** | DNS history | Yes | ⭐⭐⭐ Supplementary data |

---

## 📁 Output Files

After running a case, you'll find:

```
outputs/<case_slug>/
├── timeline.md                    # 📊 Main report (dual-timezone, with ❌ markers)
├── sources_manifest.txt           # 🔒 SHA256 checksums of all evidence
├── LOG.md                         # 📝 Execution log (timestamps + operations)
├── gharchive_push_events.jsonl    # Raw GH Archive data
├── gharchive_push_events.tsv      # Formatted push events
├── github_commit_*.json           # GitHub API responses
├── ct_*.json                      # Certificate Transparency logs
├── urlscan_*.json                 # urlscan.io results
├── dns_*.json                     # DNS history (if available)
├── wayback_*.json                 # Wayback Machine metadata
└── http_probe.txt                 # HTTP response headers
```

---

## 📖 Documentation

- **[INSTALLATION.md](INSTALLATION.md)** - Detailed installation instructions for all platforms
- **[TROUBLESHOOTING.md](TROUBLESHOOTING.md)** - Common issues and solutions
- **[CLAUDE.md](CLAUDE.md)** - Automation guidelines for AI assistants
- **[schemas/case.schema.yaml](schemas/case.schema.yaml)** - Case file format specification

---

## 🔧 Advanced Usage

### Running Multiple Cases

```bash
for case in cases/*.yaml; do
  bash scripts/run_case.sh "$case"
done
```

### Custom Date Range

Adjust `date_window_utc` in your case file to narrow or expand the search:

```yaml
targets:
  date_window_utc:
    start: 2025-10-05  # Narrow to specific dates
    end:   2025-10-06
```

### Manual Evidence Collection

Run individual collectors:

```bash
# GH Archive only
bash scripts/gharchive_pull.sh OWNER REPO START_DATE END_DATE CASE_SLUG

# GitHub API only
bash scripts/github_commit_time.sh OWNER REPO COMMIT_SHA CASE_SLUG

# CT logs only
bash scripts/ct_lookup.sh DOMAIN CASE_SLUG
```

---

## ⚠️ Important Notes

### Timestamp Reliability

**Most Reliable → Least Reliable:**
1. ⭐⭐⭐⭐⭐ GH Archive PushEvent `created_at` (server-side, tamper-proof)
2. ⭐⭐⭐⭐⭐ Certificate Transparency logs (append-only)
3. ⭐⭐⭐⭐ Wayback Machine snapshots (timestamped by IA)
4. ⭐⭐⭐⭐ GitHub API `committer.date` (can be manipulated by client)
5. ⭐⭐⭐ urlscan.io (third-party observations)
6. ⭐⭐⭐ GitHub API `author.date` (easily manipulated)

**Always use multiple sources for verification!**

### API Rate Limits

- **GitHub without token**: 60 requests/hour
- **GitHub with token**: 5,000 requests/hour
- **urlscan.io free tier**: 50 scans/day, 100 searches/day

### Windows Users

- ⚠️ **Always use Git Bash**, not PowerShell or CMD
- PowerShell's `curl` is an alias for `Invoke-WebRequest` and won't work
- Make sure yq.exe and jq.exe are in your PATH

---

## 🐛 Troubleshooting

**Common Issues:**

1. **"yq: command not found"** → See [INSTALLATION.md](INSTALLATION.md#3-install-yq)
2. **Python zoneinfo errors** → `pip install tzdata backports.zoneinfo`
3. **GitHub rate limit** → Add `GITHUB_TOKEN` to `.env`
4. **Empty timeline** → Check `LOG.md`, verify date range and repo details
5. **Permission denied** → `chmod +x scripts/*.sh` or use `bash scripts/...`

For detailed solutions, see [TROUBLESHOOTING.md](TROUBLESHOOTING.md).

---

## 🤝 Contributing

Contributions welcome! Areas for improvement:

- Additional data sources (Internet Archive CDX API, etc.)
- Better error handling and retry logic
- Parallel downloads for GH Archive
- Support for more evidence types (Docker Hub, npm registry, etc.)
- Web UI for report viewing

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 🙏 Acknowledgments

- [GH Archive](https://www.gharchive.org/) - GitHub event archive
- [GitHub](https://github.com/) - Git hosting and API
- [crt.sh](https://crt.sh/) - Certificate Transparency search
- [urlscan.io](https://urlscan.io/) - URL scanning service
- [Internet Archive](https://web.archive.org/) - Wayback Machine
- [SecurityTrails](https://securitytrails.com/) - DNS history

---

## 📞 Support

- **Issues**: For bugs or feature requests, open an issue
- **Documentation**: Check [INSTALLATION.md](INSTALLATION.md) and [TROUBLESHOOTING.md](TROUBLESHOOTING.md)
- **Dependencies**: Run `bash scripts/check_dependencies.sh` for diagnostics

---

**Made with ❤️ for fair competition and evidence-based verification.**
