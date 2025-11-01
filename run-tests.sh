#!/usr/bin/env bash
# Test runner using bats-core
# Install bats-core: https://github.com/bats-core/bats-core

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Check if bats is installed
if ! command -v bats &>/dev/null; then
    echo "Error: bats-core is not installed."
    echo ""
    echo "Install bats-core:"
    echo "  macOS: brew install bats-core"
    echo "  Linux: See https://github.com/bats-core/bats-core#installation"
    echo ""
    exit 1
fi

echo "=========================================="
echo "Wiz Installer Test Suite (bats-core)"
echo "=========================================="
echo ""

# Run tests
bats "$SCRIPT_DIR/test-install.bats"
