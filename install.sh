#!/usr/bin/env bash
# ==============================================================================
# M&S Delivery Express Kabacan - One-Click Automated System Installer (Unix/macOS)
# ==============================================================================

set -e

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$PROJECT_ROOT"

# Ensure start.sh and install.sh are executable
chmod +x "$PROJECT_ROOT/start.sh" "$PROJECT_ROOT/install.sh" 2>/dev/null || true

# Prefer python3 / python for the installation runner
if command -v python3 >/dev/null 2>&1; then
  python3 "$PROJECT_ROOT/install.py" "$@"
elif command -v python >/dev/null 2>&1; then
  python "$PROJECT_ROOT/install.py" "$@"
else
  echo "[ERROR] Python 3 is required to run the installer, but was not found in PATH."
  echo "Please install Python 3.10+ (via brew install python@3.11 or from python.org) and try again."
  exit 1
fi
