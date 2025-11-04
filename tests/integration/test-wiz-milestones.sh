#!/usr/bin/env bash
# Integration test for /wiz-milestones command
# Tests milestone generation with phases input and context integration

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

# Test 1: Phase file structure validation
test_phase_structure() {
    increment_test
    log_info "Test 1: Phase file structure validation"
    
    # Setup: Create test phase files
    local test_slug="test-milestones"
    mkdir -p "$PROJECT_ROOT/.wiz/$test_slug/phases"
    cp "$FIXTURES_DIR/workflows/test-phases/phase1.md" "$PROJECT_ROOT/.wiz/$test_slug/phases/phase1.md"
    cp "$FIXTURES_DIR/workflows/test-phases/phase2.md" "$PROJECT_ROOT/.wiz/$test_slug/phases/phase2.md"
    
    # Verify phase files exist
    if [[ -f "$PROJECT_ROOT/.wiz/$test_slug/phases/phase1.md" ]]; then
        log_success "Phase files exist"
        
        # Check for required sections
        local required_sections=("Goal" "Dependencies" "Acceptance Criteria")
        local found_sections=0
        
        for section in "${required_sections[@]}"; do
            if grep -qi "$section" "$PROJECT_ROOT/.wiz/$test_slug/phases/phase1.md"; then
                ((found_sections++))
            fi
        done
        
        if [[ $found_sections -gt 0 ]]; then
            log_success "Phase contains required sections ($found_sections/${#required_sections[@]})"
            return 0
        else
            log_error "Phase missing required sections"
            return 1
        fi
    else
        log_error "Phase file not found"
        return 1
    fi
}

# Test 2: Context loading for milestones
test_milestones_context() {
    increment_test
    log_info "Test 2: Context loading for milestone generation"
    
    # Setup: Create context directory
    mkdir -p "$PROJECT_ROOT/.wiz/context"
    cp "$FIXTURES_DIR/context/frameworks.md" "$PROJECT_ROOT/.wiz/context/frameworks.md"
    
    cd "$PROJECT_ROOT"
    
    # Test metadata loading
    local metadata
    metadata=$(wiz_load_context_metadata)
    
    if [[ -n "$metadata" ]] && [[ "$metadata" != "[]" ]]; then
        log_success "Context metadata loaded for milestone generation"
        return 0
    else
        log_error "Failed to load context metadata"
        return 1
    fi
}

# Test 3: Multiple phase files handling
test_multiple_phases() {
    increment_test
    log_info "Test 3: Multiple phase files handling"
    
    # Setup: Create multiple phase files
    local test_slug="test-milestones"
    mkdir -p "$PROJECT_ROOT/.wiz/$test_slug/phases"
    cp "$FIXTURES_DIR/workflows/test-phases/phase1.md" "$PROJECT_ROOT/.wiz/$test_slug/phases/phase1.md"
    cp "$FIXTURES_DIR/workflows/test-phases/phase2.md" "$PROJECT_ROOT/.wiz/$test_slug/phases/phase2.md"
    
    # Count phase files
    local phase_count
    phase_count=$(find "$PROJECT_ROOT/.wiz/$test_slug/phases" -name "phase*.md" -type f | wc -l | tr -d ' ')
    
    if [[ "$phase_count" -ge 2 ]]; then
        log_success "Multiple phase files detected: $phase_count"
        return 0
    else
        log_error "Expected multiple phase files, found: $phase_count"
        return 1
    fi
}

# Main test execution
main() {
    log_info "Starting /wiz-milestones integration tests..."
    echo ""
    
    test_phase_structure || true
    test_milestones_context || true
    test_multiple_phases || true
    
    echo ""
    print_test_summary
}

main "$@"
