______________________________________________________________________

## description: Generate detailed milestones for all phases argument-hint: <slug>

# Generate Implementation Milestones

You are generating detailed implementation milestones for all phases using the Wiz Planner workflow.

## ⚠️ CRITICAL: Direct File Writing (No Delegation)

**YOU MUST WRITE FILES TO DISK YOURSELF**. Do not delegate to subagents for file operations:

1. **Read each phase file** to understand requirements
1. **Generate milestones** for that phase (15-40 milestones)
1. **Use Edit tool YOURSELF** to append milestones to phase files
1. **Verify files** were updated after writing
1. **Process all phases** before completing

Previous versions delegated to subagents, but this proved unreliable. You must do all the work directly.

## Arguments

- `<slug>`: PRD slug (phases must exist at `.wiz/<slug>/phases/`)

## Planning Agent

This command delegates milestone generation to the **wiz-planner** agent (`.cursor/agents/wiz-planner.md`) when using parallel processing, which provides verbose, detailed milestone planning output suitable for strategic planning activities.

## Command Overview

This command reads all phase documents and generates detailed milestones (~1h each) for every phase. Each milestone represents a concrete, testable unit of work with clear acceptance criteria. Additionally, this command generates an IMPLEMENTATION_GUIDE.md to help developers understand how to execute the project.

## Prerequisites

- PRD must exist at `.wiz/<slug>/prd.md`
- Phases must exist in `.wiz/<slug>/phases/` (created by `/wiz:phases`)
- Phase files must follow naming convention: `phase1.md`, `phase2.md`, etc.

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

### File I/O Functions

```bash
# wiz_read_json - Read and parse a JSON file
wiz_read_json() {
    local file_path="$1"
    local jq_filter="${2:-.}"

    if [[ ! -f "$file_path" ]]; then
        echo "ERROR: File not found: $file_path" >&2
        return 1
    fi

    if [[ ! -r "$file_path" ]]; then
        echo "ERROR: Permission denied reading: $file_path" >&2
        return 1
    fi

    if ! jq "$jq_filter" "$file_path" 2>/dev/null; then
        echo "ERROR: Invalid JSON in file: $file_path" >&2
        return 1
    fi

    return 0
}

# wiz_write_json - Write JSON data to a file
wiz_write_json() {
    local file_path="$1"
    local json_data="$2"

    # Validate JSON before writing
    if ! echo "$json_data" | jq . >/dev/null 2>&1; then
        echo "ERROR: Invalid JSON data provided" >&2
        return 1
    fi

    local dir_path
    dir_path="$(dirname "$file_path")"

    if [[ ! -d "$dir_path" ]]; then
        echo "ERROR: Directory does not exist: $dir_path" >&2
        return 1
    fi

    if [[ -f "$file_path" ]] && [[ ! -w "$file_path" ]]; then
        echo "ERROR: Permission denied writing: $file_path" >&2
        return 1
    fi

    # Write formatted JSON
    if ! echo "$json_data" | jq . > "$file_path" 2>/dev/null; then
        echo "ERROR: Failed to write JSON to: $file_path" >&2
        return 1
    fi

    return 0
}

# wiz_read_file - Read a file with error handling
wiz_read_file() {
    local file_path="$1"

    if [[ ! -f "$file_path" ]]; then
        echo "ERROR: File not found: $file_path" >&2
        return 1
    fi

    if [[ ! -r "$file_path" ]]; then
        echo "ERROR: Permission denied reading: $file_path" >&2
        return 1
    fi

    cat "$file_path"
    return 0
}

# wiz_write_file - Write content to a file
wiz_write_file() {
    local file_path="$1"
    local content="$2"

    local dir_path
    dir_path="$(dirname "$file_path")"

    if [[ ! -d "$dir_path" ]]; then
        echo "ERROR: Directory does not exist: $dir_path" >&2
        return 1
    fi

    if [[ -f "$file_path" ]] && [[ ! -w "$file_path" ]]; then
        echo "ERROR: Permission denied writing: $file_path" >&2
        return 1
    fi

    if ! echo "$content" > "$file_path"; then
        echo "ERROR: Failed to write to: $file_path" >&2
        return 1
    fi

    return 0
}

# wiz_ensure_dir - Ensure directory exists, create if needed
wiz_ensure_dir() {
    local dir_path="$1"

    if [[ -d "$dir_path" ]]; then
        if [[ ! -w "$dir_path" ]]; then
            echo "ERROR: Directory not writable: $dir_path" >&2
            return 1
        fi
        return 0
    fi

    if ! mkdir -p "$dir_path" 2>/dev/null; then
        echo "ERROR: Failed to create directory: $dir_path" >&2
        return 1
    fi

    return 0
}
```

