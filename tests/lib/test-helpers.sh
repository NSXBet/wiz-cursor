#!/usr/bin/env bash
# Common test helper functions for Wiz integration tests

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test counters (exported for use in test scripts)
export TESTS_RUN=0
export TESTS_PASSED=0
export TESTS_FAILED=0

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[PASS]${NC} $1"
    ((TESTS_PASSED++))
}

log_error() {
    echo -e "${RED}[FAIL]${NC} $1"
    ((TESTS_FAILED++))
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

# Increment test counter
increment_test() {
    ((TESTS_RUN++))
}

# Print test summary
print_test_summary() {
    echo ""
    log_info "Test Summary:"
    echo "  Tests run: $TESTS_RUN"
    echo "  Tests passed: $TESTS_PASSED"
    echo "  Tests failed: $TESTS_FAILED"
    
    if [[ $TESTS_FAILED -eq 0 ]]; then
        log_success "All tests passed!"
        return 0
    else
        log_error "Some tests failed"
        return 1
    fi
}

# Setup test environment
setup_test_env() {
    local test_slug="$1"
    local project_root="${2:-$(pwd)}"
    
    log_info "Setting up test environment for: $test_slug"
    
    # Create test .wiz directory
    mkdir -p "$project_root/.wiz/$test_slug"
    mkdir -p "$project_root/.wiz/context"
    
    echo "$project_root/.wiz/$test_slug"
}

# Cleanup test environment
cleanup_test_env() {
    local project_root="${1:-$(pwd)}"
    
    log_info "Cleaning up test artifacts..."
    find "$project_root" -type d -name ".wiz" -path "*/test-*" -exec rm -rf {} + 2>/dev/null || true
    rm -rf "$project_root/.wiz/context" 2>/dev/null || true
}

# Copy context file
copy_context_file() {
    local source_file="$1"
    local dest_dir="${2:-$(pwd)/.wiz/context}"
    
    mkdir -p "$dest_dir"
    cp "$source_file" "$dest_dir/"
    log_info "Copied context file: $(basename "$source_file")"
}

# Verify file exists
verify_file_exists() {
    local file="$1"
    
    if [[ -f "$file" ]]; then
        log_success "File exists: $file"
        return 0
    else
        log_error "File not found: $file"
        return 1
    fi
}

# Verify directory exists
verify_dir_exists() {
    local dir="$1"
    
    if [[ -d "$dir" ]]; then
        log_success "Directory exists: $dir"
        return 0
    else
        log_error "Directory not found: $dir"
        return 1
    fi
}

# Verify file contains text
verify_file_contains() {
    local file="$1"
    local text="$2"
    
    if [[ -f "$file" ]] && grep -q "$text" "$file"; then
        log_success "File contains expected text: $text"
        return 0
    else
        log_error "File does not contain expected text: $text"
        return 1
    fi
}

# Verify JSON file is valid
verify_json_valid() {
    local file="$1"
    
    if [[ -f "$file" ]] && command -v jq >/dev/null 2>&1; then
        if jq empty "$file" 2>/dev/null; then
            log_success "JSON file is valid: $file"
            return 0
        else
            log_error "JSON file is invalid: $file"
            return 1
        fi
    elif [[ -f "$file" ]]; then
        log_warn "jq not installed, skipping JSON validation"
        return 0
    else
        log_error "File not found: $file"
        return 1
    fi
}

# Get absolute path
abs_path() {
    local path="$1"
    cd "$(dirname "$path")" && pwd -P
}

# Find test fixtures directory
get_fixtures_dir() {
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    echo "$script_dir/../fixtures"
}

# Find project root
get_project_root() {
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    echo "$script_dir/../.."
}

