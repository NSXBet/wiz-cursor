#!/usr/bin/env bash
# Mock specialist review functions for testing
# These simulate the specialist review workflow

# Mock specialist review response (for testing)
# In real execution, this would call the actual specialist agent
mock_specialist_review() {
    local language="$1"
    local diff_content="$2"
    local response_type="${3:-approve}"  # approve, issues, or multiple_rounds
    
    case "$response_type" in
        approve)
            echo "## Review Complete
✅ No issues found. Changes follow ${language} best practices."
            ;;
        issues)
            echo "## Issues Found

### Issue 1: Code Style
**Location**: test.go:42
**Problem**: Using t.Errorf instead of require.Error
**Fix**: Replace with require.Error for better test failure handling"
            ;;
        multiple_rounds)
            # First round has issues, second round approves
            if [[ -f "/tmp/specialist_review_round" ]]; then
                local round=$(cat /tmp/specialist_review_round)
                if [[ "$round" -eq 2 ]]; then
                    echo "## Review Complete
✅ No issues found. Changes follow ${language} best practices."
                    rm -f /tmp/specialist_review_round
                else
                    echo "## Issues Found

### Issue 1: Code Style
**Location**: test.go:42
**Problem**: Using t.Errorf instead of require.Error
**Fix**: Replace with require.Error for better test failure handling"
                    echo "2" > /tmp/specialist_review_round
                fi
            else
                echo "## Issues Found

### Issue 1: Code Style
**Location**: test.go:42
**Problem**: Using t.Errorf instead of require.Error
**Fix**: Replace with require.Error for better test failure handling"
                echo "2" > /tmp/specialist_review_round
            fi
            ;;
    esac
}

# Check if specialist review approved
check_specialist_approval() {
    local review_output="$1"
    
    if echo "$review_output" | grep -qiE "review complete|no issues found|✅"; then
        return 0
    else
        return 1
    fi
}

# Detect language from changed files
detect_language_from_files() {
    local files="$1"
    local detected=()
    
    # Split files by space and check each
    for file in $files; do
        if echo "$file" | grep -q '\.go$'; then
            detected+=("go")
        elif echo "$file" | grep -qE '\.(ts|tsx|js|jsx)$'; then
            detected+=("typescript")
        elif echo "$file" | grep -q '\.py$'; then
            detected+=("python")
        elif echo "$file" | grep -q '\.cs$'; then
            detected+=("csharp")
        elif echo "$file" | grep -q '\.java$'; then
            detected+=("java")
        fi
    done
    
    # Remove duplicates and return space-separated
    echo "${detected[@]}" | tr ' ' '\n' | sort -u | tr '\n' ' ' | sed 's/ $//'
}

# Mock multiple specialist reviews in parallel (for testing)
# Simulates calling multiple specialists simultaneously
mock_multiple_specialist_reviews() {
    local languages="$1"  # Space-separated list: "go typescript python"
    local diff_content="$2"
    local response_type="${3:-all_approve}"  # all_approve, one_has_issues, all_have_issues
    
    local specialists=()
    for lang in $languages; do
        specialists+=("$lang")
    done
    
    case "$response_type" in
        all_approve)
            # All specialists approve
            for lang in "${specialists[@]}"; do
                echo "=== ${lang} specialist review ==="
                mock_specialist_review "$lang" "$diff_content" "approve"
                echo ""
            done
            ;;
        one_has_issues)
            # First specialist has issues, others approve
            local first=true
            for lang in "${specialists[@]}"; do
                echo "=== ${lang} specialist review ==="
                if [[ "$first" == "true" ]]; then
                    mock_specialist_review "$lang" "$diff_content" "issues"
                    first=false
                else
                    mock_specialist_review "$lang" "$diff_content" "approve"
                fi
                echo ""
            done
            ;;
        all_have_issues)
            # All specialists find issues
            for lang in "${specialists[@]}"; do
                echo "=== ${lang} specialist review ==="
                mock_specialist_review "$lang" "$diff_content" "issues"
                echo ""
            done
            ;;
    esac
}

# Aggregate multiple specialist reviews
# Checks if ALL specialists approved
aggregate_specialist_reviews() {
    local all_reviews="$1"
    local all_approved=true
    
    # Split reviews by specialist marker and check each
    # Use a more reliable parsing method
    local current_review=""
    while IFS= read -r line; do
        if echo "$line" | grep -q "^=== .* specialist review ==="; then
            # Check previous review if exists
            if [[ -n "$current_review" ]]; then
                if ! check_specialist_approval "$current_review"; then
                    all_approved=false
                    break
                fi
            fi
            current_review="$line"
        elif [[ -n "$current_review" ]]; then
            current_review+=$'\n'"$line"
        fi
    done <<< "$all_reviews"
    
    # Check last review
    if [[ -n "$current_review" ]]; then
        if ! check_specialist_approval "$current_review"; then
            all_approved=false
        fi
    fi
    
    if [[ "$all_approved" == "true" ]]; then
        return 0
    else
        return 1
    fi
}

# Count number of specialists consulted
count_specialists_consulted() {
    local reviews="$1"
    echo "$reviews" | grep -c "=== .* specialist review ===" || echo "0"
}