### State Management Functions

```bash
# Get state file path
_wiz_get_state_file() {
    echo ".wiz/state.json"
}

# Initialize state file if it doesn't exist
_wiz_init_state() {
    local state_file
    state_file="$(_wiz_get_state_file)"
    local state_dir
    state_dir="$(dirname "$state_file")"

    wiz_ensure_dir "$state_dir" || return 1

    if [[ ! -f "$state_file" ]]; then
        wiz_log_debug "Initializing state file: $state_file"
        echo '{}' | jq . > "$state_file"
    fi

    return 0
}

# Validate state JSON structure
_wiz_validate_state() {
    local json_data="$1"

    # Basic validation: ensure it's valid JSON
    if ! echo "$json_data" | jq . >/dev/null 2>&1; then
        wiz_log_error "State validation failed: Invalid JSON"
        return 1
    fi

    # Ensure it's an object
    if ! echo "$json_data" | jq -e 'type == "object"' >/dev/null 2>&1; then
        wiz_log_error "State validation failed: Root must be an object"
        return 1
    fi

    return 0
}

# Atomic write to state file
_wiz_atomic_write_state() {
    local state_file="$1"
    local json_data="$2"

    # Validate before writing
    if ! _wiz_validate_state "$json_data"; then
        return 1
    fi

    # Write to temp file
    local temp_file="${state_file}.tmp.$$"
    if ! echo "$json_data" | jq . > "$temp_file" 2>/dev/null; then
        wiz_log_error "Failed to write temp state file: $temp_file"
        rm -f "$temp_file"
        return 1
    fi

    # Atomic move
    if ! mv "$temp_file" "$state_file" 2>/dev/null; then
        wiz_log_error "Failed to move temp state file to: $state_file"
        rm -f "$temp_file"
        return 1
    fi

    return 0
}

# wiz_set_current_prd - Set current PRD slug in state
wiz_set_current_prd() {
    local prd_slug="$1"

    _wiz_init_state || return 1

    local state_file
    state_file="$(_wiz_get_state_file)"

    local current_state
    current_state=$(wiz_read_json "$state_file") || {
        wiz_log_error "Failed to read current state"
        return 1
    }

    local new_state
    new_state=$(echo "$current_state" | jq --arg prd "$prd_slug" '.current_prd = $prd') || {
        wiz_log_error "Failed to update PRD in state"
        return 1
    }

    _wiz_atomic_write_state "$state_file" "$new_state" || return 1

    wiz_log_debug "Set current PRD to: $prd_slug"
    return 0
}
```

## Execution Steps

### Step 1: Validate Arguments and Load Phases

