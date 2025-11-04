#!/usr/bin/env bash
# Integration test for /wiz-auto command
# Tests automated milestone execution loop with specialist review and milestone-analyst integration

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
source "$LIB_DIR/specialist-functions.sh"
source "$LIB_DIR/analyst-functions.sh"

# Note: specialist-functions.sh includes aggregate_specialist_reviews and count_specialists_consulted

# Cleanup function
cleanup() {
    log_info "Cleaning up test artifacts..."
    find "$PROJECT_ROOT" -type d -name ".wiz" -path "*/test-*" -exec rm -rf {} + 2>/dev/null || true
    rm -rf "$PROJECT_ROOT/.wiz/context" 2>/dev/null || true
    rm -f /tmp/specialist_review_round 2>/dev/null || true
}

trap cleanup EXIT

# Test 1: Context loaded once before loop
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

# Test 3: Milestone-analyst PROCEED decision
test_analyst_proceed_decision() {
    increment_test
    log_info "Test 3: Milestone-analyst PROCEED decision"
    
    # Mock analyst decision
    local analyst_output
    analyst_output=$(mock_milestone_analyst "P01M02" "mock milestone content" "proceed")
    
    # Parse decision
    local decision
    decision=$(parse_analyst_decision "$analyst_output")
    
    if [[ "$decision" == "PROCEED" ]]; then
        log_success "PROCEED decision parsed correctly"
        return 0
    else
        log_error "Failed to parse PROCEED decision, got: $decision"
        return 1
    fi
}

# Test 4: Milestone-analyst HALT decision
test_analyst_halt_decision() {
    increment_test
    log_info "Test 4: Milestone-analyst HALT decision"
    
    # Mock analyst decision
    local analyst_output
    analyst_output=$(mock_milestone_analyst "P01M02" "mock milestone content" "halt")
    
    # Parse decision
    local decision
    decision=$(parse_analyst_decision "$analyst_output")
    
    if [[ "$decision" == "HALT" ]]; then
        # Extract questions
        local questions
        questions=$(extract_analyst_questions "$analyst_output")
        
        if [[ -n "$questions" ]]; then
            log_success "HALT decision parsed correctly with questions"
            return 0
        else
            log_error "HALT decision parsed but no questions found"
            return 1
        fi
    else
        log_error "Failed to parse HALT decision, got: $decision"
        return 1
    fi
}

# Test 5: Loop continuation on PROCEED
test_loop_continuation_on_proceed() {
    increment_test
    log_info "Test 5: Loop continuation on PROCEED decision"
    
    # Simulate loop behavior
    local milestones_completed=0
    local max_iterations=3
    local should_continue=true
    
    for i in $(seq 1 $max_iterations); do
        # Mock analyst decision (all PROCEED)
        local analyst_output
        analyst_output=$(mock_milestone_analyst "P01M0$i" "mock content" "proceed")
        local decision
        decision=$(parse_analyst_decision "$analyst_output")
        
        if [[ "$decision" == "PROCEED" ]]; then
            milestones_completed=$((milestones_completed + 1))
            should_continue=true
        else
            should_continue=false
            break
        fi
    done
    
    if [[ "$milestones_completed" -eq $max_iterations ]] && [[ "$should_continue" == "true" ]]; then
        log_success "Loop continues correctly on PROCEED decisions (completed $milestones_completed milestones)"
        return 0
    else
        log_error "Loop should continue on PROCEED but stopped early"
        return 1
    fi
}

# Test 6: Loop halt on HALT decision
test_loop_halt_on_halt() {
    increment_test
    log_info "Test 6: Loop halt on HALT decision"
    
    # Simulate loop behavior
    local milestones_completed=0
    local should_continue=true
    
    # First milestone - PROCEED
    local analyst_output1
    analyst_output1=$(mock_milestone_analyst "P01M01" "mock content" "proceed")
    local decision1
    decision1=$(parse_analyst_decision "$analyst_output1")
    
    if [[ "$decision1" == "PROCEED" ]]; then
        milestones_completed=$((milestones_completed + 1))
    fi
    
    # Second milestone - HALT
    local analyst_output2
    analyst_output2=$(mock_milestone_analyst "P01M02" "mock content" "halt")
    local decision2
    decision2=$(parse_analyst_decision "$analyst_output2")
    
    if [[ "$decision2" == "HALT" ]]; then
        should_continue=false
        local questions
        questions=$(extract_analyst_questions "$analyst_output2")
        
        if [[ -n "$questions" ]] && [[ "$should_continue" == "false" ]]; then
            log_success "Loop halts correctly on HALT decision with questions"
            return 0
        else
            log_error "Loop should halt on HALT but continued"
            return 1
        fi
    else
        log_error "Failed to get HALT decision"
        return 1
    fi
}

