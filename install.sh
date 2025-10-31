#!/usr/bin/env bash
set -euo pipefail

# Wiz Planner Installation Script
# Downloads .cursor directory from the repository

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
REPO_URL="${WIZ_REPO_URL:-https://github.com/NSXBet/wiz-cursor.git}"
BRANCH="${WIZ_BRANCH:-main}"

# Print colored messages
info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

success() {
    echo -e "${GREEN}✓${NC} $1"
}

warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

error() {
    echo -e "${RED}✗${NC} $1" >&2
}

# Check if .cursor directory already exists
if [[ -d ".cursor" ]]; then
    warning ".cursor directory already exists!"
    echo ""
    read -p "Do you want to overwrite it? (y/N): " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        info "Installation cancelled."
        exit 0
    fi
    info "Removing existing .cursor directory..."
    rm -rf .cursor
fi

# Check if git is available
if ! command -v git &> /dev/null; then
    error "git is required but not installed. Please install git first."
    exit 1
fi

info "Installing Wiz Planner for Cursor..."
info "Repository: $REPO_URL"
info "Branch: $BRANCH"
echo ""

# Create temporary directory
TEMP_DIR=$(mktemp -d)
trap "rm -rf $TEMP_DIR" EXIT

# Try multiple installation methods in sequence
INSTALLED=false

# Method 1: Git sparse checkout (most efficient, works for public/private repos with git access)
info "Trying git sparse checkout method..."
if git clone --depth 1 --branch "$BRANCH" --filter=blob:none --sparse "$REPO_URL" "$TEMP_DIR/repo" 2>/dev/null; then
    cd "$TEMP_DIR/repo"
    git sparse-checkout init --cone 2>/dev/null
    git sparse-checkout set .cursor 2>/dev/null
    cd - > /dev/null
    
    if [[ -d "$TEMP_DIR/repo/.cursor" ]]; then
        # Create .cursor directory
        mkdir -p .cursor
        # Copy only agents/ and commands/ directories
        if [[ -d "$TEMP_DIR/repo/.cursor/agents" ]]; then
            cp -r "$TEMP_DIR/repo/.cursor/agents" .cursor/
        fi
        if [[ -d "$TEMP_DIR/repo/.cursor/commands" ]]; then
            cp -r "$TEMP_DIR/repo/.cursor/commands" .cursor/
        fi
        INSTALLED=true
    fi
fi

# Method 2: Try downloading as tarball (if Method 1 failed and it's a GitHub repo)
if [[ "$INSTALLED" == "false" ]] && [[ "$REPO_URL" == *"github.com"* ]]; then
    # Extract owner and repo from URL
    if [[ "$REPO_URL" =~ github.com[:/]([^/]+)/([^/]+)\.git ]]; then
        OWNER="${BASH_REMATCH[1]}"
        REPO="${BASH_REMATCH[2]}"
        
        info "Trying tarball download method..."
        
        # Try multiple tarball URL formats
        TARBALL_URLS=(
            "https://github.com/$OWNER/$REPO/archive/refs/heads/$BRANCH.tar.gz"
            "https://github.com/$OWNER/$REPO/archive/$BRANCH.tar.gz"
        )
        
        for TARBALL_URL in "${TARBALL_URLS[@]}"; do
            if command -v curl &> /dev/null && command -v tar &> /dev/null; then
                info "Trying: $TARBALL_URL"
                if curl -sL "$TARBALL_URL" | tar -xz -C "$TEMP_DIR" 2>/dev/null; then
                    # Find .cursor directory in extracted tarball
                    CURSOR_DIR=$(find "$TEMP_DIR" -type d -name ".cursor" -path "*/$REPO-*/.cursor" 2>/dev/null | head -1)
                    if [[ -n "$CURSOR_DIR" ]] && [[ -d "$CURSOR_DIR" ]]; then
                        # Create .cursor directory
                        mkdir -p .cursor
                        # Copy only agents/ and commands/ directories
                        if [[ -d "$CURSOR_DIR/agents" ]]; then
                            cp -r "$CURSOR_DIR/agents" .cursor/
                        fi
                        if [[ -d "$CURSOR_DIR/commands" ]]; then
                            cp -r "$CURSOR_DIR/commands" .cursor/
                        fi
                        INSTALLED=true
                        break
                    fi
                fi
            fi
        done
    fi
fi

# Success!
if [[ "$INSTALLED" == "true" ]]; then
    success "Wiz Planner installed successfully!"
    echo ""
    info "Next steps:"
    echo "  1. Open your project in Cursor 2.0+"
    echo "  2. Use Composer1 (recommended) for best experience"
    echo "  3. Run /wiz-prd to get started"
    echo ""
    info "For documentation, see: https://github.com/NSXBet/wiz-cursor"
    exit 0
fi

# All methods failed
error "Failed to download .cursor directory"
echo ""
error "Tried multiple installation methods but all failed."
echo ""
error "Possible reasons:"
echo "  - Network connectivity issues"
echo "  - Repository URL is incorrect"
echo "  - Repository is private and requires authentication"
echo ""
info "Try manual installation instead:"
echo "  1. Clone or download the repository"
echo "  2. Copy the .cursor directory to your project root"
echo ""
info "Manual installation command:"
echo "  git clone --depth 1 --branch $BRANCH --filter=blob:none --sparse $REPO_URL /tmp/wiz-install"
echo "  cd /tmp/wiz-install && git sparse-checkout init --cone && git sparse-checkout set .cursor"
echo "  cp -r .cursor /path/to/your/project && rm -rf /tmp/wiz-install"
exit 1

