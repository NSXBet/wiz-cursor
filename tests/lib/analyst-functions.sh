#!/usr/bin/env bash
# Mock milestone-analyst functions for testing
# These simulate the milestone-analyst agent integration

# Mock milestone analyst decision (for testing)
# In real execution, this would call the actual milestone-analyst agent
mock_milestone_analyst() {
    local milestone_id="$1"
    local milestone_content="$2"
    local decision_type="${3:-proceed}"  # proceed or halt
    
    case "$decision_type" in
        proceed)
            echo "## Analysis Result: PROCEED

**Decision**: PROCEED ✅

**Rationale**: Requirements are clear and unambiguous. This milestone can be safely executed automatically without human input.

**Confidence**: High

**Reasoning**:
- Requirements are well-defined
- No ambiguous decisions needed
- Technical approach is clear
- No architectural questions"
            ;;
        halt)
            echo "## Analysis Result: HALT

**Decision**: HALT ⚠️

**Rationale**: Human input is required before proceeding with this milestone.

**Questions for Human**:
1. What authentication mechanism should be used? (OAuth, JWT, or basic auth?)
2. Should this integrate with existing systems or be standalone?
3. What are the performance requirements for this feature?

**Reasoning**:
- Requires architectural decisions
- Needs clarification on integration approach
- Performance requirements unclear"
            ;;
    esac
}

# Parse analyst decision from output
parse_analyst_decision() {
    local analyst_output="$1"
    
    if echo "$analyst_output" | grep -qiE "decision.*proceed|proceed.*✅"; then
        echo "PROCEED"
        return 0
    elif echo "$analyst_output" | grep -qiE "decision.*halt|halt.*⚠️"; then
        echo "HALT"
        return 0
    else
        echo "UNKNOWN"
        return 1
    fi
}

# Extract questions from HALT decision
extract_analyst_questions() {
    local analyst_output="$1"
    
    # Extract questions section
    echo "$analyst_output" | awk '/Questions for Human/,/Reasoning:/' | grep -E '^\s*[0-9]+\.' || true
}