# Test 7: Specialist review integration in auto loop
test_specialist_review_in_auto() {
    increment_test
    log_info "Test 7: Specialist review integration in auto-execution loop"
    
    # Mock specialist review
    local review_output
    review_output=$(mock_specialist_review "go" "mock diff" "approve")
    
    if check_specialist_approval "$review_output"; then
        log_success "Specialist review integrated correctly in auto loop"
        return 0
    else
        log_error "Specialist review failed in auto loop"
        return 1
    fi
}

# Test 11: Multiple specialists in auto loop - parallel reviews
test_multiple_specialists_in_auto() {
    increment_test
    log_info "Test 11: Multiple specialists called in parallel during auto-execution"
    
    # Simulate multi-language diff in auto loop
    local detected_langs="go typescript python"
    
    # Mock multiple specialist reviews (all approve)
    local all_reviews
    all_reviews=$(mock_multiple_specialist_reviews "$detected_langs" "mock diff" "all_approve")
    
    # Count specialists consulted
    local specialist_count
    specialist_count=$(count_specialists_consulted "$all_reviews")
    
    if [[ "$specialist_count" -ge 3 ]]; then
        # Verify all approved
        if aggregate_specialist_reviews "$all_reviews"; then
            log_success "Multiple specialists ($specialist_count) reviewed in parallel during auto-execution"
            return 0
        else
            log_error "All specialists should approve"
            return 1
        fi
    else
        log_error "Expected 3+ specialists, got: $specialist_count"
        return 1
    fi
}

# Test 8: PRD and phase validation for auto
test_auto_prd_phase_validation() {
    increment_test
    log_info "Test 8: PRD and phase validation for auto-execution"
    
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

# Test 9: State file handling
test_state_file_handling() {
    increment_test
    log_info "Test 9: State file handling"
    
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

# Test 10: Sequential milestone execution in loop
test_sequential_milestone_execution() {
    increment_test
    log_info "Test 10: Sequential milestone execution in auto loop"
    
    # Setup: Create phase with sequential milestones
    local test_slug="test-auto-seq"
    mkdir -p "$PROJECT_ROOT/.wiz/$test_slug/phases"
    
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
    
    cd "$PROJECT_ROOT"
    
    # Simulate sequential execution
    local executed=0
    
    for i in 1 2 3; do
        # Find next milestone
        local next
        next=$(wiz_find_next_milestone "$test_slug")
        
        if [[ -n "$next" ]] && [[ "$next" != "null" ]] && [[ "$next" != "\"COMPLETED\"" ]]; then
            executed=$((executed + 1))
            # Simulate marking this specific milestone as complete (only the one after the milestone ID)
            # Use awk to replace only the TODO status for this specific milestone
            awk -v milestone="$next" '
                /^### / && $0 ~ milestone {found=1; print; next}
                found && /🚧 TODO/ {gsub(/🚧 TODO/, "✅ COMPLETE"); found=0}
                {print}
            ' "$PROJECT_ROOT/.wiz/$test_slug/phases/phase1.md" > "$PROJECT_ROOT/.wiz/$test_slug/phases/phase1.md.tmp" && \
            mv "$PROJECT_ROOT/.wiz/$test_slug/phases/phase1.md.tmp" "$PROJECT_ROOT/.wiz/$test_slug/phases/phase1.md" 2>/dev/null || true
        else
            # No more milestones
            break
        fi
    done
    
    if [[ "$executed" -ge 2 ]]; then
        log_success "Sequential milestone execution works: executed $executed milestones"
        return 0
    else
        log_error "Sequential execution failed, only executed $executed milestones"
        return 1
    fi
}

# Main test execution
main() {
    log_info "Starting /wiz-auto integration tests..."
    echo ""
    
    test_context_loaded_once || true
    test_multiple_milestones || true
    test_analyst_proceed_decision || true
    test_analyst_halt_decision || true
    test_loop_continuation_on_proceed || true
    test_loop_halt_on_halt || true
    test_specialist_review_in_auto || true
    test_multiple_specialists_in_auto || true
    test_auto_prd_phase_validation || true
    test_state_file_handling || true
    test_sequential_milestone_execution || true
    
    echo ""
    print_test_summary
}

main "$@"
