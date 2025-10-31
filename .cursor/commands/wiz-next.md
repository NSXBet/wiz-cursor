---
description: Find and execute the next TODO milestone(s)
argument-hint: "[slug] [count]"
---

# Execute Next Milestone(s)

You are executing the next TODO milestone(s) using the Wiz Planner workflow.

## Arguments

- `[slug]` (optional): PRD slug. If not provided, uses current PRD from `.wiz/.current-prd`
- `[count]` (optional): Number of milestones to complete. Default: 1. Example: `/wiz-next 4` completes the next 4 milestones sequentially


## Command Overview

This command finds and executes the next TODO milestone(s) across all phases. When a count is provided, it completes multiple milestones sequentially, one by one. The command **implements each milestone directly** (no delegation). Each milestone:
1. Loads focused context (phase document + milestone + design guidelines)
2. Analyzes requirements and detects language
3. (Optional) Consults language specialist for guidance during implementation
4. Implements code directly using Write/Edit/Bash tools
5. **Validates ALL acceptance criteria** and runs quality gates (tests, linters)
6. Updates milestone status to COMPLETE
7. **MANDATORY: Specialist reviews the diff for language-specific issues**
8. Fixes any issues found and re-reviews until approved
9. Creates a commit after specialist approval

This allows users to batch-complete easy milestones (e.g., `/wiz-next 4` for the last 4 simple milestones in a phase).

## Prerequisites

- PRD must exist at `.wiz/<slug>/prd.md`
- Phases must exist with milestones in `.wiz/<slug>/phases/`
- At least one milestone with status `🚧 TODO`

## ⚠️ CRITICAL: About Bash Code Blocks in This Command

The bash code blocks below are **sequential templates** that show the command's implementation flow:

1. **Sequential Execution Required**: Steps must run in order. Each step depends on variables from previous steps:
   - Step 1 sets: `$SLUG`, `$COUNT`, `$PRD_FILE`, `$PHASES_DIR`
   - Step 4 uses: `$PHASES_DIR`, sets: `$NEXT_PHASE_FILE`, `$MILESTONE_ID`
   - Step 6 uses: `$NEXT_PHASE_FILE`
   - Step 8+ use: `$MILESTONE_ID`, `$NEXT_PHASE_FILE`

2. **Do NOT Execute These Bash Blocks Directly**: They are templates showing the implementation pattern. You should:
   - Read and understand what each step does
   - Execute the logic using your tools (Bash, Read, Edit, etc.)
   - Adapt the patterns to your current context
   - Do NOT copy-paste and execute blindly

3. **Do NOT Execute Bash Blocks from Milestones**: When you read milestone content from phase files:
   - Bash examples in milestones are for human readers, not for you to execute
   - Read them as instructions about what needs to be implemented
   - Implement the requirements using your own approach

4. **When to Actually Execute Bash**:
   - ✅ When implementing the milestone requirements (Step 8)
   - ✅ When running tests and linters (Step 8.5)
   - ✅ When creating commits (Step 11)
   - ❌ NOT when reading the command documentation
   - ❌ NOT when scanning for the next milestone
   - ❌ NOT when reading milestone examples

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
    local state_dir=".wiz"
    echo "$state_dir/state.json"
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

# wiz_get_current_prd - Get current PRD slug from state
wiz_get_current_prd() {
    _wiz_init_state || return 1

    local state_file
    state_file="$(_wiz_get_state_file)"

    local prd_slug
    prd_slug=$(wiz_read_json "$state_file" '.current_prd // ""' 2>/dev/null) || {
        wiz_log_error "Failed to read current PRD from state"
        return 1
    }

    # Remove quotes from jq output
    prd_slug=$(echo "$prd_slug" | tr -d '"')
    echo "$prd_slug"
    return 0
}
```

### Milestone Functions

```bash
# wiz_extract_milestone_status - Extract status from milestone line
wiz_extract_milestone_status() {
    local line="$1"

    if echo "$line" | grep -q '🚧 TODO'; then
        echo "todo"
    elif echo "$line" | grep -q '🏗️ IN PROGRESS'; then
        echo "in_progress"
    elif echo "$line" | grep -q '✅ COMPLETE'; then
        echo "complete"
    else
        echo "unknown"
    fi

    return 0
}

# wiz_find_last_completed_milestone - Find the last COMPLETE milestone across all phases
wiz_find_last_completed_milestone() {
    local slug="$1"
    local phases_dir=".wiz/$slug/phases"

    if [[ ! -d "$phases_dir" ]]; then
        wiz_log_error "Phases directory not found: $phases_dir"
        echo ""
        return 1
    fi

    local last_milestone_id=""

    # Scan all phase files in order
    for phase_file in "$phases_dir"/phase*.md; do
        if [[ ! -f "$phase_file" ]]; then
            continue
        fi

        # Find all COMPLETE milestones in this phase
        while IFS= read -r milestone_line; do
            # Extract milestone ID
            local mid=$(echo "$milestone_line" | sed -E 's/^### ([A-Z0-9]+):.*/\1/')

            # Check if this milestone is COMPLETE
            local status_line=$(grep -A 5 "^### ${mid}:" "$phase_file" | grep -m 1 '^\*\*Status:\*\*' || echo "")
            if echo "$status_line" | grep -q '✅ COMPLETE'; then
                last_milestone_id="$mid"
            fi
        done < <(grep -E "^### [A-Z0-9]+:" "$phase_file" 2>/dev/null || true)
    done

    echo "$last_milestone_id"
    return 0
}

