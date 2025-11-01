---
description: Review and verify phase completion
argument-hint: "<slug> <phase-number>"
---

# Review Phase Completion

You are reviewing a phase for completeness and quality using the Wiz Planner workflow.

## Arguments

- `<slug>`: PRD slug
- `<phase-number>`: Phase number to review (1, 2, 3, etc.)

## Review Agent

This command delegates detailed review to the **wiz-reviewer** agent (`.cursor/agents/wiz-reviewer.md`), which provides comprehensive phase review output suitable for quality assurance activities.

## Command Overview

This command performs comprehensive review of a phase to verify:
- All milestones are complete
- Functional requirements are met
- NFR gates are satisfied (tests, lint, docs, benchmarks)
- Code quality standards are met
- No missing or incomplete work

The review generates a detailed report with findings and recommendations.

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

## Execution Steps

### Step 1: Validate Arguments

```bash
#!/usr/bin/env bash
set -euo pipefail

# Parse arguments
SLUG="${1:-}"
PHASE_NUMBER="${2:-}"

if [[ -z "$SLUG" || -z "$PHASE_NUMBER" ]]; then
    echo "Usage: /wiz:review-phase <slug> <phase-number>"
    echo ""
    echo "Example: /wiz:review-phase auth-system 1"
    exit 1
fi

# Validate slug
if ! wiz_validate_slug "$SLUG"; then
    echo "Error: Invalid slug format: $SLUG"
    exit 1
fi

# Validate phase number
if ! [[ "$PHASE_NUMBER" =~ ^[0-9]+$ ]]; then
    echo "Error: Phase number must be a positive integer"
    exit 1
fi

# Check if PRD exists
PRD_FILE=".wiz/$SLUG/prd.md"
if [[ ! -f "$PRD_FILE" ]]; then
    echo "Error: PRD not found: $PRD_FILE"
    echo "Run /wiz:prd $SLUG first"
    exit 1
fi

# Check if phase file exists
PHASE_FILE=".wiz/$SLUG/phases/phase${PHASE_NUMBER}.md"
if [[ ! -f "$PHASE_FILE" ]]; then
    echo "Error: Phase file not found: $PHASE_FILE"
    echo "Run /wiz:phases $SLUG first"
    exit 1
fi

wiz_log_info "Reviewing phase $PHASE_NUMBER for PRD: $SLUG"
```

### Step 2: Load Phase Content

```bash
# Extract phase information
PHASE_TITLE=$(grep -m 1 "^# " "$PHASE_FILE" | sed 's/^# //')
PHASE_CONTENT=$(cat "$PHASE_FILE")

# Count milestones by status
TODO_COUNT=$(grep -c '🚧 TODO' "$PHASE_FILE" || echo "0")
IN_PROGRESS_COUNT=$(grep -c '🏗️ IN PROGRESS' "$PHASE_FILE" || echo "0")
COMPLETE_COUNT=$(grep -c '✅ COMPLETE' "$PHASE_FILE" || echo "0")
TOTAL_MILESTONES=$((TODO_COUNT + IN_PROGRESS_COUNT + COMPLETE_COUNT))

wiz_log_info "Phase has $TOTAL_MILESTONES milestones: $COMPLETE_COUNT complete, $IN_PROGRESS_COUNT in progress, $TODO_COUNT TODO"
```

### Step 3: Analyze Phase Completion

```bash
# Check if phase is ready for review
if [[ $TODO_COUNT -gt 0 || $IN_PROGRESS_COUNT -gt 0 ]]; then
    echo ""
    echo "⚠️  Phase Not Ready for Review"
    echo ""
    echo "Phase: $PHASE_NUMBER - $PHASE_TITLE"
    echo "Status:"
    echo "  ✅ Complete:     $COMPLETE_COUNT"
    echo "  🏗️  In Progress:  $IN_PROGRESS_COUNT"
    echo "  🚧 TODO:         $TODO_COUNT"
    echo ""
    echo "All milestones must be complete before phase review."
    echo "Run /wiz:next to continue implementation."
    echo ""
    exit 0
fi

echo ""
echo "📋 Phase Review: $PHASE_TITLE"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "PRD: $SLUG"
echo "Phase: $PHASE_NUMBER"
echo "Milestones: $TOTAL_MILESTONES (all complete)"
echo ""
```

### Step 4: Delegate to wiz-reviewer Agent

**⚠️ CRITICAL: Agent File Operation Limitation**

Agents invoked via agent references **cannot reliably write files**. This is a known limitation.

**Solution:**
- The `wiz-reviewer` agent **returns review report content** as markdown code blocks in its response
- The main agent (you, running /wiz:review-phase) **performs all Write operations**
- Agent focuses on: review analysis, findings, recommendations
- Main agent handles: all file I/O operations

**Workflow:**
1. Reference `.cursor/agents/wiz-reviewer.md` with the prompt template below
2. Agent returns review report as markdown in code blocks
3. Main agent writes the review report file using Write tool
4. Main agent displays summary to user

Reference the `.cursor/agents/wiz-reviewer.md` agent with the following prompt:

