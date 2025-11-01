#!/usr/bin/env bash
# Wiz Planner Installation Script
# Downloads .cursor directory from the repository

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration defaults
REPO_URL="${WIZ_REPO_URL:-https://github.com/NSXBet/wiz-cursor.git}"
BRANCH="${WIZ_REPO_BRANCH:-main}"
REPO_API="${WIZ_REPO_API:-https://api.github.com/repos/NSXBet/wiz-cursor}"

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

# Parse command line arguments
# Usage: parse_args "$@"
# Sets global: VERSION
parse_args() {
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
        -h | --help)
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
}

# Fetch latest release from GitHub API
# Usage: fetch_latest_release
# Output: version tag or empty string
# Returns: 0 on success, 1 on failure
fetch_latest_release() {
    local api_url="$REPO_API/releases/latest"

    if ! command -v curl &>/dev/null; then
        return 1
    fi

    local api_response
    api_response=$(curl -sL -w "\n%{http_code}" "$api_url" 2>/dev/null || echo "")

    if [[ -z $api_response ]]; then
        return 1
    fi

    local http_code
    http_code=$(echo "$api_response" | tail -n1)
    local api_body
    api_body=$(echo "$api_response" | sed '$d')

    if [[ $http_code == "200" ]]; then
        local tag_name
        tag_name=$(echo "$api_body" | grep -o '"tag_name":"[^"]*' | cut -d'"' -f4)
        if [[ -n $tag_name ]]; then
            echo "$tag_name"
            return 0
        fi
    fi

    return 1
}

# Determine version to use
# Usage: determine_version [version]
# Sets global: VERSION, REF, REF_TYPE, REF_DISPLAY
determine_version() {
    local provided_version="${1:-}"

    if [[ -z $provided_version ]]; then
        info "No version specified, fetching latest stable release..."
        local latest_release
        latest_release=$(fetch_latest_release)

        if [[ -n $latest_release ]]; then
            VERSION="$latest_release"
            info "Latest release: $VERSION"
        else
            warning "Could not fetch latest release, falling back to main branch"
            VERSION="HEAD"
        fi
    else
        VERSION="$provided_version"
    fi

    # Determine ref to use (tag or branch)
    if [[ $VERSION == "HEAD" ]]; then
        REF="$BRANCH"
        REF_TYPE="branch"
        REF_DISPLAY="$BRANCH (HEAD)"
    else
        REF="$VERSION"
        REF_TYPE="tag"
        REF_DISPLAY="$VERSION"
    fi
}

# Check if Wiz is already installed
# Usage: check_wiz_installed
# Sets global: WIZ_INSTALLED (true/false)
check_wiz_installed() {
    WIZ_INSTALLED=false

    if [[ -d ".cursor/agents" ]] || [[ -d ".cursor/commands" ]]; then
        # Check if there are Wiz-specific files
        if [[ -n "$(find .cursor/agents -name 'wiz-*.md' 2>/dev/null 2>/dev/null)" ]] ||
            [[ -n "$(find .cursor/commands -name 'wiz-*.md' 2>/dev/null 2>/dev/null)" ]]; then
            WIZ_INSTALLED=true
        fi
    fi
}

# Clean up old Wiz files before update
# Usage: cleanup_old_wiz_files
cleanup_old_wiz_files() {
    rm -rf .cursor/agents/wiz-* .cursor/commands/wiz-* 2>/dev/null || true
}

# Extract owner and repo from GitHub URL
# Usage: extract_github_info <url>
# Output: owner repo (space-separated)
extract_github_info() {
    local url="$1"
    if [[ $url =~ github.com[:/]([^/]+)/([^/]+)\.git ]]; then
        echo "${BASH_REMATCH[1]} ${BASH_REMATCH[2]}"
        return 0
    fi
    return 1
}

# Build tarball URLs for GitHub repo
# Usage: build_tarball_urls <owner> <repo> <ref_type> <ref>
# Output: URLs separated by newlines
build_tarball_urls() {
    local owner="$1"
    local repo="$2"
    local ref_type="$3"
    local ref="$4"

    if [[ $ref_type == "tag" ]]; then
        echo "https://github.com/$owner/$repo/archive/refs/tags/$ref.tar.gz"
        echo "https://github.com/$owner/$repo/archive/$ref.tar.gz"
    else
        echo "https://github.com/$owner/$repo/archive/refs/heads/$ref.tar.gz"
        echo "https://github.com/$owner/$repo/archive/$ref.tar.gz"
    fi
}

# Install using git sparse checkout
# Usage: install_git_sparse_checkout <repo_url> <ref> <ref_type> <temp_dir>
# Returns: 0 on success, 1 on failure
install_git_sparse_checkout() {
    local repo_url="$1"
    local ref="$2"
    local ref_type="$3"
    local temp_dir="$4"

    info "Trying git sparse checkout method..."

    if [[ $ref_type == "tag" ]]; then
        # For tags, try cloning with tag as branch
        if git clone --branch "$ref" --filter=blob:none --sparse "$repo_url" "$temp_dir/repo" 2>/dev/null ||
            git clone --depth 1 --branch "$ref" --filter=blob:none --sparse "$repo_url" "$temp_dir/repo" 2>/dev/null; then
            cd "$temp_dir/repo"
            git checkout "$ref" 2>/dev/null || git checkout "tags/$ref" 2>/dev/null || true
            git sparse-checkout init --cone 2>/dev/null
            git sparse-checkout set .cursor 2>/dev/null
            cd - >/dev/null

            if [[ -d "$temp_dir/repo/.cursor" ]]; then
                return 0
            fi
        fi
    else
        # Clone with branch
        if git clone --depth 1 --branch "$ref" --filter=blob:none --sparse "$repo_url" "$temp_dir/repo" 2>/dev/null; then
            cd "$temp_dir/repo"
            git sparse-checkout init --cone 2>/dev/null
            git sparse-checkout set .cursor 2>/dev/null
            cd - >/dev/null

            if [[ -d "$temp_dir/repo/.cursor" ]]; then
                return 0
            fi
        fi
    fi

    return 1
}