# wiz_find_next_milestone - Find the next milestone after the last completed one
wiz_find_next_milestone() {
    local slug="$1"
    local phases_dir=".wiz/$slug/phases"

    if [[ ! -d "$phases_dir" ]]; then
        wiz_log_error "Phases directory not found: $phases_dir"
        echo "null"
        return 1
    fi

    # Find last completed milestone
    local last_milestone_id
    last_milestone_id=$(wiz_find_last_completed_milestone "$slug")

    # If no completed milestones, start with P01M01
    if [[ -z "$last_milestone_id" ]]; then
        wiz_log_info "No completed milestones found, looking for P01M01"

        # Check if phase1.md exists
        local phase1_file="$phases_dir/phase1.md"
        if [[ ! -f "$phase1_file" ]]; then
            wiz_log_error "Phase 1 file not found: $phase1_file"
            echo "null"
            return 1
        fi

        # Look for P01M01
        if grep -q "^### P01M01:" "$phase1_file"; then
            # Return P01M01 with phase info
            local title=$(grep "^### P01M01:" "$phase1_file" | sed -E 's/^### P01M01: //')
            echo "{\"id\":\"P01M01\",\"title\":\"$title\",\"phase_number\":\"1\",\"phase_file\":\"$phase1_file\"}"
            return 0
        else
            wiz_log_error "P01M01 not found in phase 1"
            echo "null"
            return 1
        fi
    fi

    wiz_log_info "Last completed milestone: $last_milestone_id"

    # Extract phase and milestone numbers
    # P01M08 → phase=01, milestone=08
    local phase_num=$(echo "$last_milestone_id" | sed -E 's/^P0*([0-9]+)M[0-9]+$/\1/')
    local milestone_num=$(echo "$last_milestone_id" | sed -E 's/^P[0-9]+M0*([0-9]+)$/\1/')

    # Try next milestone in same phase (milestone + 1)
    local next_milestone_num=$((milestone_num + 1))
    local next_milestone_id=$(printf "P%02dM%02d" "$phase_num" "$next_milestone_num")
    local phase_file="$phases_dir/phase${phase_num}.md"

    wiz_log_info "Trying next milestone in same phase: $next_milestone_id"

    if [[ -f "$phase_file" ]] && grep -q "^### ${next_milestone_id}:" "$phase_file"; then
        # Found next milestone in same phase
        local title=$(grep "^### ${next_milestone_id}:" "$phase_file" | sed -E "s/^### ${next_milestone_id}: //")
        echo "{\"id\":\"$next_milestone_id\",\"title\":\"$title\",\"phase_number\":\"$phase_num\",\"phase_file\":\"$phase_file\"}"
        return 0
    fi

    # Milestone not in same phase, try first milestone of next phase
    local next_phase_num=$((phase_num + 1))
    local next_phase_milestone_id=$(printf "P%02dM01" "$next_phase_num")
    local next_phase_file="$phases_dir/phase${next_phase_num}.md"

    wiz_log_info "Phase $phase_num complete, trying next phase: $next_phase_milestone_id"

    if [[ -f "$next_phase_file" ]] && grep -q "^### ${next_phase_milestone_id}:" "$next_phase_file"; then
        # Found first milestone of next phase
        local title=$(grep "^### ${next_phase_milestone_id}:" "$next_phase_file" | sed -E "s/^### ${next_phase_milestone_id}: //")
        echo "{\"id\":\"$next_phase_milestone_id\",\"title\":\"$title\",\"phase_number\":\"$next_phase_num\",\"phase_file\":\"$next_phase_file\"}"
        return 0
    fi

    # No next milestone found - project complete!
    wiz_log_info "No next milestone found - project complete!"
    echo "\"COMPLETED\""
    return 0
}

# wiz_complete_milestone - Mark a milestone as complete in its phase file
wiz_complete_milestone() {
    local phase_file="$1"
    local milestone_id="$2"

    wiz_validate_file_exists "$phase_file" --type f || return 1

    # Check if milestone exists
    if ! grep -q "^### ${milestone_id}:" "$phase_file"; then
        wiz_log_error "Milestone not found: $milestone_id in $phase_file"
        return 1
    fi

    # Check current status
    local current_line
    current_line=$(grep "^### ${milestone_id}:" "$phase_file")

    if echo "$current_line" | grep -q '✅ COMPLETE'; then
        wiz_log_warn "Milestone already marked as complete: $milestone_id"
        return 0
    fi

    # Update status to COMPLETE
    # This updates the Status line that appears after the milestone heading
    local temp_file="${phase_file}.tmp"
    awk -v milestone="### ${milestone_id}:" '
        $0 ~ milestone { found=1 }
        found && /^\*\*Status:\*\*/ {
            sub(/🚧 TODO/, "✅ COMPLETE")
            sub(/🏗️ IN PROGRESS/, "✅ COMPLETE")
            found=0
        }
        { print }
    ' "$phase_file" > "$temp_file"

    # Verify the update was made
    if ! grep -q "^### ${milestone_id}:" "$temp_file"; then
        wiz_log_error "Update verification failed: milestone disappeared"
        rm -f "$temp_file"
        return 1
    fi

    # Atomic replacement
    mv "$temp_file" "$phase_file"

    wiz_log_info "Marked milestone as complete: $milestone_id"
    return 0
}

