---
description: Review and audit a specific milestone
argument-hint: "<slug> <milestone-id>"
---

# Review Milestone Implementation

You are reviewing a milestone for completeness and quality using the Wiz Planner workflow.

## Arguments

- `<slug>`: PRD slug
- `<milestone-id>`: Milestone ID (e.g., P01M05, P02M12)

## Review Agent

This command delegates detailed audit to the **wiz-reviewer** agent (`.cursor/agents/wiz-reviewer.md`), which provides comprehensive milestone audit output suitable for quality assurance activities.

## Command Overview

This command performs deep audit of a single milestone:
- Verifies all acceptance criteria
- Checks code quality and implementation
- Validates test coverage
- Assesses NFR compliance
- Identifies improvement opportunities

## Embedded Utility Functions

### Logging Functions

```bash
# Check if terminal supports colors
_wiz_supports_color() {
    [[ -t 2 ]] && command -v tput >/dev/null 2>&1 && [[ $(tput colors 2>/dev/null || echo 0) -ge 8 ]]
}

# Color codes - only set if not already set
if [[ -z "${WIZ_COLOR_RESET+x}" ]]; then
    if _wiz_supports_color; then
        WIZ_COLOR_RESET="\033[0m"
        WIZ_COLOR_RED="\033[31m"
        WIZ_COLOR_YELLOW="\033[33m"
        WIZ_COLOR_BLUE="\033[34m"
        WIZ_COLOR_GRAY="\033[90m"
    else
        WIZ_COLOR_RESET=""
        WIZ_COLOR_RED=""
        WIZ_COLOR_YELLOW=""
        WIZ_COLOR_BLUE=""
        WIZ_COLOR_GRAY=""
    fi
    readonly WIZ_COLOR_RESET WIZ_COLOR_RED WIZ_COLOR_YELLOW WIZ_COLOR_BLUE WIZ_COLOR_GRAY 2>/dev/null || true
fi

# Get timestamp for logging
_wiz_timestamp() {
    date '+%Y-%m-%d %H:%M:%S'
}

# wiz_log_info - Log informational message
wiz_log_info() {
    local message="$*"
    echo -e "${WIZ_COLOR_BLUE}[$(_wiz_timestamp)] INFO:${WIZ_COLOR_RESET} $message" >&2
}

# wiz_log_warn - Log warning message
wiz_log_warn() {
    local message="$*"
    echo -e "${WIZ_COLOR_YELLOW}[$(_wiz_timestamp)] WARN:${WIZ_COLOR_RESET} $message" >&2
}

# wiz_log_error - Log error message
wiz_log_error() {
    local message="$*"
    echo -e "${WIZ_COLOR_RED}[$(_wiz_timestamp)] ERROR:${WIZ_COLOR_RESET} $message" >&2
}

# wiz_log_debug - Log debug message (only if WIZ_DEBUG is set)
wiz_log_debug() {
    if [[ "${WIZ_DEBUG:-}" == "1" ]] || [[ "${WIZ_DEBUG:-}" == "true" ]]; then
        local message="$*"
        echo -e "${WIZ_COLOR_GRAY}[$(_wiz_timestamp)] DEBUG:${WIZ_COLOR_RESET} $message" >&2
    fi
}
```

### Validation Functions

```bash
# wiz_validate_slug - Validate slug format
wiz_validate_slug() {
    local slug="$1"

    if [[ -z "$slug" ]]; then
        wiz_log_error "Slug cannot be empty"
        return 1
    fi

    # Check if slug matches pattern: lowercase letters, numbers, and hyphens only
    # Must not start or end with hyphen
    if [[ ! "$slug" =~ ^[a-z0-9]+(-[a-z0-9]+)*$ ]]; then
        wiz_log_error "Invalid slug: '$slug'"
        wiz_log_error "Slug must be lowercase, alphanumeric, with hyphens (not at start/end)"
        return 1
    fi

    return 0
}

# wiz_validate_file_exists - Validate that a file exists and is readable
wiz_validate_file_exists() {
    local file_path="$1"
    local file_type="${2:-f}"

    if [[ "$file_type" == "--type" ]]; then
        file_type="${3:-f}"
    fi

    if [[ -z "$file_path" ]]; then
        wiz_log_error "File path cannot be empty"
        return 1
    fi

    case "$file_type" in
        f)
            if [[ ! -f "$file_path" ]]; then
                wiz_log_error "File does not exist: $file_path"
                return 1
            fi
            ;;
        d)
            if [[ ! -d "$file_path" ]]; then
                wiz_log_error "Directory does not exist: $file_path"
                return 1
            fi
            ;;
        *)
            wiz_log_error "Invalid file type: $file_type (must be 'f' or 'd')"
            return 1
            ;;
    esac

    if [[ ! -r "$file_path" ]]; then
        wiz_log_error "Permission denied reading: $file_path"
        return 1
    fi

    return 0
}
```

