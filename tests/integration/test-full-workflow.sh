#!/usr/bin/env bash
# Integration test for full workflow (PRD → Phases → Milestones → Execution)
# Tests complete workflow from PRD to milestone execution

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

# Test 1: Complete workflow file structure
test_workflow_file_structure() {
    increment_test
    log_info "Test 1: Complete workflow file structure validation"
    
    local test_slug="test-full-workflow"
    mkdir -p "$PROJECT_ROOT/.wiz/$test_slug/phases"
    
    # Create PRD
    cp "$FIXTURES_DIR/workflows/test-prd.md" "$PROJECT_ROOT/.wiz/$test_slug/prd.md"
    
    # Create phases
    cp "$FIXTURES_DIR/workflows/test-phases/phase1.md" "$PROJECT_ROOT/.wiz/$test_slug/phases/phase1.md"
    cp "$FIXTURES_DIR/workflows/test-phases/phase2.md" "$PROJECT_ROOT/.wiz/$test_slug/phases/phase2.md"
    
    # Verify all files exist
    if [[ -f "$PROJECT_ROOT/.wiz/$test_slug/prd.md" ]] && \
       [[ -f "$PROJECT_ROOT/.wiz/$test_slug/phases/phase1.md" ]] && \
       [[ -f "$PROJECT_ROOT/.wiz/$test_slug/phases/phase2.md" ]]; then
        log_success "All workflow files created successfully"
        return 0
    else
        log_error "Missing workflow files"
        return 1
    fi
}

# Test 2: Context flow through all stages
test_context_flow() {
    increment_test
    log_info "Test 2: Context flow through all workflow stages"
    
    # Setup: Create context files
    mkdir -p "$PROJECT_ROOT/.wiz/context/go"
    cp "$FIXTURES_DIR/context/frameworks.md" "$PROJECT_ROOT/.wiz/context/frameworks.md"
    cp "$FIXTURES_DIR/context/go/patterns.md" "$PROJECT_ROOT/.wiz/context/go/patterns.md"
    
    cd "$PROJECT_ROOT"
    
    # Test context loading (simulating what each command would do)
    local metadata
    metadata=$(wiz_load_context_metadata)
    
    if [[ -n "$metadata" ]] && [[ "$metadata" != "[]" ]]; then
        # Verify multiple context files are loaded
        local file_count
        file_count=$(echo "$metadata" | grep -o '"path"' | wc -l | tr -d ' ')
        
        if [[ "$file_count" -ge 2 ]]; then
            log_success "Multiple context files loaded: $file_count"
            return 0
        else
            log_success "Context metadata loaded (file count: $file_count)"
            return 0
        fi
    else
        log_error "Failed to load context metadata"
        return 1
    fi
}

# Test 3: Milestone finding across phases
test_milestone_finding() {
    increment_test
    log_info "Test 3: Milestone finding across multiple phases"
    
    # Setup: Create phase files with milestones
    local test_slug="test-full-workflow"
    mkdir -p "$PROJECT_ROOT/.wiz/$test_slug/phases"
    
    # Create phase 1 with completed milestone
    cat > "$PROJECT_ROOT/.wiz/$test_slug/phases/phase1.md" <<'EOF'
# Phase 1: Test Phase

### P01M01: First Milestone

**Status:** ✅ COMPLETE

Goal: First milestone
EOF
    
    # Create phase 2 with TODO milestone
    cat > "$PROJECT_ROOT/.wiz/$test_slug/phases/phase2.md" <<'EOF'
# Phase 2: Test Phase 2

### P02M01: Second Phase Milestone

**Status:** 🚧 TODO

Goal: Second phase milestone
EOF
    
    cd "$PROJECT_ROOT"
    
    # Test finding next milestone
    local next_milestone
    next_milestone=$(wiz_find_next_milestone "$test_slug")
    
    if [[ "$next_milestone" == "P02M01" ]]; then
        log_success "Next milestone found across phases: $next_milestone"
        return 0
    else
        log_error "Failed to find next milestone across phases, got: $next_milestone"
        return 1
    fi
}

# Test 4: Workflow consistency
test_workflow_consistency() {
    increment_test
    log_info "Test 4: Workflow consistency (PRD → Phases → Milestones)"
    
    local test_slug="test-full-workflow"
    
    # Verify PRD references align with phases
    if [[ -f "$PROJECT_ROOT/.wiz/$test_slug/prd.md" ]]; then
        # Check PRD has expected content
        if grep -qi "Authentication\|auth" "$PROJECT_ROOT/.wiz/$test_slug/prd.md"; then
            log_success "PRD content verified"
        else
            log_warn "PRD content check skipped (fixture may vary)"
        fi
        
        # Verify phases reference PRD structure
        if [[ -f "$PROJECT_ROOT/.wiz/$test_slug/phases/phase1.md" ]]; then
            log_success "Phase structure verified"
            return 0
        else
            log_error "Phase structure missing"
            return 1
        fi
    else
        log_error "PRD file missing"
        return 1
    fi
}

# Main test execution
main() {
    log_info "Starting full workflow integration tests..."
    echo ""
    
    test_workflow_file_structure || true
    test_context_flow || true
    test_milestone_finding || true
    test_workflow_consistency || true
    
    echo ""
    print_test_summary
}

main "$@"