# wiz_extract_milestone_section - Extract a milestone section from a phase file
wiz_extract_milestone_section() {
    local phase_file="$1"
    local milestone_id="$2"

    wiz_validate_file_exists "$phase_file" --type f || return 1

    # Extract from milestone heading to ---
    awk "/^### ${milestone_id}:/,/^---$/" "$phase_file" | head -n -1

    return 0
}

# wiz_check_acceptance_criteria - Check if acceptance criteria are met
wiz_check_acceptance_criteria() {
    local phase_file="$1"
    local milestone_id="$2"

    wiz_validate_file_exists "$phase_file" --type f || return 1

    # Extract milestone section
    local milestone_section
    milestone_section=$(wiz_extract_milestone_section "$phase_file" "$milestone_id")

    if [[ -z "$milestone_section" ]]; then
        wiz_log_error "Failed to extract milestone section: $milestone_id"
        return 1
    fi

    # Count checked and unchecked criteria
    local total_criteria
    total_criteria=$(echo "$milestone_section" | grep -c "^- \[.\]" || true)

    if [[ $total_criteria -eq 0 ]]; then
        wiz_log_warn "No acceptance criteria found in milestone: $milestone_id"
        return 0  # No criteria means nothing to check
    fi

    local checked_criteria
    checked_criteria=$(echo "$milestone_section" | grep -c "^- \[x\]" || true)

    local unchecked_criteria=$((total_criteria - checked_criteria))

    wiz_log_info "Acceptance criteria for $milestone_id: $checked_criteria/$total_criteria complete"

    if [[ $unchecked_criteria -gt 0 ]]; then
        wiz_log_warn "Milestone has $unchecked_criteria unchecked acceptance criteria"
        echo "$milestone_section" | grep "^- \[ \]" | while read -r line; do
            wiz_log_warn "  Unchecked: $line"
        done
        return 1
    fi

    return 0
}

# wiz_mark_acceptance_criteria - Mark all acceptance criteria as complete
wiz_mark_acceptance_criteria() {
    local phase_file="$1"
    local milestone_id="$2"

    wiz_validate_file_exists "$phase_file" --type f || return 1

    # Check if milestone exists
    if ! grep -q "^### ${milestone_id}:" "$phase_file"; then
        wiz_log_error "Milestone not found: $milestone_id in $phase_file"
        return 1
    fi

    # Create temp file
    local temp_file="${phase_file}.tmp"

    # Mark all unchecked criteria as checked within the milestone section
    awk -v milestone="### ${milestone_id}:" '
        $0 ~ milestone { in_milestone=1 }
        in_milestone && /^---$/ { in_milestone=0 }
        in_milestone && /^- \[ \]/ { sub(/- \[ \]/, "- [x]") }
        { print }
    ' "$phase_file" > "$temp_file"

    # Verify the file was created
    if [[ ! -f "$temp_file" ]]; then
        wiz_log_error "Failed to create temp file"
        return 1
    fi

    # Atomic replacement
    mv "$temp_file" "$phase_file"

    wiz_log_info "Marked all acceptance criteria as complete for: $milestone_id"
    return 0
}
```

### PRD Functions

```bash
# wiz_check_all_milestones_complete - Check if all milestones in all phases are complete
wiz_check_all_milestones_complete() {
    local phases_dir="$1"

    if [[ ! -d "$phases_dir" ]]; then
        wiz_log_error "Phases directory not found: $phases_dir"
        return 1
    fi

    # Count TODO and IN_PROGRESS milestones across all phases
    local total_incomplete=0

    for phase_file in "$phases_dir"/phase*.md; do
        if [[ ! -f "$phase_file" ]]; then
            continue
        fi

        local todo_count
        todo_count=$(grep -c '🚧 TODO' "$phase_file" 2>/dev/null || echo "0")

        local in_progress_count
        in_progress_count=$(grep -c '🏗️ IN PROGRESS' "$phase_file" 2>/dev/null || echo "0")

        total_incomplete=$((total_incomplete + todo_count + in_progress_count))
    done

    if [[ $total_incomplete -eq 0 ]]; then
        wiz_log_info "All milestones are complete"
        return 0
    else
        wiz_log_info "Found $total_incomplete incomplete milestones"
        return 1
    fi
}

