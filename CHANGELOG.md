# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2025-10-15

### Added
- Initial release of Contest Challenge Forensics Toolkit
- Multi-source evidence collection from 6+ public sources:
  - GH Archive (GitHub event archive)
  - GitHub REST API
  - Certificate Transparency logs
  - urlscan.io
  - Internet Archive Wayback Machine
  - SecurityTrails DNS history
- Automated timeline compilation with dual-timezone display (UTC + local)
- Deadline verification with automatic late submission flagging
- SHA256 checksums for all evidence files
- Comprehensive documentation:
  - README.md with features and usage
  - INSTALLATION.md for all platforms
  - TROUBLESHOOTING.md for common issues
- Dependency checker script (`scripts/check_dependencies.sh`)
- Automatic dependency installer (`scripts/install_dependencies.sh`)
- Docker support with Dockerfile and docker-compose.yml
- GitHub Actions CI/CD pipeline for automated testing
- Quick start script for one-command setup
- Python 3.9+ support with zoneinfo backport
- 11 bash collection scripts
- 2 Python analysis tools
- YAML schema validation
- .gitignore for security (protects .env and outputs)

### Features
- **CLI-only**: No GUI required, perfect for automation
- **Cross-platform**: Windows (Git Bash), Linux, macOS
- **Reproducible**: All evidence includes timestamps and checksums
- **Tamper-proof**: Uses server-side timestamps and append-only logs
- **User-friendly**: Color-coded output, clear error messages
- **Production-ready**: Docker support, CI/CD, comprehensive docs

### Documentation
- Complete installation guide for Windows/Linux/macOS
- Troubleshooting guide with 15+ common issues
- API key setup instructions
- Docker quick start guide
- Contributing guidelines

### Technical
- Python 3.9+ compatible
- Bash 4.0+ compatible
- Requires: bash, curl, jq, yq, python3, PyYAML
- Optional: Docker, GitHub CLI

## [Unreleased]

### Planned
- Parallel GH Archive downloads for better performance
- Additional data sources (Docker Hub, npm registry, etc.)
- Web UI for report viewing
- More test coverage
- Performance optimizations

---

For upgrade instructions and migration guides, see [INSTALLATION.md](INSTALLATION.md).
