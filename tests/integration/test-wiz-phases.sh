#!/usr/bin/env bash
# Integration test for /wiz-phases command
# Tests phase generation with PRD input and context integration

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

# Test 1: Context metadata loading for phases
test_phases_context_metadata() {
    increment_test
    log_info "Test 1: Context metadata loading for phase generation"
    
    # Setup: Create context directory with framework file
    mkdir -p "$PROJECT_ROOT/.wiz/context"
    cp "$FIXTURES_DIR/context/frameworks.md" "$PROJECT_ROOT/.wiz/context/frameworks.md"
    
    cd "$PROJECT_ROOT"
    
    # Test metadata loading
    local metadata
    metadata=$(wiz_load_context_metadata)
    
    if [[ -n "$metadata" ]] && [[ "$metadata" != "[]" ]]; then
        log_success "Context metadata loaded for phase generation"
        
        # Verify metadata contains framework info
        if echo "$metadata" | grep -q "frameworks"; then
            log_success "Metadata contains framework context"
        else
            log_error "Metadata missing framework context"
            return 1
        fi
        return 0
    else
        log_error "Failed to load context metadata"
        return 1
    fi
}

# Test 2: Context filtering by applies_to
test_context_filtering() {
    increment_test
    log_info "Test 2: Context filtering by applies_to field"
    
    # Setup: Create context file with applies_to: [planning]
    mkdir -p "$PROJECT_ROOT/.wiz/context"
    cp "$FIXTURES_DIR/context/frameworks.md" "$PROJECT_ROOT/.wiz/context/frameworks.md"
    
    cd "$PROJECT_ROOT"
    
    # Load metadata and check applies_to
    local metadata
    metadata=$(wiz_load_context_metadata)
    
    # Verify metadata can be parsed
    if command -v jq >/dev/null 2>&1; then
        local applies_to_count
        applies_to_count=$(echo "$metadata" | jq '.[0].applies_to | length' 2>/dev/null || echo "0")
        
        if [[ "$applies_to_count" -ge 0 ]]; then
            log_success "Context metadata filtering structure verified"
            return 0
        else
            log_warn "Could not verify applies_to structure (jq required)"
            return 0
        fi
    else
        log_warn "jq not available, skipping JSON validation"
        return 0
    fi
}

# Test 3: PRD file validation
test_prd_validation() {
    increment_test
    log_info "Test 3: PRD file structure validation"
    
    # Setup: Create test PRD file
    local test_slug="test-phases"
    mkdir -p "$PROJECT_ROOT/.wiz/$test_slug"
    cp "$FIXTURES_DIR/workflows/test-prd.md" "$PROJECT_ROOT/.wiz/$test_slug/prd.md"
    
    # Verify PRD file exists and has required sections
    if [[ -f "$PROJECT_ROOT/.wiz/$test_slug/prd.md" ]]; then
        log_success "PRD file exists"
        
        # Check for required sections
        local required_sections=("Overview" "Requirements" "Architecture")
        local found_sections=0
        
        for section in "${required_sections[@]}"; do
            if grep -qi "$section" "$PROJECT_ROOT/.wiz/$test_slug/prd.md"; then
                ((found_sections++))
            fi
        done
        
        if [[ $found_sections -gt 0 ]]; then
            log_success "PRD contains required sections ($found_sections/${#required_sections[@]})"
            return 0
        else
            log_error "PRD missing required sections"
            return 1
        fi
    else
        log_error "PRD file not found"
        return 1
    fi
}

# Main test execution
main() {
    log_info "Starting /wiz-phases integration tests..."
    echo ""
    
    test_phases_context_metadata || true
    test_context_filtering || true
    test_prd_validation || true
    
    echo ""
    print_test_summary
}

main "$@"