# wiz_mark_prd_complete - Mark PRD as complete if all milestones are done
wiz_mark_prd_complete() {
    local prd_file="$1"
    local phases_dir="$2"

    wiz_validate_file_exists "$prd_file" --type f || return 1

    # Check if all milestones are complete
    if ! wiz_check_all_milestones_complete "$phases_dir"; then
        wiz_log_warn "Cannot mark PRD as complete: milestones still pending"
        return 1
    fi

    # Update status to Complete in frontmatter (simplified - actual implementation would parse YAML)
    wiz_log_info "🎉 PRD marked as complete!"
    return 0
}
```

## Execution Steps

### Step 1: Determine PRD Slug

```bash
#!/usr/bin/env bash
set -euo pipefail

# Parse arguments
SLUG="${1:-}"
COUNT="${2:-1}"

# If no slug provided, read from current PRD state
if [[ -z "$SLUG" ]]; then
    if [[ -f ".wiz/.current-prd" ]]; then
        SLUG=$(cat .wiz/.current-prd)
        wiz_log_info "Using current PRD: $SLUG"
    else
        wiz_log_error "No slug provided and no current PRD set"
        echo "Usage: /wiz-next [slug] [count]"
        echo "Or set current PRD with /wiz-prd or /wiz-phases first"
        exit 1
    fi
fi

# Validate count is a positive integer
if ! [[ "$COUNT" =~ ^[0-9]+$ ]] || [[ "$COUNT" -lt 1 ]]; then
    wiz_log_error "Invalid count: $COUNT (must be a positive integer)"
    echo "Usage: /wiz-next [slug] [count]"
    echo "Count must be a positive integer (default: 1)"
    exit 1
fi

wiz_log_info "Executing $COUNT milestone(s)"

# Validate slug
if ! wiz_validate_slug "$SLUG"; then
    wiz_log_error "Invalid slug format: $SLUG"
    echo "Slug must be lowercase, alphanumeric, and hyphens only"
    exit 1
fi

# Check if PRD exists
PRD_FILE=".wiz/$SLUG/prd.md"
if [[ ! -f "$PRD_FILE" ]]; then
    wiz_log_error "PRD file not found: $PRD_FILE"
    echo "Run /wiz-prd $SLUG \"<idea>\" first to create a PRD"
    exit 1
fi

# Check if phases exist
PHASES_DIR=".wiz/$SLUG/phases"
if [[ ! -d "$PHASES_DIR" ]]; then
    wiz_log_error "Phases directory not found: $PHASES_DIR"
    echo "Run /wiz-phases $SLUG first to generate phases"
    exit 1
fi

wiz_log_info "Working with PRD: $SLUG"
```

### Step 2: Start Milestone Execution Loop

Wrap the execution in a loop to handle multiple milestones:

```bash
# Track completed milestones for summary
COMPLETED_MILESTONES=()
COMPLETED_COUNT=0

# Execute COUNT milestones
for ((i=1; i<=COUNT; i++)); do
    wiz_log_info "Processing milestone $i of $COUNT"

    # If multiple milestones, show progress
    if [[ $COUNT -gt 1 ]]; then
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "   Milestone $i of $COUNT"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
    fi
```

### Step 3: Check for Resume State

```bash
# Check for existing milestone in progress
RESUME_STATE_FILE=".wiz/.current-milestone.json"

if [[ -f "$RESUME_STATE_FILE" ]]; then
    RESUME_STATUS=$(jq -r '.status // "unknown"' "$RESUME_STATE_FILE")

    if [[ "$RESUME_STATUS" == "in_progress" ]]; then
        RESUME_ID=$(jq -r '.milestone_id' "$RESUME_STATE_FILE")
        RESUME_STARTED=$(jq -r '.started_at' "$RESUME_STATE_FILE")

        wiz_log_info "Found in-progress milestone: $RESUME_ID"
        echo ""
        echo "⚠️  In-Progress Milestone Found"
        echo ""
        echo "Milestone: $RESUME_ID"
        echo "Started: $RESUME_STARTED"
        echo ""
        echo "Would you like to:"
        echo "  1. Resume this milestone (recommended)"
        echo "  2. Skip to next TODO milestone"
        echo ""
        echo "Use /wiz-resume to resume the current milestone"
        echo "Or delete $RESUME_STATE_FILE to skip to next"
        exit 0
    fi
fi
```

### Step 4: Find Next TODO Milestone

Use the milestone finding logic to scan all phase files:

```bash
wiz_log_info "Finding next milestone..."

# Find next milestone using simple increment logic
# Logic:
# 1. Find last COMPLETE milestone (e.g., P01M08)
# 2. Try next milestone in same phase (P01M09)
# 3. If not found, try first milestone of next phase (P02M01)
# 4. If not found, project is complete
NEXT_MILESTONE_JSON=$(wiz_find_next_milestone "$SLUG")

# Check result
if [[ "$NEXT_MILESTONE_JSON" == "\"COMPLETED\"" ]]; then
    echo ""
    echo "🎉 All Milestones Complete!"
    echo ""
    echo "No more milestones found."
    echo "Congratulations - the project is complete!"
    echo ""
    echo "Run /wiz-status to see final statistics"
    exit 0