### Milestone Functions

```bash
# wiz_extract_milestone_section - Extract a milestone section from a phase file
wiz_extract_milestone_section() {
    local phase_file="$1"
    local milestone_id="$2"

    wiz_validate_file_exists "$phase_file" --type f || return 1

    # Extract from milestone heading to ---
    awk "/^### ${milestone_id}:/,/^---$/" "$phase_file" | head -n -1

    return 0
}
```

## Execution Steps

### Step 1: Validate Arguments

```bash
#!/usr/bin/env bash
set -euo pipefail

# Parse arguments
SLUG="${1:-}"
MILESTONE_ID="${2:-}"

if [[ -z "$SLUG" || -z "$MILESTONE_ID" ]]; then
    echo "Usage: /wiz:review-milestone <slug> <milestone-id>"
    echo ""
    echo "Example: /wiz:review-milestone auth-system P01M05"
    exit 1
fi

# Validate slug
if ! wiz_validate_slug "$SLUG"; then
    echo "Error: Invalid slug format: $SLUG"
    exit 1
fi

# Validate milestone ID format (P##M##)
if ! [[ "$MILESTONE_ID" =~ ^P[0-9]{2}M[0-9]{2}$ ]]; then
    echo "Error: Invalid milestone ID format: $MILESTONE_ID"
    echo "Expected format: P##M## (e.g., P01M05, P02M12)"
    exit 1
fi

# Extract phase number from milestone ID
PHASE_NUMBER=$(echo "$MILESTONE_ID" | sed -E 's/^P0*([0-9]+)M.*/\1/')

# Check if phase file exists
PHASE_FILE=".wiz/$SLUG/phases/phase${PHASE_NUMBER}.md"
if [[ ! -f "$PHASE_FILE" ]]; then
    echo "Error: Phase file not found: $PHASE_FILE"
    exit 1
fi

wiz_log_info "Reviewing milestone $MILESTONE_ID for PRD: $SLUG"
```

### Step 2: Load Milestone Content

```bash
# Extract milestone section
MILESTONE_SECTION=$(wiz_extract_milestone_section "$PHASE_FILE" "$MILESTONE_ID")

if [[ -z "$MILESTONE_SECTION" ]]; then
    echo "Error: Milestone not found: $MILESTONE_ID in $PHASE_FILE"
    exit 1
fi

# Extract milestone title
MILESTONE_TITLE=$(echo "$MILESTONE_SECTION" | grep "^### ${MILESTONE_ID}:" | sed -E 's/^### [^:]+: //')

# Extract milestone status
MILESTONE_STATUS="unknown"
if echo "$MILESTONE_SECTION" | grep -q '✅ COMPLETE'; then
    MILESTONE_STATUS="complete"
elif echo "$MILESTONE_SECTION" | grep -q '🏗️ IN PROGRESS'; then
    MILESTONE_STATUS="in_progress"
elif echo "$MILESTONE_SECTION" | grep -q '🚧 TODO'; then
    MILESTONE_STATUS="todo"
fi

# Check if milestone is complete
if [[ "$MILESTONE_STATUS" != "complete" ]]; then
    echo ""
    echo "⚠️  Milestone Not Complete"
    echo ""
    echo "Milestone: $MILESTONE_ID - $MILESTONE_TITLE"
    echo "Status: $MILESTONE_STATUS"
    echo ""
    echo "Complete the milestone before reviewing."
    echo "Run /wiz:next to work on it."
    echo ""
    exit 0
fi

echo ""
echo "📋 Milestone Review: $MILESTONE_ID"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Milestone: $MILESTONE_ID"
echo "Title: $MILESTONE_TITLE"
echo "Phase: $PHASE_NUMBER"
echo "Status: ✅ Complete"
echo ""
```