```bash
#!/usr/bin/env bash
set -euo pipefail

# Parse arguments
SLUG="${1:-}"

# Validate slug
if [[ -z "$SLUG" ]]; then
    wiz_log_error "Missing slug argument"
    echo "Usage: /wiz:milestones <slug>"
    exit 1
fi

if ! wiz_validate_slug "$SLUG"; then
    wiz_log_error "Invalid slug format: $SLUG"
    echo "Slug must be lowercase, alphanumeric, and hyphens only"
    exit 1
fi

# Check if PRD exists
PRD_FILE=".wiz/$SLUG/prd.md"
if [[ ! -f "$PRD_FILE" ]]; then
    wiz_log_error "PRD file not found: $PRD_FILE"
    echo "Run /wiz:prd $SLUG \"<idea>\" first to create a PRD"
    exit 1
fi

# Check if phases exist
PHASES_DIR=".wiz/$SLUG/phases"
if [[ ! -d "$PHASES_DIR" ]]; then
    wiz_log_error "Phases directory not found: $PHASES_DIR"
    echo "Run /wiz:phases $SLUG first to generate phases"
    exit 1
fi

# Count phase files
PHASE_COUNT=$(ls -1 "$PHASES_DIR"/phase*.md 2>/dev/null | wc -l)
if [[ $PHASE_COUNT -eq 0 ]]; then
    wiz_log_error "No phase files found in $PHASES_DIR"
    echo "Run /wiz:phases $SLUG first to generate phases"
    exit 1
fi

wiz_log_info "Validated arguments - slug: $SLUG"
wiz_log_info "Found $PHASE_COUNT phases to process"
```

### Step 2: Invoke wiz-planner Agent (for Parallel Processing)

When using parallel processing (Option A), you'll delegate milestone generation to the `wiz-planner` agent (`.cursor/agents/wiz-planner.md`), which provides verbose, detailed milestone planning output suitable for strategic planning activities. The agent will automatically provide comprehensive, detailed milestone content when invoked.

### Step 3: Process Each Phase and Generate Milestones

**⚠️ CRITICAL: YOU MUST USE PARALLEL PROCESSING (OPTION A)**

Unless you have already tried Option A and it failed, you MUST use parallel processing.

#### Option A: Parallel Processing (DEFAULT - REQUIRED)

**YOU MUST USE THIS APPROACH FIRST**:

1. **Launch ALL phases in parallel** using Task tool in a SINGLE message
   - One Task tool call per phase
   - All Task calls in the same message for parallel execution
1. **Each subagent** receives the complete task prompt from the template below
1. **After all tasks complete**, verify each phase file has milestones
1. **ONLY if verification fails**, fall back to Option B for failed phases

**Why Use This**:

- 🚀 **5-10x faster**: Processes all phases simultaneously
- ✅ **Should work**: Subagents CAN execute bash commands
- 🔄 **Safe**: Has automatic fallback if it fails

**Do NOT skip to Option B without trying this first.**

#### Option B: Sequential Processing (FALLBACK ONLY)

**ONLY use this if**:

- You already tried Option A and it failed (0 tool uses or files not written)
- You are processing specific phases that failed in Option A

Process phases one at a time:

1. **Read the PRD** (`.wiz/{SLUG}/prd.md`) for context
1. **Read the phase file** (`.wiz/{SLUG}/phases/phase{N}.md`)
1. **Determine milestone count** from phase metadata
1. **Generate ALL milestones** for this phase
1. **Use the append_milestone bash function** to write each milestone
1. **Verify file was updated** by reading it back
1. **Move to next phase** and repeat

**This is slower** (sequential vs parallel) but guaranteed reliable.

### Parallel Task Template (Option A)

When using parallel processing, launch ALL tasks in a SINGLE message with this prompt for each phase:

````
Generate milestones for Phase {phase_num} in PRD: {SLUG}

## ⚠️ CRITICAL: Use Bash Commands to Write Files

You MUST use bash commands to append milestones. DO NOT use the Edit tool.

## Your Task

1. Read the PRD at `.wiz/{SLUG}/prd.md` (for context)
2. Read the phase file `.wiz/{SLUG}/phases/phase{phase_num}.md`
3. Note the milestone count from metadata (`**Duration**: ~X days (Y milestones @ 1h each)`)
4. Generate ALL milestones for THIS PHASE ONLY (15-40 milestones)
5. Use the append_milestone bash function (below) to write EACH milestone
6. Verify file was updated by reading it back
7. Report completion with milestone count

## The append_milestone Function