fi

if [[ "$NEXT_MILESTONE_JSON" == "null" || -z "$NEXT_MILESTONE_JSON" ]]; then
    echo ""
    echo "❌ Error finding next milestone"
    echo ""
    echo "Please check your phase files and milestone IDs."
    echo ""
    exit 1
fi

# Extract milestone metadata
MILESTONE_ID=$(echo "$NEXT_MILESTONE_JSON" | jq -r '.id')
MILESTONE_TITLE=$(echo "$NEXT_MILESTONE_JSON" | jq -r '.title')
NEXT_PHASE_NUM=$(echo "$NEXT_MILESTONE_JSON" | jq -r '.phase_number')
NEXT_PHASE_FILE=$(echo "$NEXT_MILESTONE_JSON" | jq -r '.phase_file')

wiz_log_info "Found next milestone: $MILESTONE_ID in phase $NEXT_PHASE_NUM"
```

### Step 6: Load Execution Context

Load the focused context for execution (phase + milestone + design guidelines):

```bash
# Load phase document
PHASE_CONTENT=$(cat "$NEXT_PHASE_FILE")

# Extract milestone section (from milestone heading to next heading or ---)
MILESTONE_SECTION=$(awk "/^### ${MILESTONE_ID}:/,/^---$|^### [A-Z0-9]+:/" "$NEXT_PHASE_FILE" | sed '$ d')

# Load design guidelines (if they exist)
DESIGN_GUIDELINES=""
if [[ -d ".wiz/design-guidelines" ]]; then
    for GUIDELINE_FILE in .wiz/design-guidelines/*.md; do
        if [[ -f "$GUIDELINE_FILE" ]]; then
            LANG=$(basename "$GUIDELINE_FILE" .md)
            DESIGN_GUIDELINES+="## Design Guidelines: $LANG\n\n"
            DESIGN_GUIDELINES+="$(cat "$GUIDELINE_FILE")\n\n"
        fi
    done
fi

# Calculate context size
CONTEXT_SIZE=$(( ${#PHASE_CONTENT} + ${#MILESTONE_SECTION} + ${#DESIGN_GUIDELINES} ))
wiz_log_info "Context size: ${CONTEXT_SIZE} bytes"

# Warn if context is large
if [[ $CONTEXT_SIZE -gt 20000 ]]; then
    wiz_log_warn "Context size exceeds 20KB - consider splitting milestone"
fi
```

### Step 7: Create Resume State

Save the current milestone state before execution:

```bash
# Create resume state
STARTED_AT=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

jq -n \
    --arg slug "$SLUG" \
    --arg milestone_id "$MILESTONE_ID" \
    --arg phase_num "$NEXT_PHASE_NUM" \
    --arg phase_file "$NEXT_PHASE_FILE" \
    --arg status "in_progress" \
    --arg started_at "$STARTED_AT" \
    '{
        slug: $slug,
        milestone_id: $milestone_id,
        phase_number: $phase_num,
        phase_file: $phase_file,
        status: $status,
        started_at: $started_at
    }' > "$RESUME_STATE_FILE"

wiz_log_info "Created resume state: $RESUME_STATE_FILE"
```

### Step 8: Display Milestone Info and Implement Directly

```bash
echo ""
echo "🚀 Executing Milestone: $MILESTONE_ID"
echo ""
echo "$MILESTONE_SECTION"
echo ""
echo "---"
echo ""
```

**YOU (the command) now implement the milestone directly. Do NOT delegate.**

#### 8.1: Analyze Milestone

From `$MILESTONE_SECTION`, understand:
- Goal of the milestone
- Acceptance criteria to satisfy
- Files mentioned (detect language from extensions)

#### 8.2: Detect Language

From file paths in milestone:
- `.go` → Go project
- `.ts`, `.tsx`, `.js`, `.jsx` → TypeScript/JavaScript
- `.py` → Python
- `.cs` → C#
- `.java` → Java

#### 8.3: (Optional) Consult Language Specialist

**You can consult specialists when you need help with:**
- ✅ **Figuring out the right coding strategy** for the milestone
- ✅ **Determining test commands** for the project's language/stack
- ✅ **Understanding assertion patterns** (e.g., for Go: should I use require.* methods?)
- ✅ Best practices unclear for the language
- ✅ Complex patterns needed (concurrency, async, etc.)
- ✅ Architecture decisions required
- ✅ Testing strategies and frameworks to use

**Only if you need guidance**, consult the language specialist by referencing the appropriate agent:
- `.cursor/agents/wiz-go-specialist.md` for Go
- `.cursor/agents/wiz-typescript-specialist.md` for TypeScript
- `.cursor/agents/wiz-python-specialist.md` for Python
- `.cursor/agents/wiz-csharp-specialist.md` for C#
- `.cursor/agents/wiz-java-specialist.md` for Java
- `.cursor/agents/wiz-docker-specialist.md` for Docker

Specialist provides guidance (not implementation). You use advice to implement.

#### 8.4: Write Code Using Your Tools

**Use Write tool for new files:**
- Create new files with the Write tool
- Provide complete file content

**Use Edit tool for modifications:**
- Edit existing files with the Edit tool
- Provide old_string and new_string for replacements

**Use Bash tool for file operations:**
- Create directories, run commands, etc.

#### 8.5: Run Tests and Linters

**If you're unsure about test commands for the project's language/stack, consult the specialist first (see Step 8.3).**

**For Go:**
```bash
go test ./... -v          # All tests must pass
golangci-lint run         # Zero errors
gofmt -w .                # Format
go vet ./...              # Vet
```

**For TypeScript:**
```bash
npm test                  # All tests must pass
eslint src/**/*.ts        # Zero errors
prettier --write "src/**"  # Format
```

**For Python:**
```bash
pytest                    # All tests must pass
flake8 .                  # Zero errors
black .                   # Format
mypy .                    # Type check
```

**CRITICAL**: Fix any failures before proceeding. If tests or linters fail and you're unsure how to fix them, consult the language specialist for guidance (see Step 8.3).

## Critical Quality Standards

**IMPORTANT: we WILL NOT tolerate any failing or skipped tests and we won't allow any LINT ERRORS. The entire codebase is your responsibility, not just the last milestone updates. This means that if something is broken WE FIX IT!**

Before marking this milestone as complete:
- Run ALL tests in the entire codebase - ZERO failures, ZERO skips
- Run ALL linters across the entire codebase - ZERO errors
- If your changes broke something elsewhere, YOU MUST FIX IT
- The ENTIRE codebase must be healthy before completing

A milestone is NOT complete if any test fails, any test is skipped, or any lint error exists anywhere in the codebase.

#### 8.6: Validate Acceptance Criteria

Check each criterion from milestone is satisfied. If not, implement missing pieces.

### Step 9: Verify and Update Milestone Status (After YOU Complete Implementation)

After YOU complete the milestone implementation directly:

**Step 9a: Mark Acceptance Criteria as Complete**

After verifying all criteria are met in Step 8.6:

```bash
echo ""
echo "Marking acceptance criteria as complete..."
echo ""

