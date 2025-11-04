#!/usr/bin/env bash
# Integration test for /wiz-prd command
# Tests PRD generation with context integration

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
TESTS_DIR="$SCRIPT_DIR/.."
FIXTURES_DIR="$TESTS_DIR/fixtures"
LIB_DIR="$TESTS_DIR/lib"

# Source test helpers and wiz functions
source "$LIB_DIR/test-helpers.sh"
source "$LIB_DIR/wiz-functions.sh"

# Cleanup function
cleanup() {
    log_info "Cleaning up test artifacts..."
    find "$PROJECT_ROOT" -type d -name ".wiz" -path "*/test-*" -exec rm -rf {} + 2>/dev/null || true
    rm -rf "$PROJECT_ROOT/.wiz/context" 2>/dev/null || true
}

trap cleanup EXIT

# Test 1: Context metadata loading
test_context_metadata_loading() {
    increment_test
    log_info "Test 1: Context metadata loading"
    
    # Setup: Create context directory with framework file
    mkdir -p "$PROJECT_ROOT/.wiz/context"
    cp "$FIXTURES_DIR/context/frameworks.md" "$PROJECT_ROOT/.wiz/context/frameworks.md"
    
    # Change to project root to test function
    cd "$PROJECT_ROOT"
    
    # Test metadata loading
    local metadata
    metadata=$(wiz_load_context_metadata)
    
    if [[ -n "$metadata" ]]; then
        log_success "Context metadata loaded successfully"
        
        # Verify metadata contains expected content
        if echo "$metadata" | grep -q "frameworks.md"; then
            log_success "Metadata contains expected file path"
        else
            log_error "Metadata missing expected file path"
            return 1
        fi
        return 0
    else
        log_error "Failed to load context metadata"
        return 1
    fi
}

# Test 2: Context file loading
test_context_file_loading() {
    increment_test
    log_info "Test 2: Context file loading (without frontmatter)"
    
    # Setup: Ensure context file exists
    mkdir -p "$PROJECT_ROOT/.wiz/context"
    cp "$FIXTURES_DIR/context/frameworks.md" "$PROJECT_ROOT/.wiz/context/frameworks.md"
    
    cd "$PROJECT_ROOT"
    
    # Test file loading
    local content
    content=$(wiz_load_context_file "frameworks.md")
    
    if [[ -n "$content" ]]; then
        log_success "Context file loaded successfully"
        
        # Verify frontmatter was removed
        if echo "$content" | grep -q "^---"; then
            log_error "Frontmatter not removed from content"
            return 1
        fi
        
        # Verify actual content is present
        if echo "$content" | grep -q "FastAPI"; then
            log_success "File content contains expected text"
        else
            log_error "File content missing expected text"
            return 1
        fi
        return 0
    else
        log_error "Failed to load context file"
        return 1
    fi
}

# Test 3: Empty context directory
test_empty_context() {
    increment_test
    log_info "Test 3: Empty context directory handling"
    
    # Ensure no context files exist
    rm -rf "$PROJECT_ROOT/.wiz/context" 2>/dev/null || true
    
    cd "$PROJECT_ROOT"
    
    # Test metadata loading with empty directory
    local metadata
    metadata=$(wiz_load_context_metadata)
    
    if [[ "$metadata" == "[]" ]]; then
        log_success "Empty context returns empty array"
        return 0
    else
        log_error "Empty context should return []"
        return 1
    fi
}

# Test 4: Codebase analysis (language detection)
test_codebase_analysis() {
    increment_test
    log_info "Test 4: Codebase language detection"
    
    # Setup: Create a test Go project
    local test_project="$PROJECT_ROOT/tests/fixtures/codebases/go-project"
    cd "$test_project"
    
    # Count Go files
    local go_files
    go_files=$(find . -name "*.go" -not -path "*/.git/*" 2>/dev/null | wc -l | tr -d ' ')
    
    if [[ "$go_files" -gt 0 ]]; then
        log_success "Go files detected: $go_files"
        return 0
    else
        log_error "No Go files detected"
        return 1
    fi
}

# Test 5: Context file with nested path
test_nested_context() {
    increment_test
    log_info "Test 5: Nested context file handling"
    
    # Setup: Create nested context directory
    mkdir -p "$PROJECT_ROOT/.wiz/context/go"
    cp "$FIXTURES_DIR/context/go/patterns.md" "$PROJECT_ROOT/.wiz/context/go/patterns.md"
    
    cd "$PROJECT_ROOT"
    
    # Test loading nested file
    local content
    content=$(wiz_load_context_file "go/patterns.md")
    
    if [[ -n "$content" ]]; then
        log_success "Nested context file loaded successfully"
        
        # Verify content
        if echo "$content" | grep -q "Go"; then
            log_success "Nested file content verified"
        else
            log_error "Nested file content missing expected text"
            return 1
        fi
        return 0
    else
        log_error "Failed to load nested context file"
        return 1
    fi
}

# Main test execution
main() {
    log_info "Starting /wiz-prd integration tests..."
    echo ""
    
    test_context_metadata_loading || true
    test_context_file_loading || true
    test_empty_context || true
    test_codebase_analysis || true
    test_nested_context || true
    
    echo ""
    print_test_summary
}

main "$@"