### Step 3: Extract Acceptance Criteria

```bash
# Extract acceptance criteria from milestone section
ACCEPTANCE_CRITERIA=$(echo "$MILESTONE_SECTION" | awk '/^\*\*Acceptance Criteria\*\*/,/^---$/' | grep '^- \[' || true)

CRITERIA_COUNT=$(echo "$ACCEPTANCE_CRITERIA" | grep -c '^- \[' || echo "0")

echo "Acceptance Criteria: $CRITERIA_COUNT items"
echo ""
```

### Step 4: Delegate to wiz-reviewer Agent

**⚠️ CRITICAL: Agent File Operation Limitation**

Agents invoked via agent references **cannot reliably write files**. This is a known limitation.

**Solution:**
- The `wiz-reviewer` agent **returns audit report content** as markdown code blocks in its response
- The main agent (you, running /wiz:review-milestone) **performs all Write operations**
- Agent focuses on: audit analysis, findings, recommendations
- Main agent handles: all file I/O operations

**Workflow:**
1. Reference `.cursor/agents/wiz-reviewer.md` with the prompt template below
2. Agent returns audit report as markdown in code blocks
3. Main agent writes the audit report file using Write tool
4. Main agent displays summary to user

**Prompt Template**:
```
Audit milestone: {MILESTONE_ID}

## Context

### Milestone Details

{MILESTONE_SECTION}

### Phase Context

File: {PHASE_FILE}

Phase Number: {PHASE_NUMBER}

### Repository Context

Search the codebase for changes related to this milestone.
Look for:
- Files created or modified for this milestone
- Tests added for this functionality
- Documentation updates
- Commits mentioning this milestone ID

## Your Task

Perform a detailed audit of this milestone:

### 1. Acceptance Criteria Verification

For each acceptance criterion:
```
{ACCEPTANCE_CRITERIA}
```

Verify each criterion:
- [ ] Find evidence in code that criterion is met
- [ ] Provide file paths and line numbers
- [ ] Check if implementation is correct and complete
- [ ] Identify any gaps or issues

### 2. Code Quality Assessment

- Readability: Is code clear and well-structured?
- Maintainability: Can others easily understand and modify?
- Complexity: Any overly complex sections?
- Design patterns: Appropriate patterns used?
- Comments: Adequate inline documentation?

### 3. Test Coverage

- Unit tests: Do tests exist for this functionality?
- Test quality: Are tests comprehensive and meaningful?
- Edge cases: Are edge cases tested?
- Error cases: Are error paths tested?
- Test execution: Do tests pass?

### 4. NFR Compliance

**P0 - Correctness:**
- Input validation present?
- Error handling comprehensive?
- Edge cases handled?

**P1 - Tests:**
- Test coverage adequate?
- Tests pass?

**P2 - Security:**
- Security considerations addressed?
- No vulnerabilities introduced?

**P3 - Quality:**
- Code lint clean?
- Documentation complete?
- Follows design guidelines?

**P4 - Performance:**
- No obvious performance issues?
- Efficient algorithms used?

### 5. Improvement Opportunities

- What could be better?
- Any technical debt created?
- Refactoring opportunities?
- Missing optimizations?

## Audit Report Format

Generate a detailed audit report. Return the complete report as a markdown code block:

```markdown
# Milestone Audit: {MILESTONE_ID}

**Title**: {MILESTONE_TITLE}
**PRD**: {SLUG}
**Phase**: {PHASE_NUMBER}
**Date**: {TIMESTAMP}
**Auditor**: Claude Code (wiz-reviewer)

## Summary

[2-3 sentence overview of milestone status]