# Mark all criteria as complete
wiz_mark_acceptance_criteria "$NEXT_PHASE_FILE" "$MILESTONE_ID"

if [ $? -ne 0 ]; then
    wiz_log_error "Failed to mark acceptance criteria"
    exit 1
fi

wiz_log_info "All acceptance criteria marked as complete"
```

**Step 9b: Verify Criteria Are Checked**

```bash
# Double-check that criteria are now marked
if wiz_check_acceptance_criteria "$NEXT_PHASE_FILE" "$MILESTONE_ID"; then
    wiz_log_info "All acceptance criteria verified and marked"
else
    wiz_log_error "Acceptance criteria verification failed"
    exit 1
fi
```

**Step 9c: Update Milestone Status to COMPLETE**

```bash
wiz_complete_milestone "$NEXT_PHASE_FILE" "$MILESTONE_ID"

if [ $? -ne 0 ]; then
    wiz_log_error "Failed to update milestone status"
    exit 1
fi

wiz_log_info "Milestone status updated to COMPLETE"
```

**Step 9d: Update Resume State**

```bash
COMPLETED_AT=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

jq --arg completed_at "$COMPLETED_AT" \
   '.status = "complete" | .completed_at = $completed_at' \
   "$RESUME_STATE_FILE" > "${RESUME_STATE_FILE}.tmp"
mv "${RESUME_STATE_FILE}.tmp" "$RESUME_STATE_FILE"

wiz_log_info "Updated resume state to complete"
```

### Step 10: Mandatory Specialist Review of Changes

**⚠️ CRITICAL: Specialist review is REQUIRED before committing.**

Before creating the commit, the language specialist MUST review all changes to catch language-specific issues (e.g., using `t.Errorf` instead of `require.*` in Go).

#### 10.1: Generate Diff and Detect Language

**⚠️ CRITICAL: You MUST send the COMPLETE diff to the specialist.**

The specialist review is **worthless** if you only send partial files. Common mistakes:
- ❌ Only sending source files (writer.go) but not tests (writer_test.go)
- ❌ Only sending "main" files and skipping related files
- ❌ Filtering out test files, config files, or markdown files
- ❌ Truncating the diff because it's "too large"

**CORRECT approach - Include ALL code:**
- ✅ Include ALL source files (.go, .ts, .py, .cs, .java, etc.)
- ✅ Include ALL test files (*_test.go, *.test.ts, test_*.py, etc.)
- ✅ Include ALL config files (.toml, .yaml, .env, etc.)
- ✅ Include ALL documentation files (.md, .txt, etc.)
- ❌ Exclude binary files (executables, images, .so, .dll, etc.)
- ❌ Exclude large data files (.csv, .json data files, .db, etc.)

```bash
# Generate diff of ALL code changes - exclude binaries and large data files
CHANGES_DIFF=$(git diff HEAD -- . \
    ':(exclude)*.jpg' ':(exclude)*.jpeg' ':(exclude)*.png' ':(exclude)*.gif' \
    ':(exclude)*.pdf' ':(exclude)*.zip' ':(exclude)*.tar' ':(exclude)*.gz' \
    ':(exclude)*.exe' ':(exclude)*.dll' ':(exclude)*.so' ':(exclude)*.dylib' \
    ':(exclude)*.db' ':(exclude)*.sqlite' ':(exclude)*.csv' ':(exclude)*.parquet')