Copy this function and use it to append milestones:

```bash
append_milestone() {
    local slug="$1"
    local phase_num="$2"
    local milestone_content="$3"
    local phase_file=".wiz/${slug}/phases/phase${phase_num}.md"

    if [[ ! -f "$phase_file" ]]; then
        echo "Error: Phase file not found: $phase_file"
        return 1
    fi

    local temp_file=$(mktemp)
    awk -v content="$milestone_content" '
    /<!-- END:WIZ:SECTION:MILESTONES -->/ {
        print content
    }
    { print }
    ' "$phase_file" > "$temp_file"
    mv "$temp_file" "$phase_file"
    echo "✓ Appended milestone"
}
````

## How to Use the Function

For EACH milestone you generate:

```bash
# First, define the function (copy from above)

# Then, for each milestone:
MILESTONE=$(cat <<'EOF'
### P{phase:02d}M{milestone:02d}: {Title}

**Status:** 🚧 TODO
**ID:** P{phase:02d}M{milestone:02d}

**Goal**
{Description}

**Acceptance Criteria**
- [ ] {Criterion 1}
- [ ] {Criterion 2}

---

EOF
)

append_milestone "{SLUG}" {phase_num} "$MILESTONE"
```

**CRITICAL**:

- You MUST actually execute these bash commands
- Do NOT just generate milestone content without writing it
- Use the bash function for EVERY milestone
- If you only generate content without calling the function, you have FAILED

## After Generating All Milestones

1. Read the phase file back to verify milestones are present
1. Count the milestones (should match target count)
1. Report: "✅ Phase {N}: Generated and wrote {count} milestones"

```

**Example parallel launch**:
```

I'm launching milestone generation for all 5 phases in parallel...

[Task tool: Generate milestones for Phase 1]
[Task tool: Generate milestones for Phase 2]
[Task tool: Generate milestones for Phase 3]
[Task tool: Generate milestones for Phase 4]
[Task tool: Generate milestones for Phase 5]

All in the same message to execute in parallel.

````

## How to Append Milestones (Inline Bash)

### The Append Function

Use this bash function to append milestone content to phase files. It uses awk for reliable multiline insertion:

```bash
append_milestone() {
    local slug="$1"
    local phase_num="$2"
    local milestone_content="$3"

    local phase_file=".wiz/${slug}/phases/phase${phase_num}.md"

    # Verify file exists
    if [[ ! -f "$phase_file" ]]; then
        echo "Error: Phase file not found: $phase_file"
        return 1
    fi

    # Create temp file
    local temp_file=$(mktemp)

    # Use awk to insert content before end marker
    awk -v content="$milestone_content" '
    /<!-- END:WIZ:SECTION:MILESTONES -->/ {
        print content
    }
    { print }
    ' "$phase_file" > "$temp_file"

    # Atomic move
    mv "$temp_file" "$phase_file"

    echo "✓ Appended milestone to $phase_file"
}
````

### How to Use It

For each milestone you generate:

```bash
# Define the function first (copy from above)

# Generate milestone content
MILESTONE=$(cat <<'EOF'
### P01M01: First milestone title

**Status:** 🚧 TODO
**ID:** P01M01

**Goal**
Description of what this milestone achieves...

**Acceptance Criteria**
- [ ] Criterion 1
- [ ] Criterion 2
- [ ] Criterion 3

---

EOF
)

# Append it using the function
append_milestone "my-project" 1 "$MILESTONE"
```

### Why This Works

- ✅ **Self-contained** - Function defined in command, no external dependencies
- ✅ **Handles multiline** - awk naturally handles newlines in content
- ✅ **Atomic operation** - Temp file + mv ensures consistency
- ✅ **Simple** - Just bash, no Edit tool string matching
- ✅ **Reliable** - Proven strategy from utility script

## Milestone Generation Guidelines

### Milestone Granularity

Each milestone should represent ~1 hour of work:

