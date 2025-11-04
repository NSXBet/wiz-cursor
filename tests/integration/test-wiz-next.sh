#!/usr/bin/env bash
# Integration test for /wiz-next command
# Tests milestone execution with context integration and quality gates

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
TESTS_DIR="$SCRIPT_DIR/.."
FIXTURES_DIR="$TESTS_DIR/fixtures"
LIB_DIR="$TESTS_DIR/lib"

# Source test helpers and wiz functions
source "$LIB_DIR/test-helpers.sh"
source "$LIB_DIR/wiz-functions.sh"
source "$LIB_DIR/milestone-functions.sh"

# Cleanup function
cleanup() {
    log_info "Cleaning up test artifacts..."
    find "$PROJECT_ROOT" -type d -name ".wiz" -path "*/test-*" -exec rm -rf {} + 2>/dev/null || true
    rm -rf "$PROJECT_ROOT/.wiz/context" 2>/dev/null || true
}

trap cleanup EXIT

# Test 1: Milestone status extraction
test_milestone_status_extraction() {
    increment_test
    log_info "Test 1: Milestone status extraction"
    
    # Test TODO status
    local status
    status=$(wiz_extract_milestone_status "**Status:** 🚧 TODO")
    if [[ "$status" == "todo" ]]; then
        log_success "TODO status extracted correctly"
    else
        log_error "Failed to extract TODO status, got: $status"
        return 1
    fi
    
    # Test COMPLETE status
    status=$(wiz_extract_milestone_status "**Status:** ✅ COMPLETE")
    if [[ "$status" == "complete" ]]; then
        log_success "COMPLETE status extracted correctly"
    else
        log_error "Failed to extract COMPLETE status, got: $status"
        return 1
    fi
    
    # Test IN PROGRESS status
    status=$(wiz_extract_milestone_status "**Status:** 🏗️ IN PROGRESS")
    if [[ "$status" == "in_progress" ]]; then
        log_success "IN PROGRESS status extracted correctly"
    else
        log_error "Failed to extract IN PROGRESS status, got: $status"
        return 1
    fi
    
    return 0
}

# Test 2: Finding next TODO milestone
test_find_next_milestone() {
    increment_test
    log_info "Test 2: Finding next TODO milestone"
    
    # Setup: Create test phase files with milestones
    local test_slug="test-next"
    mkdir -p "$PROJECT_ROOT/.wiz/$test_slug/phases"
    
    # Create phase file with milestones
    cat > "$PROJECT_ROOT/.wiz/$test_slug/phases/phase1.md" <<'EOF'
# Phase 1: Test Phase

### P01M01: First Milestone

**Status:** ✅ COMPLETE

Goal: First milestone

### P01M02: Second Milestone

**Status:** 🚧 TODO

Goal: Second milestone
EOF
    
    cd "$PROJECT_ROOT"
    
    # Test finding next milestone
    local next_milestone
    next_milestone=$(wiz_find_next_milestone "$test_slug")
    
    if [[ "$next_milestone" == "P01M02" ]]; then
        log_success "Next milestone found correctly: $next_milestone"
        return 0
    else
        log_error "Failed to find next milestone, got: $next_milestone"
        return 1
    fi
}

# Test 3: Context loading for execution
test_execution_context_loading() {
    increment_test
    log_info "Test 3: Context loading for milestone execution"
    
    # Setup: Create context directory
    mkdir -p "$PROJECT_ROOT/.wiz/context"
    cp "$FIXTURES_DIR/context/frameworks.md" "$PROJECT_ROOT/.wiz/context/frameworks.md"
    
    cd "$PROJECT_ROOT"
    
    # Test metadata loading
    local metadata
    metadata=$(wiz_load_context_metadata)
    
    if [[ -n "$metadata" ]] && [[ "$metadata" != "[]" ]]; then
        log_success "Context metadata loaded for execution"
        return 0
    else
        log_error "Failed to load context metadata"
        return 1
    fi
}

# Test 4: PRD and phase file validation
test_prd_phase_validation() {
    increment_test
    log_info "Test 4: PRD and phase file validation"
    
    # Setup: Create test PRD and phases
    local test_slug="test-next"
    mkdir -p "$PROJECT_ROOT/.wiz/$test_slug/phases"
    
    # Create PRD file
    cp "$FIXTURES_DIR/workflows/test-prd.md" "$PROJECT_ROOT/.wiz/$test_slug/prd.md"
    
    # Create phase file
    cp "$FIXTURES_DIR/workflows/test-phases/phase1.md" "$PROJECT_ROOT/.wiz/$test_slug/phases/phase1.md"
    
    # Verify PRD exists
    if [[ ! -f "$PROJECT_ROOT/.wiz/$test_slug/prd.md" ]]; then
        log_error "PRD file not found"
        return 1
    fi
    
    # Verify phase file exists
    if [[ ! -f "$PROJECT_ROOT/.wiz/$test_slug/phases/phase1.md" ]]; then
        log_error "Phase file not found"
        return 1
    fi
    
    log_success "PRD and phase files validated"
    return 0
}

# Main test execution
main() {
    log_info "Starting /wiz-next integration tests..."
    echo ""
    
    test_milestone_status_extraction || true
    test_find_next_milestone || true
    test_execution_context_loading || true
    test_prd_phase_validation || true
    
    echo ""
    print_test_summary
}

main "$@"