if [[ -z "$CHANGES_DIFF" ]]; then
    wiz_log_error "No changes detected - cannot review empty diff"
    exit 1
fi

# Detect ALL languages and technologies from changed files
CHANGED_FILES=$(git diff HEAD --name-only)
DETECTED_SPECIALISTS=()

# Detect programming languages
if echo "$CHANGED_FILES" | grep -q '\.go$'; then
    DETECTED_SPECIALISTS+=("go")
fi

if echo "$CHANGED_FILES" | grep -qE '\.(ts|tsx|js|jsx)$'; then
    DETECTED_SPECIALISTS+=("typescript")
fi

if echo "$CHANGED_FILES" | grep -q '\.py$'; then
    DETECTED_SPECIALISTS+=("python")
fi

if echo "$CHANGED_FILES" | grep -q '\.cs$'; then
    DETECTED_SPECIALISTS+=("csharp")
fi

if echo "$CHANGED_FILES" | grep -q '\.java$'; then
    DETECTED_SPECIALISTS+=("java")
fi

# Detect Docker files
if echo "$CHANGED_FILES" | grep -qE '(Dockerfile|docker-compose\.ya?ml)'; then
    DETECTED_SPECIALISTS+=("docker")
fi

wiz_log_info "Detected specialists to consult: ${DETECTED_SPECIALISTS[*]}"
```

#### 10.2: Consult ALL Specialists in Parallel

**⚠️ CRITICAL: Call ALL detected specialists in parallel in a SINGLE message.**

If you detected multiple specialists (e.g., Go, Python, and Docker), you MUST invoke them ALL in the SAME response message. This allows all reviews to happen concurrently for maximum efficiency.

**⚠️ REMINDER: Send the ENTIRE CHANGES_DIFF variable to EACH specialist - all code files.**

Do NOT:
- Filter which source/test files to include
- Select only certain code file types
- Omit test files or config files
- Truncate the diff
- Call specialists sequentially (call them ALL in one message!)

Each specialist MUST see ALL code changes to catch issues in their domain.

**How to call multiple specialists in parallel:**

When you need to consult specialists, reference the appropriate agent files:
- For Go: `.cursor/agents/wiz-go-specialist.md`
- For TypeScript: `.cursor/agents/wiz-typescript-specialist.md`
- For Python: `.cursor/agents/wiz-python-specialist.md`
- For C#: `.cursor/agents/wiz-csharp-specialist.md`
- For Java: `.cursor/agents/wiz-java-specialist.md`
- For Docker: `.cursor/agents/wiz-docker-specialist.md`

**Example prompt for Go specialist:**

```
Review the following changes for Go-specific issues and best practices violations.

## Milestone Context

Milestone: {MILESTONE_ID}
Goal: {MILESTONE_TITLE}

## Changes to Review

**IMPORTANT**: This is the COMPLETE diff including ALL files (source, tests, configs, etc.)

```diff
{CHANGES_DIFF}
```

## Your Task

Review the diff for Go-specific issues including:
- Assertion methods (require.* not t.Errorf/t.Fatalf)
- Concurrency (atomic/xsync vs locks/channels)
- Error handling and wrapping
- Naming conventions
- Imports (uber/zap, uber/fx, etc.)
- Testing patterns (table-driven tests)
- Code organization and package structure

Use your Read/Grep/Glob/Bash tools to:
- Read full files for context
- Find related code or tests
- Check repository patterns
- Verify consistency

## Output Format

If issues found:
```
## Issues Found

### Issue 1: [Category]
**Location**: [file:line]
**Problem**: [description]
**Fix**: [how to fix]
```

If no issues:
```
## Review Complete
✅ No issues found. Changes follow Go best practices.
```
```

**IMPORTANT**: Call ALL detected specialists in the SAME message. Do NOT wait for one to finish before calling the next. Call them ALL at once and wait for ALL responses.

#### 10.3: Aggregate Reviews and Fix Issues

After ALL specialists respond, aggregate their reviews:

**Aggregate all issues from all specialists:**

1. **Collect issues from ALL specialist responses**
2. **If ANY specialist found issues:**
   - Display ALL issues from ALL specialists
   - Fix EACH issue using Edit tool or Bash
   - **CRITICAL: Loop back to Step 10.1** - Do NOT proceed forward!
   - Generate new diff (Step 10.1)
   - Consult ALL specialists again with new diff (Step 10.2)
   - Parse the new reviews (Step 10.3)
   - Repeat until ALL specialists approve
3. **Do NOT proceed to Step 11** until ALL specialists say "No issues found"

**IF ALL SPECIALISTS say "No issues found" or "Review Complete":**

1. Proceed to Step 11 (Create Commit)

### Step 11: Create Narrative Commit

After specialist approval, create a commit with full narrative structure:

```bash
git add "$NEXT_PHASE_FILE"