```
Review phase completion: Phase {PHASE_NUMBER} of PRD {SLUG}

## Context

### Phase Information

{PHASE_CONTENT}

### PRD Context

File: {PRD_FILE}

Extract relevant sections from the PRD that pertain to this phase's goals and requirements.

## Your Task

Perform a comprehensive review of this phase:

### 1. Milestone Completeness

For each milestone in this phase:
- Verify all acceptance criteria are met
- Check that implementation exists in codebase
- Validate that milestone goal was achieved

### 2. Functional Requirements

- Verify all phase goals are satisfied
- Check that features work as described
- Test critical functionality paths
- Identify any missing functionality

### 3. NFR Gate Compliance

Check compliance with NFR priority order:

**P0 - Correctness:**
- All code handles edge cases correctly
- Input validation present where needed
- Error handling comprehensive

**P1 - Regression Prevention:**
- Unit tests exist for all functions
- Integration tests cover workflows
- Test coverage is adequate
- All tests pass

**P2 - Security:**
- Input sanitization implemented
- No hardcoded secrets
- Authentication/authorization correct
- Security best practices followed

**P3 - Quality:**
- Code is readable and well-documented
- Linting rules satisfied
- No code smells or anti-patterns
- Documentation is complete

**P4 - Performance:**
- Performance requirements met (if specified)
- No obvious performance issues
- Benchmarks run (if required)

### 4. Code Quality

- Check code follows design guidelines
- Verify consistent coding style
- Look for technical debt
- Assess maintainability

## Review Report Format

Generate a review report with the following structure. Return the complete report as a markdown code block:

```markdown
# Phase {PHASE_NUMBER} Review: {PHASE_TITLE}

**PRD**: {SLUG}
**Date**: {TIMESTAMP}
**Reviewer**: Claude Code (wiz-reviewer)

## Summary

[1-2 paragraph overview of phase status and key findings]

## Milestone Verification

[For each milestone:]
### {MILESTONE_ID}: {MILESTONE_TITLE}

**Status**: ✅ Verified / ⚠️ Issues Found / ❌ Incomplete

[Verification details]

## NFR Compliance

### P0 - Correctness
- [Finding 1]
- [Finding 2]

### P1 - Tests
- [Finding 1]
- [Test coverage statistics]

### P2 - Security
- [Finding 1]
- [Security scan results]

### P3 - Quality
- [Lint results]
- [Documentation status]

### P4 - Performance
- [Benchmark results if applicable]

## Findings

### Critical Issues (must fix before proceeding)
- [Issue 1 with severity: CRITICAL]
- [Issue 2 with severity: CRITICAL]

### Warnings (should fix)
- [Issue 1 with severity: WARNING]

### Suggestions (nice to have)
- [Suggestion 1 with severity: INFO]

## Recommendations

1. [Specific actionable recommendation]
2. [Another recommendation]

## Conclusion

[Overall assessment: PASS / PASS WITH WARNINGS / FAIL]
```

## Output

Return the complete review report as a markdown code block. The main agent will write it to the file.
```

### Step 5: Generate and Save Review Report

```bash
# Create reviews directory if it doesn't exist
REVIEWS_DIR=".wiz/$SLUG/reviews"
mkdir -p "$REVIEWS_DIR"

# Review report file path
REVIEW_FILE="$REVIEWS_DIR/phase-${PHASE_NUMBER}-review.md"

# Extract review report from agent response (markdown code block)
# The main agent should extract the markdown content from the code block
# and write it to REVIEW_FILE using Write tool

# After writing, display completion message
echo "Review complete!"
echo ""
echo "Report saved to: $REVIEW_FILE"
echo ""
echo "Summary of findings:"
echo "  [Summary will be provided by wiz-reviewer agent]"
echo ""
```

## Example Output

```
📋 Phase Review: Foundation & Setup

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

PRD: auth-system
Phase: 1
Milestones: 10 (all complete)

[Agent performs review...]

Review complete!

Report saved to: .wiz/auth-system/reviews/phase-1-review.md

Summary of findings:
  ✅ All milestones verified
  ✅ NFR gates satisfied
  ⚠️  2 warnings found (code documentation)
  ℹ️  3 suggestions for improvement

Overall: PASS WITH WARNINGS

Next steps:
  - Address warnings in phase-1-review.md
  - Run /wiz:next to continue to Phase 2
```

## Error Handling

- **Missing slug**: Show usage
- **Missing phase number**: Show usage
- **Invalid slug format**: Error message
- **Invalid phase number**: Error message with format requirements
- **PRD not found**: Suggest running /wiz:prd
- **Phase file not found**: Suggest running /wiz:phases
- **Phase not complete**: Show status, suggest /wiz:next

## Notes

- Review should only be performed when all milestones are complete
- Review delegates to wiz-reviewer agent (`.cursor/agents/wiz-reviewer.md`)
- Report saved to `.wiz/<slug>/reviews/phase-<n>-review.md`
- Review follows NFR priority order (P0 → P1 → P2 → P3 → P4)
- Findings categorized by severity (Critical, Warning, Suggestion)
- Recommendations are specific and actionable
- Review can identify missing functionality or incomplete work
- Agent returns report as markdown code block, main agent writes file