- Small enough to complete in a single focused session
- Large enough to deliver tangible value or progress
- Specific enough to have clear acceptance criteria

### Milestone Structure

Use the milestone template:

```markdown
### P{phase:02d}M{milestone:02d}: {Title}

**Status:** 🚧 TODO
**ID:** P{phase:02d}M{milestone:02d}

**Goal**

{1-3 sentences describing what this milestone achieves}

**Acceptance Criteria**

- [ ] {Specific, testable criterion}
- [ ] {Another criterion}
- [ ] {Third criterion (typically 3-5 total)}

---
```

### Milestone ID Format

- Format: `P{phase:02d}M{milestone:02d}`
- Examples: P01M01, P01M25, P03M15, P07M40
- Zero-padded 2-digit numbers for both phase and milestone
- IDs are unique across the entire project

### Milestone Titling

Use clear, actionable titles with imperative mood:

- Good: "Implement user authentication endpoint"
- Bad: "User authentication" (not actionable)
- Good: "Add error handling to file operations"
- Bad: "Error handling" (too vague)

### Milestone Count by Phase

Distribute milestones based on phase complexity from phase metadata:

- Look for `**Duration**: ~X days (Y milestones @ 1h each)` in phase file
- Use Y as target milestone count
- Adjust slightly if needed for logical grouping (±3 milestones)

### Milestone Sequencing

Within each phase, milestones should follow logical order:

1. **Foundation Before Features**: Setup/structure before usage
1. **Core Before Edge Cases**: Happy path before error handling
1. **Implementation Before Testing**: Code before tests for that code
1. **Unit Before Integration**: Isolated tests before integration tests
1. **Features Before Documentation**: Working code before docs
1. **Verification Last**: Phase completion verification as final milestone

Example sequence for a "File Upload" feature:

1. Create file upload data structure
1. Implement file validation logic
1. Add file storage functionality
1. Handle file upload errors
1. Write unit tests for validation
1. Write unit tests for storage
1. Add integration test for upload flow
1. Document file upload API
1. **Verify phase completion** (final milestone)

### Phase Verification Milestone (Required)

**CRITICAL**: Every phase MUST end with a phase verification milestone as the LAST milestone.

This milestone ensures the phase is truly complete before moving to the next phase.

**Milestone Template**:

```markdown
### P{NN}M{LAST}: Verify Phase {N} Completion

**Status:** 🚧 TODO
**ID:** P{NN}M{LAST}

**Goal**
Verify that all Phase {N} requirements are met, tests pass, benchmarks are in place, and the phase is ready for sign-off before proceeding to Phase {N+1}.

**Acceptance Criteria**
- [ ] All previous milestones in Phase {N} marked as complete
- [ ] All tests pass (unit, integration, and end-to-end as applicable)
- [ ] Code coverage meets project standards (check answers.json for targets)
- [ ] Benchmarks exist and meet performance targets (if benchmarking enabled in answers.json)
- [ ] No outstanding bugs or issues from this phase
- [ ] Code reviewed and meets quality standards
- [ ] Documentation updated for all features in this phase
- [ ] Ready to proceed to Phase {N+1}

---
```

**When to Include**:

- **EVERY phase** must have this as the final milestone
- This is milestone N where N is the total count for that phase
- Example: If Phase 1 has 25 milestones, P01M25 should be the verification milestone

**What to Verify**:

1. **Completeness**: All feature milestones completed
1. **Testing**: Test suite comprehensive and passing
1. **Benchmarks**: Performance validated (if required by project)
1. **Quality**: Code meets standards from design guidelines
1. **Documentation**: All changes documented
1. **Readiness**: Confident to move to next phase

### Milestone Types by Phase

**Phase 1 (Foundation)**:

- Directory structure creation
- Template files
- Utility functions
- Configuration files
- Testing infrastructure

**Phase 2 (Core Features)**:

- Main functionality implementation
- API endpoints
- Business logic
- Data models
- Core workflows

**Phase 3 (Advanced Features)**:

- Secondary features
- Integrations
- Enhanced functionality
- User experience improvements

**Phase 4-5 (Quality & Deployment)**:

- Additional test coverage
- Performance optimization
- Documentation
- CI/CD setup
- Deployment scripts

### Milestone Acceptance Criteria

Each milestone must have 3-5 specific, testable criteria:

**Good Criteria** (specific, measurable):

- ✅ "File created: `src/auth/login.ts`"
- ✅ "Unit test passes: `login.test.ts` covers happy path"
- ✅ "Error handling: returns 401 for invalid credentials"
- ✅ "Integration test: end-to-end login flow succeeds"

**Bad Criteria** (vague, unmeasurable):

- ❌ "Login works"
- ❌ "Code is tested"
- ❌ "Documentation updated"
- ❌ "Everything done"

### NFR Integration

Ensure milestones address P0-P4 priorities:

**P0 Correctness**: Include in most milestones

- Error handling
- Edge case validation
- Data validation

**P1 Regression Prevention**: Include test milestones

- Unit tests
- Integration tests
- Test fixtures

**P2 Security**: Include dedicated milestones

- Authentication
- Authorization
- Input sanitization
- Encryption

**P3 Quality**: Include dedicated milestones

- Code review
- Documentation
- Refactoring
- Linting/formatting

**P4 Performance**: Include if required by PRD

- Profiling
- Optimization
- Load testing

### Step 4: Verify All Phases Complete

After processing all phases, **verify each file** contains milestones:

1. **Read each phase file** (`.wiz/{slug}/phases/phase{N}.md`)
1. **Check for milestones** - look for `### P{N}M` pattern entries
1. **Count milestones** - ensure count matches phase duration metadata

If any phase is missing milestones, go back and process it.

### Step 5: Display Summary

After all phases have milestones, display completion summary:

```
✅ Milestones Generated Successfully!

Phase 1: {N} milestones (P01M01-P01M{N})
Phase 2: {N} milestones (P02M01-P02M{N})
...

Files updated:
- .wiz/{slug}/phases/phase1.md
- .wiz/{slug}/phases/phase2.md
...
```

### Step 6: Generate Implementation Guide

Create `IMPLEMENTATION_GUIDE.md` with PRD-specific context:

````markdown
# Implementation Guide: {PRD Title}

**PRD**: {slug}
**Status**: Ready for implementation
**Primary Language(s)**: {from answers.json}
**Total Phases**: {N}
**Estimated Duration**: {X weeks/months}

## Overview

{Brief summary of project from PRD}

## How to Use This Guide

This guide provides step-by-step instructions for implementing the project using the Wiz Planner workflow.

### Starting Implementation

If no work has been done so far, start with Phase 1, Milestone 1 (P01M01). Otherwise, continue to the next milestone in ascending order.

