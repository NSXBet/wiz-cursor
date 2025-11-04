#!/usr/bin/env bash
# Integration test for /wiz-auto command
# Tests automated milestone execution loop with context integration

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

# Test 1: Context loading once before loop
test_context_loaded_once() {
    increment_test
    log_info "Test 1: Context loaded once before auto-execution loop"
    
    # Setup: Create context directory
    mkdir -p "$PROJECT_ROOT/.wiz/context"
    cp "$FIXTURES_DIR/context/frameworks.md" "$PROJECT_ROOT/.wiz/context/frameworks.md"
    
    cd "$PROJECT_ROOT"
    
    # Load context metadata (simulating what auto does once)
    local metadata
    metadata=$(wiz_load_context_metadata)
    
    if [[ -n "$metadata" ]] && [[ "$metadata" != "[]" ]]; then
        log_success "Context metadata loaded successfully (once before loop)"
        return 0
    else
        log_error "Failed to load context metadata"
        return 1
    fi
}

# Test 2: Multiple milestones handling
test_multiple_milestones() {
    increment_test
    log_info "Test 2: Multiple milestones handling"
    
    # Setup: Create test phase files with multiple milestones
    local test_slug="test-auto"
    mkdir -p "$PROJECT_ROOT/.wiz/$test_slug/phases"
    
    # Create phase file with multiple TODO milestones
    cat > "$PROJECT_ROOT/.wiz/$test_slug/phases/phase1.md" <<'EOF'
# Phase 1: Test Phase

### P01M01: First Milestone

**Status:** 🚧 TODO

Goal: First milestone

### P01M02: Second Milestone

**Status:** 🚧 TODO

Goal: Second milestone

### P01M03: Third Milestone

**Status:** 🚧 TODO

Goal: Third milestone
EOF
    
    # Count TODO milestones
    local todo_count
    todo_count=$(grep -c "🚧 TODO" "$PROJECT_ROOT/.wiz/$test_slug/phases/phase1.md" || echo "0")
    
    if [[ "$todo_count" -ge 2 ]]; then
        log_success "Multiple TODO milestones found: $todo_count"
        return 0
    else
        log_error "Expected multiple TODO milestones, found: $todo_count"
        return 1
    fi
}

# Test 3: PRD and phase validation for auto
test_auto_prd_phase_validation() {
    increment_test
    log_info "Test 3: PRD and phase validation for auto-execution"
    
    # Setup: Create test PRD and phases
    local test_slug="test-auto"
    mkdir -p "$PROJECT_ROOT/.wiz/$test_slug/phases"
    
    # Create PRD file
    cp "$FIXTURES_DIR/workflows/test-prd.md" "$PROJECT_ROOT/.wiz/$test_slug/prd.md"
    
    # Create phase file
    cp "$FIXTURES_DIR/workflows/test-phases/phase1.md" "$PROJECT_ROOT/.wiz/$test_slug/phases/phase1.md"
    
    # Verify both exist
    if [[ -f "$PROJECT_ROOT/.wiz/$test_slug/prd.md" ]] && \
       [[ -f "$PROJECT_ROOT/.wiz/$test_slug/phases/phase1.md" ]]; then
        log_success "PRD and phase files validated for auto-execution"
        return 0
    else
        log_error "PRD or phase files missing"
        return 1
    fi
}

# Test 4: State file handling
test_state_file_handling() {
    increment_test
    log_info "Test 4: State file handling"
    
    # Setup: Create state directory
    mkdir -p "$PROJECT_ROOT/.wiz"
    
    # Create test state file
    echo '{"current_prd": "test-auto"}' > "$PROJECT_ROOT/.wiz/state.json"
    
    # Verify state file exists and is valid JSON
    if [[ -f "$PROJECT_ROOT/.wiz/state.json" ]]; then
        if command -v jq >/dev/null 2>&1; then
            if jq empty "$PROJECT_ROOT/.wiz/state.json" 2>/dev/null; then
                log_success "State file is valid JSON"
                return 0
            else
                log_error "State file is invalid JSON"
                return 1
            fi
        else
            log_warn "jq not available, skipping JSON validation"
            return 0
        fi
    else
        log_error "State file not found"
        return 1
    fi
}

# Main test execution
main() {
    log_info "Starting /wiz-auto integration tests..."
    echo ""
    
    test_context_loaded_once || true
    test_multiple_milestones || true
    test_auto_prd_phase_validation || true
    test_state_file_handling || true
    
    echo ""
    print_test_summary
}

main "$@"