## Acceptance Criteria Verification

[For each criterion:]
### Criterion 1: [Description]

**Status**: ✅ Verified / ⚠️ Partially Met / ❌ Not Met

**Evidence**:
- File: `path/to/file.ext:123-145`
- Implementation: [Description of how criterion is met]

**Issues** (if any):
- [Issue description]

## Code Quality

**Overall Rating**: Excellent / Good / Fair / Poor

**Strengths**:
- [Strength 1]
- [Strength 2]

**Areas for Improvement**:
- [Area 1]
- [Area 2]

**Code Examples** (if issues found):
```language
[Example of problematic code]
```

**Suggested Fix**:
```language
[Improved version]
```

## Test Coverage

**Coverage**: [Percentage if available]

**Test Files**:
- `path/to/test1.test.ext`
- `path/to/test2.test.ext`

**Test Quality**: Excellent / Good / Fair / Poor

**Gaps**:
- [Missing test case 1]
- [Missing test case 2]

## NFR Compliance

### P0 - Correctness: ✅ Pass / ⚠️ Warning / ❌ Fail
[Details]

### P1 - Tests: ✅ Pass / ⚠️ Warning / ❌ Fail
[Details]

### P2 - Security: ✅ Pass / ⚠️ Warning / ❌ Fail
[Details]

### P3 - Quality: ✅ Pass / ⚠️ Warning / ❌ Fail
[Details]

### P4 - Performance: ✅ Pass / ⚠️ Warning / ❌ Fail
[Details]

## Findings

### Critical Issues
- [Critical issue requiring immediate fix]

### Warnings
- [Warning that should be addressed]

### Suggestions
- [Suggestion for improvement]

## Recommendations

1. [Specific actionable recommendation with code example]
2. [Another recommendation]

## Conclusion

**Overall Assessment**: PASS / PASS WITH WARNINGS / FAIL

[Final summary and next steps]
```

## Output

Return the complete audit report as a markdown code block. The main agent will write it to the file.
```

### Step 5: Save Audit Report

```bash
# Create reviews directory
REVIEWS_DIR=".wiz/$SLUG/reviews"
mkdir -p "$REVIEWS_DIR"

# Audit report file path
AUDIT_FILE="$REVIEWS_DIR/milestone-${MILESTONE_ID}-review.md"

# Extract audit report from agent response (markdown code block)
# The main agent should extract the markdown content from the code block
# and write it to AUDIT_FILE using Write tool

echo "Audit complete!"
echo ""
echo "Report saved to: $AUDIT_FILE"
echo ""
echo "Summary:"
echo "  [Summary will be provided by wiz-reviewer agent]"
echo ""
```

## Example Output

```
📋 Milestone Review: P01M05

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Milestone: P01M05
Title: Add JWT token validation
Phase: 1
Status: ✅ Complete

Acceptance Criteria: 5 items

[Agent performs audit...]

Audit complete!

Report saved to: .wiz/auth-system/reviews/milestone-P01M05-review.md

Summary:
  ✅ All 5 acceptance criteria verified
  ✅ Code quality: Good
  ✅ Test coverage: 87%
  ⚠️  1 warning: Error message could be more descriptive
  ℹ️  1 suggestion: Consider adding performance benchmark

Overall: PASS WITH WARNINGS

Recommended actions:
  1. Improve error message in jwt.go:145
  2. Add benchmark test for token validation performance
```

## Error Handling

- **Missing arguments**: Show usage
- **Invalid slug**: Error with format requirements
- **Invalid milestone ID**: Error with format example
- **Phase file not found**: Error message
- **Milestone not found**: Error with suggestion
- **Milestone not complete**: Show status, suggest /wiz:next

## Notes

- Only complete milestones should be audited
- Audit is more detailed than phase review
- Reviews specific acceptance criteria one by one
- Provides code examples and line numbers
- Suggests specific improvements with code samples
- Report saved to `.wiz/<slug>/reviews/milestone-<id>-review.md`
- Can be run independently of phase review
- Useful for quality assurance during development
- Agent returns report as markdown code block, main agent writes file