To begin implementation:
```bash
/wiz:next
````

This will load the next TODO milestone and guide you through implementation.

### Workflow Commands

- `/wiz:next` - Load next TODO milestone and begin work
- `/wiz:status` - View progress across all phases
- `/wiz:resume` - Resume work on in-progress milestone
- `/wiz:review-milestone <id>` - Review and mark milestone complete
- `/wiz:review-phase <number>` - Review entire phase completion

## Phase Overview

{For each phase, provide:

- Phase number and title
- Brief goal
- Milestone count
- Dependencies
  }

## Design Guidelines

This project uses the following design guidelines:

- {Language 1}: `.wiz/design-guidelines/{lang1}.md` (generated from templates)
- {Language 2}: `.wiz/design-guidelines/{lang2}.md` (if multi-language)

Refer to these guidelines during implementation for language-specific best practices.

## NFR Priority Order

This project follows the Wiz Planner NFR priority order:

1. **P0 - Correctness**: Code must work correctly for all inputs
1. **P1 - Regression Prevention**: Tests prevent future breakage
1. **P2 - Security**: System is secure against threats
1. **P3 - Quality**: Code is maintainable and documented
1. **P4 - Performance**: System meets performance targets

Address priorities in this order during implementation.

## Testing Strategy

{Extract from PRD answers and requirements:

- Unit testing approach
- Integration testing approach
- Test coverage targets
- Benchmarking policy (from answers)
- Fuzzing policy (from answers)
  }

## Key Technical Decisions

{Extract from PRD:

- Architecture choices
- Technology stack
- Integration points
- Constraints
  }

## Success Metrics

{Extract from PRD:

- Acceptance criteria
- Success metrics
- Performance targets
  }

## Next Steps

1. Review this guide and the PRD (`.wiz/{slug}/prd.md`)
1. Familiarize yourself with phase structure (`.wiz/{slug}/phases/`)
1. Run `/wiz:next` to begin Phase 1, Milestone 1 (P01M01)
1. Follow the milestone acceptance criteria
1. Use `/wiz:review-milestone P01M01` when complete

## Resources

- PRD: `.wiz/{slug}/prd.md`
- Q&A Session: `.wiz/{slug}/intake/qa.md`
- Design Guidelines: `.wiz/design-guidelines/`
- Phase Documents: `.wiz/{slug}/phases/`

______________________________________________________________________

Generated by Wiz Planner • {timestamp}

````

Save to `.wiz/{SLUG}/IMPLEMENTATION_GUIDE.md`

### Step 7: Update State

Set current PRD to indicate milestones have been generated:

```bash
wiz_set_current_prd "$SLUG"

wiz_log_info "Set current PRD to: $SLUG"
````

### Step 8: Display Final Success Message

Display milestone summary to user:

```
✅ Milestones Generated Successfully!

**PRD**: {SLUG}
**Total Milestones**: {count} across {N} phases
**Location**: .wiz/{SLUG}/phases/

## Milestone Summary

**Phase 1**: {Title}
- Milestones: P01M01 through P01M{count}
- Duration: ~{duration} days

**Phase 2**: {Title}
- Milestones: P02M01 through P02M{count}
- Duration: ~{duration} days

[... continue for all phases ...]

**Total Estimated Duration**: {total_days} days (~{weeks} weeks)

## Implementation Guide Created

📖 `.wiz/{SLUG}/IMPLEMENTATION_GUIDE.md` - Start here for implementation instructions

## Next Steps

1. **Review Implementation Guide**: Read `.wiz/{SLUG}/IMPLEMENTATION_GUIDE.md`
2. **Review Phase 1 Milestones**: Read `.wiz/{SLUG}/phases/phase1.md`
3. **Start Implementation**: Run `/wiz:next` to begin P01M01

## Files Updated

- `.wiz/{SLUG}/phases/phase1.md` through `phase{N}.md` - Milestones appended
- `.wiz/{SLUG}/IMPLEMENTATION_GUIDE.md` - Implementation guide created

You're ready to start implementing! Run `/wiz:next` when ready.
```

## Error Handling

- **Missing slug**: Show usage example
- **Invalid slug format**: Show format requirements
- **PRD not found**: Suggest running `/wiz:prd` first
- **Phases not found**: Suggest running `/wiz:phases` first
- **No phase files**: Check phase directory for files
- **File write errors**: Check permissions and disk space
- **Subagent errors**: Show detailed error message and recovery steps

## Example Usage

```bash
/wiz:milestones auth-system
```

This will:

1. Read `.wiz/auth-system/prd.md` and `.wiz/auth-system/phases/phase*.md`
1. Generate detailed milestones for each phase
1. Append milestones to phase files
1. Generate `.wiz/auth-system/IMPLEMENTATION_GUIDE.md`
1. Display milestone summary

## Notes

- Milestones use format: P{phase:02d}M{milestone:02d} (e.g., P01M01, P02M25)
- Each milestone ~1 hour of work
- Milestone acceptance criteria must be specific and testable
- Implementation guide provides PRD-specific context and workflow instructions
- Command delegates to `wiz-planner` subagent (Phase 3 implementation)