COMMIT_MSG="feat(${MILESTONE_ID}): ${MILESTONE_TITLE}

Completed milestone ${MILESTONE_ID}.

🤖 Generated with Wiz Planner

Co-Authored-By: Wiz Planner <noreply@wiz-planner>"

git commit --no-gpg-sign -m "$COMMIT_MSG"

COMMIT_HASH=$(git rev-parse --short HEAD)

wiz_log_info "Created commit: $COMMIT_HASH"
```

### Step 12: Track Completion and Check PRD Completion

```bash
# Track this completion
COMPLETED_MILESTONES+=("$MILESTONE_ID: $MILESTONE_TITLE")
COMPLETED_COUNT=$((COMPLETED_COUNT + 1))

# Show milestone completion
echo ""
echo "✅ Milestone Complete: $MILESTONE_ID"
echo ""
echo "Title: $MILESTONE_TITLE"
echo "Commit: $COMMIT_HASH"
echo ""

# Check if this was the last milestone - mark PRD as complete if so
if wiz_check_all_milestones_complete "$PHASES_DIR"; then
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "   🎉 ALL MILESTONES COMPLETE! 🎉"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "Marking PRD as complete..."

    if wiz_mark_prd_complete "$PRD_FILE" "$PHASES_DIR"; then
        echo ""
        echo "✅ PRD status updated to: Complete"
        echo "✅ Last updated timestamp updated"
        echo ""
        echo "Project successfully completed!"
        echo ""
        echo "Next steps:"
        echo "  • Review the implementation"
        echo "  • Run /wiz-status to see final statistics"
        echo "  • Consider creating a release or deployment"
        echo ""
    else
        wiz_log_warn "Failed to mark PRD as complete (but all milestones are done)"
    fi

    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
fi

# Continue to next iteration of loop
done  # End of for loop

# Loop complete - show summary
```

### Step 13: Final Summary

After all milestones complete, show summary:

```bash
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "   Batch Execution Complete"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Completed $COMPLETED_COUNT of $COUNT milestone(s):"
echo ""

for milestone in "${COMPLETED_MILESTONES[@]}"; do
    echo "  ✅ $milestone"
done

echo ""

if [[ $COMPLETED_COUNT -eq $COUNT ]]; then
    echo "All requested milestones completed successfully!"
    echo ""
    echo "Run /wiz-next to continue, or /wiz-status to see overall progress"
else
    echo "Stopped after $COMPLETED_COUNT milestone(s)"
    echo ""
    echo "Run /wiz-next to continue from where we left off"
fi
```

## Error Handling

- **No slug and no current PRD**: Show usage and suggest running `/wiz-prd` or `/wiz-phases`
- **Invalid count**: Must be positive integer, show usage
- **Invalid slug format**: Show format requirements
- **PRD not found**: Suggest running `/wiz-prd` first
- **Phases not found**: Suggest running `/wiz-phases` first
- **No milestones found**: Suggest running `/wiz-milestones` first
- **All milestones complete**: Congratulatory message (may complete fewer than COUNT)
- **In-progress milestone exists**: Offer to resume or skip (only checked before first iteration)
- **Context too large (>20KB)**: Warning message
- **Milestone update fails**: Error and exit (stops batch execution)
- **Commit fails**: Error and recovery steps (stops batch execution)
- **Mid-batch failure**: Show partial completion summary with what succeeded

## Performance Requirements

- Find next milestone in **<2 seconds**
- Load context in **<1 second**
- Total command overhead: **<5 seconds** (excluding actual milestone implementation)

## Notes

- **Batch execution**: When count > 1, executes milestones one by one in a loop
- **Sequential processing**: Each milestone completes fully (including commit) before next starts
- **Quality gates**: All acceptance criteria and quality checks run for each milestone
- **Early termination**: Loop stops on first error (file operation, test failure, etc.)
- **Progress tracking**: Shows "Milestone X of N" header when count > 1
- **Direct implementation**: Command implements milestones directly using Write/Edit/Bash tools
- **Mandatory specialist review**: All changes reviewed by language specialist before commit
- Milestone status update uses `wiz_complete_milestone()` utility
- Resume state allows `/wiz-resume` to pick up interrupted work
- Context kept small (<20KB) for efficient execution
- Design guidelines loaded to ensure language-specific best practices

## Use Cases

- **Default (count=1)**: `/wiz-next` - Complete single milestone with full attention
- **Easy batch (count=3-5)**: `/wiz-next 4` - Complete last few simple milestones in a phase
- **Phase completion**: `/wiz-next 10` - Finish remaining milestones if they're straightforward
- **Not recommended for complex work**: Use count=1 for milestones requiring careful thought

## Starting Implementation

**Important**: If no work has been done so far (no completed milestones), this command will start with Phase 1, Milestone 1 (P01M01). Otherwise, it finds the next TODO milestone in ascending order across all phases.

This ensures implementation follows the planned sequence and dependencies.

