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
BRANCH="${WIZ_REPO_BRANCH:-main}"
REPO_API="https://api.github.com/repos/NSXBet/wiz-cursor"

# Parse command line arguments
VERSION=""
while [[ $# -gt 0 ]]; do
    case $1 in
        --version)
            VERSION="$2"
            shift 2
            ;;
        --version=*)
            VERSION="${1#*=}"
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [--version VERSION]"
            echo ""
            echo "Options:"
            echo "  --version VERSION    Install specific version (e.g., 0.1.2)"
            echo "                      Use 'HEAD' for latest main branch"
            echo "                      Omit to use latest stable release"
            echo "  -h, --help          Show this help message"
            exit 0
            ;;
        *)
            error "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

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

# Determine version/tag to use
if [[ -z "$VERSION" ]]; then
    # No version specified - fetch latest release
    info "No version specified, fetching latest stable release..."
    if command -v curl &> /dev/null; then
        LATEST_RELEASE=$(curl -sL "$REPO_API/releases/latest" | grep -o '"tag_name":"[^"]*' | cut -d'"' -f4)
        if [[ -n "$LATEST_RELEASE" ]]; then
            VERSION="$LATEST_RELEASE"
            info "Latest release: $VERSION"
        else
            warning "Could not fetch latest release, falling back to main branch"
            VERSION="HEAD"
        fi
    else
        warning "curl not available, cannot fetch latest release. Using main branch."
        VERSION="HEAD"
    fi
fi

# Determine ref to use (tag or branch)
if [[ "$VERSION" == "HEAD" ]]; then
    REF="$BRANCH"
    REF_TYPE="branch"
    REF_DISPLAY="$BRANCH (HEAD)"
else
    REF="$VERSION"
    REF_TYPE="tag"
    REF_DISPLAY="$VERSION"
fi

# Check if Wiz is already installed (not just .cursor directory)
WIZ_INSTALLED=false
if [[ -d ".cursor/agents" ]] || [[ -d ".cursor/commands" ]]; then
    # Check if there are Wiz-specific files
    if [[ -n "$(find .cursor/agents -name 'wiz-*.md' 2>/dev/null)" ]] || \
       [[ -n "$(find .cursor/commands -name 'wiz-*.md' 2>/dev/null)" ]]; then
        WIZ_INSTALLED=true
    fi
fi

if [[ "$WIZ_INSTALLED" == "true" ]]; then
    warning "Wiz Planner is already installed!"
    info "Updating to version $REF_DISPLAY..."
    echo ""
    # Remove only Wiz-specific files for clean update
    rm -rf .cursor/agents/wiz-* .cursor/commands/wiz-* 2>/dev/null || true
fi

# Check if git is available
if ! command -v git &> /dev/null; then
    error "git is required but not installed. Please install git first."
    exit 1
fi

info "Installing Wiz Planner for Cursor..."
info "Repository: $REPO_URL"
info "Version: $REF_DISPLAY"
echo ""

# Create temporary directory
TEMP_DIR=$(mktemp -d)
trap "rm -rf $TEMP_DIR" EXIT

# Try multiple installation methods in sequence
INSTALLED=false

# Method 1: Git sparse checkout (most efficient, works for public/private repos with git access)
info "Trying git sparse checkout method..."
if [[ "$REF_TYPE" == "tag" ]]; then
    # For tags, clone with the tag as branch (git supports this)
    # We need to fetch tags explicitly or clone without depth restriction for tags
    if git clone --branch "$REF" --filter=blob:none --sparse "$REPO_URL" "$TEMP_DIR/repo" 2>/dev/null || \
       git clone --depth 1 --branch "$REF" --filter=blob:none --sparse "$REPO_URL" "$TEMP_DIR/repo" 2>/dev/null; then
        cd "$TEMP_DIR/repo"
        # Verify we're on the right tag
        git checkout "$REF" 2>/dev/null || git checkout "tags/$REF" 2>/dev/null || true
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
else
    # Clone with branch (HEAD)
    if git clone --depth 1 --branch "$REF" --filter=blob:none --sparse "$REPO_URL" "$TEMP_DIR/repo" 2>/dev/null; then
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
fi

# Method 2: Try downloading as tarball (if Method 1 failed and it's a GitHub repo)
if [[ "$INSTALLED" == "false" ]] && [[ "$REPO_URL" == *"github.com"* ]]; then
    # Extract owner and repo from URL
    if [[ "$REPO_URL" =~ github.com[:/]([^/]+)/([^/]+)\.git ]]; then
        OWNER="${BASH_REMATCH[1]}"
        REPO="${BASH_REMATCH[2]}"
        
        info "Trying tarball download method..."
        
        # Determine tarball URL based on ref type
        if [[ "$REF_TYPE" == "tag" ]]; then
            # For tags, use the tag name
            TARBALL_URLS=(
                "https://github.com/$OWNER/$REPO/archive/refs/tags/$REF.tar.gz"
                "https://github.com/$OWNER/$REPO/archive/$REF.tar.gz"
            )
        else
            # For branches, use branch name
            TARBALL_URLS=(
                "https://github.com/$OWNER/$REPO/archive/refs/heads/$REF.tar.gz"
                "https://github.com/$OWNER/$REPO/archive/$REF.tar.gz"
            )
        fi
        
        for TARBALL_URL in "${TARBALL_URLS[@]}"; do
            if command -v curl &> /dev/null && command -v tar &> /dev/null; then
                info "Trying: $TARBALL_URL"
                if curl -sL "$TARBALL_URL" | tar -xz -C "$TEMP_DIR" 2>/dev/null; then
                    # Find .cursor directory in extracted tarball
                    # Tag tarballs have format: repo-tag_name, branch tarballs have format: repo-branch_name
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
    if [[ "$WIZ_INSTALLED" == "true" ]]; then
        success "Wiz Planner updated successfully to version $REF_DISPLAY!"
    else
        success "Wiz Planner installed successfully (version $REF_DISPLAY)!"
    fi
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
if [[ "$REF_TYPE" == "tag" ]]; then
    echo "  git clone --branch $REF --filter=blob:none --sparse $REPO_URL /tmp/wiz-install"
    echo "  cd /tmp/wiz-install && git checkout $REF && git sparse-checkout init --cone && git sparse-checkout set .cursor"
else
    echo "  git clone --depth 1 --branch $REF --filter=blob:none --sparse $REPO_URL /tmp/wiz-install"
    echo "  cd /tmp/wiz-install && git sparse-checkout init --cone && git sparse-checkout set .cursor"
fi
echo "  cp -r .cursor /path/to/your/project && rm -rf /tmp/wiz-install"
exit 1

