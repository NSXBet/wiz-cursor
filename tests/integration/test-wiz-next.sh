#!/usr/bin/env bash
# Integration test for /wiz-next command
# Tests milestone execution with context integration, quality gates, and specialist review

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

# Cleanup function
cleanup() {
    log_info "Cleaning up test artifacts..."
    find "$PROJECT_ROOT" -type d -name ".wiz" -path "*/test-*" -exec rm -rf {} + 2>/dev/null || true
    rm -rf "$PROJECT_ROOT/.wiz/context" 2>/dev/null || true
    rm -f /tmp/specialist_review_round 2>/dev/null || true
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

# Test 3: Multiple milestone execution (count parameter)
test_multiple_milestone_execution() {
    increment_test
    log_info "Test 3: Multiple milestone execution with count parameter"
    
    # Setup: Create test phase with multiple TODO milestones
    local test_slug="test-next-multi"
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
    
    # Simulate finding next 3 milestones sequentially
    local count=3
    local found_milestones=()
    
    cd "$PROJECT_ROOT"
    for i in $(seq 1 $count); do
        local next
        next=$(wiz_find_next_milestone "$test_slug")
        if [[ -n "$next" ]] && [[ "$next" != "null" ]] && [[ "$next" != "\"COMPLETED\"" ]]; then
            found_milestones+=("$next")
            # Simulate marking this specific milestone as complete (only the one after the milestone ID)
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
    
    if [[ ${#found_milestones[@]} -eq $count ]]; then
        log_success "Found $count milestones for sequential execution: ${found_milestones[*]}"
        return 0
    else
        log_error "Expected $count milestones, found ${#found_milestones[@]}"
        return 1
    fi
}

# Test 4: Language detection from changed files
test_language_detection() {
    increment_test
    log_info "Test 4: Language detection from changed files"
    
    # Test Go files
    local go_files="test.go main.go handler.go"
    local detected
    detected=$(detect_language_from_files "$go_files")
    if echo "$detected" | grep -q "go"; then
        log_success "Go language detected correctly"
    else
        log_error "Failed to detect Go language"
        return 1
    fi
    
    # Test TypeScript files
    local ts_files="app.ts component.tsx"
    detected=$(detect_language_from_files "$ts_files")
    if echo "$detected" | grep -q "typescript"; then
        log_success "TypeScript language detected correctly"
    else
        log_error "Failed to detect TypeScript language"
        return 1
    fi
    
    # Test multiple languages
    local multi_files="test.go app.ts component.tsx"
    detected=$(detect_language_from_files "$multi_files")
    # Count words (languages are space-separated)
    local lang_count
    lang_count=$(echo "$detected" | tr ' ' '\n' | grep -v '^$' | wc -l | tr -d ' ')
    if [[ "$lang_count" -ge 2 ]]; then
        log_success "Multiple languages detected: $detected (count: $lang_count)"
        return 0
    else
        log_error "Failed to detect multiple languages, got: $detected (count: $lang_count)"
        return 1
    fi
}

# Test 5: Specialist review workflow - approval
test_specialist_review_approval() {
    increment_test
    log_info "Test 5: Specialist review workflow - approval path"
    
    # Mock specialist review with approval
    local review_output
    review_output=$(mock_specialist_review "go" "mock diff" "approve")
    
    if check_specialist_approval "$review_output"; then
        log_success "Specialist review approval detected correctly"
        return 0
    else
        log_error "Failed to detect specialist approval"
        return 1
    fi
}

# Test 6: Specialist review workflow - issues found
test_specialist_review_issues() {
    increment_test
    log_info "Test 6: Specialist review workflow - issues found"
    
    # Mock specialist review with issues
    local review_output
    review_output=$(mock_specialist_review "go" "mock diff" "issues")
    
    if ! check_specialist_approval "$review_output"; then
        # Should detect issues
        if echo "$review_output" | grep -qi "issues found"; then
            log_success "Specialist review issues detected correctly"
            return 0
        else
            log_error "Failed to detect specialist review issues"
            return 1
        fi
    else
        log_error "Should have detected issues but got approval"
        return 1
    fi
}

# Test 7: Specialist review workflow - multiple rounds
test_specialist_review_multiple_rounds() {
    increment_test
    log_info "Test 7: Specialist review workflow - multiple rounds until approval"
    
    rm -f /tmp/specialist_review_round
    
    # First round - issues found
    local round1
    round1=$(mock_specialist_review "go" "mock diff" "multiple_rounds")
    if ! check_specialist_approval "$round1"; then
        log_success "Round 1: Issues detected (as expected)"
    else
        log_error "Round 1: Should have found issues"
        return 1
    fi
    
    # Second round - approval
    local round2
    round2=$(mock_specialist_review "go" "mock diff" "multiple_rounds")
    if check_specialist_approval "$round2"; then
        log_success "Round 2: Approval received after fixes"
        return 0
    else
        log_error "Round 2: Should have been approved"
        return 1
    fi
}

# Test 8: Multiple specialists called in parallel - all approve
test_multiple_specialists_all_approve() {
    increment_test
    log_info "Test 8: Multiple specialists called in parallel - all approve"
    
    # Simulate multi-language diff (Go + TypeScript + Python)
    local multi_lang_files="handler.go app.ts service.py"
    local detected_langs
    detected_langs=$(detect_language_from_files "$multi_lang_files")
    
    # Should detect multiple languages
    local lang_count
    lang_count=$(echo "$detected_langs" | tr ' ' '\n' | grep -v '^$' | wc -l | tr -d ' ')
    
    if [[ "$lang_count" -lt 2 ]]; then
        log_error "Should detect multiple languages, got: $detected_langs (count: $lang_count)"
        return 1
    fi
    
    # Mock multiple specialist reviews (all approve)
    local all_reviews
    all_reviews=$(mock_multiple_specialist_reviews "$detected_langs" "mock diff" "all_approve")
    
    # Count specialists consulted
    local specialist_count
    specialist_count=$(count_specialists_consulted "$all_reviews")
    
    if [[ "$specialist_count" -ge 2 ]]; then
        log_success "Multiple specialists consulted: $specialist_count"
    else
        log_error "Expected multiple specialists, got: $specialist_count"
        return 1
    fi
    
    # Check all approved
    if aggregate_specialist_reviews "$all_reviews"; then
        log_success "All specialists approved multi-language changes"
        return 0
    else
        log_error "All specialists should approve but aggregation failed"
        return 1
    fi
}

# Test 9: Multiple specialists - one has issues
test_multiple_specialists_one_has_issues() {
    increment_test
    log_info "Test 9: Multiple specialists - one has issues"
    
    # Simulate multi-language diff (Go + TypeScript)
    local detected_langs="go typescript"
    
    # Mock reviews where one specialist has issues
    local all_reviews
    all_reviews=$(mock_multiple_specialist_reviews "$detected_langs" "mock diff" "one_has_issues")
    
    # Should NOT all approve (one has issues)
    if ! aggregate_specialist_reviews "$all_reviews"; then
        log_success "Correctly detected that not all specialists approved (one has issues)"
        return 0
    else
        log_error "Should have detected that one specialist has issues"
        return 1
    fi
}

# Test 10: Multiple specialists - all have issues
test_multiple_specialists_all_have_issues() {
    increment_test
    log_info "Test 10: Multiple specialists - all have issues"
    
    # Simulate multi-language diff (Go + Python)
    local detected_langs="go python"
    
    # Mock reviews where all specialists have issues
    local all_reviews
    all_reviews=$(mock_multiple_specialist_reviews "$detected_langs" "mock diff" "all_have_issues")
    
    # Should NOT approve
    if ! aggregate_specialist_reviews "$all_reviews"; then
        log_success "Correctly detected that all specialists found issues"
        return 0
    else
        log_error "Should have detected that all specialists have issues"
        return 1
    fi
}

# Test 8: Context loading for execution
test_execution_context_loading() {
    increment_test
    log_info "Test 8: Context loading for milestone execution"
    
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

# Test 9: PRD and phase file validation
test_prd_phase_validation() {
    increment_test
    log_info "Test 9: PRD and phase file validation"
    
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
    test_multiple_milestone_execution || true
    test_language_detection || true
    test_specialist_review_approval || true
    test_specialist_review_issues || true
    test_specialist_review_multiple_rounds || true
    test_multiple_specialists_all_approve || true
    test_multiple_specialists_one_has_issues || true
    test_multiple_specialists_all_have_issues || true
    test_execution_context_loading || true
    test_prd_phase_validation || true
    
    echo ""
    print_test_summary
}

main "$@"