# Copy .cursor directory from temp location
# Usage: copy_cursor_files <source_dir> <dest_dir>
# Returns: 0 on success, 1 on failure
copy_cursor_files() {
    local source_dir="$1"
    local dest_dir="${2:-.cursor}"

    if [[ ! -d $source_dir ]]; then
        return 1
    fi

    mkdir -p "$dest_dir"

    if [[ -d "$source_dir/agents" ]]; then
        cp -r "$source_dir/agents" "$dest_dir/"
    fi

    if [[ -d "$source_dir/commands" ]]; then
        cp -r "$source_dir/commands" "$dest_dir/"
    fi

    # Verify we copied something
    if [[ -d "$dest_dir/agents" ]] || [[ -d "$dest_dir/commands" ]]; then
        return 0
    fi

    return 1
}

# Install using tarball download
# Usage: install_tarball <repo_url> <ref> <ref_type> <temp_dir>
# Returns: 0 on success, 1 on failure
install_tarball() {
    local repo_url="$1"
    local ref="$2"
    local ref_type="$3"
    local temp_dir="$4"

    if [[ $repo_url != *"github.com"* ]]; then
        return 1
    fi

    local github_info
    github_info=$(extract_github_info "$repo_url")
    if [[ $? -ne 0 ]]; then
        return 1
    fi

    local owner repo
    read -r owner repo <<<"$github_info"

    info "Trying tarball download method..."

    local urls
    urls=$(build_tarball_urls "$owner" "$repo" "$ref_type" "$ref")

    if ! command -v curl &>/dev/null || ! command -v tar &>/dev/null; then
        return 1
    fi

    while IFS= read -r tarball_url; do
        info "Trying: $tarball_url"

        if curl -sL "$tarball_url" | tar -xz -C "$temp_dir" 2>/dev/null; then
            # Find .cursor directory in extracted tarball
            local cursor_dir
            cursor_dir=$(find "$temp_dir" -type d -name ".cursor" -path "*/$repo-*/.cursor" 2>/dev/null | head -1)

            if [[ -n $cursor_dir ]] && [[ -d $cursor_dir ]]; then
                if copy_cursor_files "$cursor_dir"; then
                    return 0
                fi
            fi
        fi
    done <<<"$urls"

    return 1
}

# Main installation function
# Usage: perform_installation <repo_url> <ref> <ref_type>
# Returns: 0 on success, 1 on failure
perform_installation() {
    local repo_url="$1"
    local ref="$2"
    local ref_type="$3"

    local temp_dir
    temp_dir=$(mktemp -d)
    trap "rm -rf $temp_dir" EXIT

    # Try git sparse checkout first
    if install_git_sparse_checkout "$repo_url" "$ref" "$ref_type" "$temp_dir"; then
        if copy_cursor_files "$temp_dir/repo/.cursor"; then
            rm -rf "$temp_dir"
            trap - EXIT
            return 0
        fi
    fi

    # Try tarball download as fallback
    if install_tarball "$repo_url" "$ref" "$ref_type" "$temp_dir"; then
        rm -rf "$temp_dir"
        trap - EXIT
        return 0
    fi

    rm -rf "$temp_dir"
    trap - EXIT
    return 1
}

# Main entry point
# Usage: main [args...]
main() {
    # Parse arguments
    parse_args "$@"

    # Determine version
    determine_version "$VERSION"

    # Check if already installed
    check_wiz_installed

    if [[ $WIZ_INSTALLED == "true" ]]; then
        warning "Wiz Planner is already installed!"
        info "Updating to version $REF_DISPLAY..."
        echo ""
        cleanup_old_wiz_files
    fi

    # Check prerequisites
    if ! command -v git &>/dev/null; then
        error "git is required but not installed. Please install git first."
        exit 1
    fi

    info "Installing Wiz Planner for Cursor..."
    info "Repository: $REPO_URL"
    info "Version: $REF_DISPLAY"
    echo ""

    # Perform installation
    if perform_installation "$REPO_URL" "$REF" "$REF_TYPE"; then
        if [[ $WIZ_INSTALLED == "true" ]]; then
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

    # Installation failed
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
    if [[ $REF_TYPE == "tag" ]]; then
        echo "  git clone --branch $REF --filter=blob:none --sparse $REPO_URL /tmp/wiz-install"
        echo "  cd /tmp/wiz-install && git checkout $REF && git sparse-checkout init --cone && git sparse-checkout set .cursor"
    else
        echo "  git clone --depth 1 --branch $REF --filter=blob:none --sparse $REPO_URL /tmp/wiz-install"
        echo "  cd /tmp/wiz-install && git sparse-checkout init --cone && git sparse-checkout set .cursor"
    fi
    echo "  cp -r .cursor /path/to/your/project && rm -rf /tmp/wiz-install"
    exit 1
}

# Only run main() if script is executed directly (not sourced for testing)
if [[ ${BASH_SOURCE[0]} == "${0}" ]]; then
    main "$@"
fi
