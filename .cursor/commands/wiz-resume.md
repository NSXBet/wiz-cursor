______________________________________________________________________

## description: Resume work on in-progress milestone

# Resume In-Progress Milestone

You are resuming work on an in-progress milestone using the Wiz Planner workflow.

## Command Overview

This command loads resume state from `.wiz/.current-milestone.json` (or state.json) and offers options to:

- Continue working on the in-progress milestone
- Skip to the next TODO milestone
- Cancel and return to shell

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
```

## Execution Steps

### Step 1: Check for Resume State

```bash
#!/usr/bin/env bash
set -euo pipefail

RESUME_STATE_FILE=".wiz/.current-milestone.json"

# Check if resume state exists (legacy file)
if [[ ! -f "$RESUME_STATE_FILE" ]]; then
    # Try to get from state.json
    if [[ -f ".wiz/state.json" ]]; then
        CURRENT_MILESTONE_ID=$(jq -r '.current_milestone // ""' .wiz/state.json 2>/dev/null || echo "")
        if [[ -n "$CURRENT_MILESTONE_ID" ]]; then
            # Reconstruct resume state from state.json
            SLUG=$(jq -r '.current_prd // ""' .wiz/state.json 2>/dev/null || echo "")
            if [[ -z "$SLUG" ]]; then
                echo ""
                echo "📋 Resume Milestone"
                echo ""
                echo "No resume state found."
                echo ""
                echo "Resume state is created when you run /wiz:next."
                echo "It allows you to continue work after interruptions."
                echo ""
                echo "To start working:"
                echo "  Run: /wiz:next"
                echo ""
                exit 0
            fi
            # Find phase file and other info
            PHASE_FILE=$(find .wiz/$SLUG/phases -name "phase*.md" -exec grep -l "^### ${CURRENT_MILESTONE_ID}:" {} \; | head -n 1)
            if [[ -n "$PHASE_FILE" ]]; then
                PHASE_NUM=$(echo "$PHASE_FILE" | sed -E 's/.*phase([0-9]+)\.md/\1/')
                STATUS="in_progress"
                STARTED_AT=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
            else
                echo ""
                echo "📋 Resume Milestone"
                echo ""
                echo "No resume state found."
                echo ""
                exit 0
            fi
        else
            echo ""
            echo "📋 Resume Milestone"
            echo ""
            echo "No resume state found."
            echo ""
            echo "Resume state is created when you run /wiz:next."
            echo "It allows you to continue work after interruptions."
            echo ""
            echo "To start working:"
            echo "  Run: /wiz:next"
            echo ""
            exit 0
        fi
    else
        echo ""
        echo "📋 Resume Milestone"
        echo ""
        echo "No resume state found."
        echo ""
        echo "Resume state is created when you run /wiz:next."
        echo "It allows you to continue work after interruptions."
        echo ""
        echo "To start working:"
        echo "  Run: /wiz:next"
        echo ""
        exit 0
    fi
else
    # Read resume state from legacy file
    STATUS=$(jq -r '.status // "unknown"' "$RESUME_STATE_FILE")
    MILESTONE_ID=$(jq -r '.milestone_id // "unknown"' "$RESUME_STATE_FILE")
    SLUG=$(jq -r '.slug // "unknown"' "$RESUME_STATE_FILE")
    PHASE_NUM=$(jq -r '.phase_number // "unknown"' "$RESUME_STATE_FILE")
    PHASE_FILE=$(jq -r '.phase_file // "unknown"' "$RESUME_STATE_FILE")
    STARTED_AT=$(jq -r '.started_at // "unknown"' "$RESUME_STATE_FILE")
fi

wiz_log_info "Resume state found: $MILESTONE_ID (status: $STATUS)"
```

### Step 2: Handle Resume State Status

```bash
# Check if milestone is complete
if [[ "$STATUS" == "complete" ]]; then
    echo ""
    echo "✅ Milestone Already Complete"
    echo ""
    echo "Milestone: $MILESTONE_ID"
    if [[ -f "$RESUME_STATE_FILE" ]]; then
        echo "Completed at: $(jq -r '.completed_at // "unknown"' "$RESUME_STATE_FILE")"
    fi
    echo ""
    echo "Resume state is stale. Clearing it."
    rm -f "$RESUME_STATE_FILE"
    echo ""
    echo "Run /wiz:next to continue to the next milestone"
    echo ""
    exit 0
fi

# Check if milestone status is not in_progress
if [[ "$STATUS" != "in_progress" ]]; then
    echo ""
    echo "⚠️  Invalid Resume State"
    echo ""
    echo "Resume state status: $STATUS"
    echo "Expected: in_progress"
    echo ""
    echo "Clearing stale resume state."
    rm -f "$RESUME_STATE_FILE"
    echo ""
    echo "Run /wiz:next to start fresh"
    echo ""
    exit 0
fi

# Validate phase file exists
if [[ ! -f "$PHASE_FILE" ]]; then
    echo ""
    echo "❌ Error: Phase file not found"
    echo ""
    echo "Phase file: $PHASE_FILE"
    echo "This may indicate the project structure has changed."
    echo ""
    echo "Clearing invalid resume state."
    rm -f "$RESUME_STATE_FILE"
    echo ""
    exit 1
fi
```

### Step 3: Load Milestone Context

```bash
# Extract milestone information
MILESTONE_SECTION=$(wiz_extract_milestone_section "$PHASE_FILE" "$MILESTONE_ID")

if [[ -z "$MILESTONE_SECTION" ]]; then
    echo ""
    echo "❌ Error: Milestone not found in phase file"
    echo ""
    echo "Milestone: $MILESTONE_ID"
    echo "Phase file: $PHASE_FILE"
    echo ""
    echo "Clearing invalid resume state."
    rm -f "$RESUME_STATE_FILE"
    echo ""
    exit 1
fi

# Extract milestone title
MILESTONE_TITLE=$(echo "$MILESTONE_SECTION" | grep "^### ${MILESTONE_ID}:" | sed -E 's/^### [^:]+: //')

# Extract goal
MILESTONE_GOAL=$(echo "$MILESTONE_SECTION" | awk '/^\*\*Goal\*\*/,/^\*\*Acceptance Criteria\*\*/' | grep -v '^\*\*' | sed '/^$/d')

# Calculate elapsed time
CURRENT_TIME=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
if [[ "$STARTED_AT" != "unknown" ]] && command -v date >/dev/null 2>&1; then
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS date command
        ELAPSED_SECONDS=$(( $(date -j -f "%Y-%m-%dT%H:%M:%SZ" "$CURRENT_TIME" +%s) - $(date -j -f "%Y-%m-%dT%H:%M:%SZ" "$STARTED_AT" +%s) ))
    else
        # Linux date command
        ELAPSED_SECONDS=$(( $(date -d "$CURRENT_TIME" +%s) - $(date -d "$STARTED_AT" +%s) ))
    fi
    ELAPSED_MINUTES=$((ELAPSED_SECONDS / 60))
    ELAPSED_HOURS=$((ELAPSED_MINUTES / 60))

    if [[ $ELAPSED_HOURS -gt 0 ]]; then
        ELAPSED_TIME="${ELAPSED_HOURS}h ${ELAPSED_MINUTES}m"
    elif [[ $ELAPSED_MINUTES -gt 0 ]]; then
        ELAPSED_TIME="${ELAPSED_MINUTES}m"
    else
        ELAPSED_TIME="${ELAPSED_SECONDS}s"
    fi
else
    ELAPSED_TIME="unknown"
fi
```

### Step 4: Display Resume Context

```bash
echo ""
echo "📋 Resume Milestone"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Milestone: $MILESTONE_ID"
echo "Title: $MILESTONE_TITLE"
echo ""
echo "PRD: $SLUG"
echo "Phase: $PHASE_NUM"
echo ""
echo "Started: $STARTED_AT"
echo "Elapsed: $ELAPSED_TIME"
echo ""
echo "Goal"
echo "────"
echo "$MILESTONE_GOAL"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
```

### Step 5: Offer Options

**Note**: In Cursor, interactive prompts may not work the same way. Adapt this to work with the Cursor interface:

```bash
echo "Options:"
echo "  1. Continue working on this milestone"
echo "  2. Skip to next TODO milestone"
echo "  3. Cancel"
echo ""
echo "Choose an option (1-3): "
# Note: In Cursor, you may need to adapt this to work without read -p
# The user will indicate their choice in the chat

# For now, default to option 1 (continue)
CHOICE="${1:-1}"

case "$CHOICE" in
    1)
        echo ""
        echo "▶️  Continuing milestone: $MILESTONE_ID"
        echo ""
        # Commands implement directly (no delegation)
        # Display the full milestone context
        echo "$MILESTONE_SECTION"
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        echo "Continue implementing this milestone."
        echo "When complete, the milestone status will be updated automatically."
        echo ""
        ;;

    2)
        echo ""
        echo "⏭️  Skipping milestone: $MILESTONE_ID"
        echo ""

        # Clear resume state
        rm -f "$RESUME_STATE_FILE"
        wiz_log_info "Cleared resume state"

        # Find next milestone using simple increment logic
        NEXT_JSON=$(wiz_find_next_milestone "$SLUG")

        if [[ "$NEXT_JSON" == "\"COMPLETED\"" ]]; then
            echo "🎉 No more milestones!"
            echo ""
            echo "All milestones are complete."
            echo "Run /wiz:status to see final progress."
            echo ""
        else
            NEXT_ID=$(echo "$NEXT_JSON" | jq -r '.id')
            NEXT_TITLE=$(echo "$NEXT_JSON" | jq -r '.title')

            echo "Next milestone:"
            echo "  $NEXT_ID: $NEXT_TITLE"
            echo ""
            echo "Run /wiz:next to begin"
            echo ""
        fi
        ;;

    3)
        echo ""
        echo "❌ Cancelled"
        echo ""
        echo "Resume state preserved."
        echo "Run /wiz:resume again when ready to continue."
        echo ""
        exit 0
        ;;

    *)
        echo ""
        echo "Invalid choice: $CHOICE"
        echo ""
        echo "Run /wiz:resume again and choose 1, 2, or 3"
        echo ""
        exit 1
        ;;
esac
```

## Output Example

```
📋 Resume Milestone
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Milestone: P02M11
Title: Implement JWT token validation

PRD: auth-system
Phase: 2

Started: 2025-01-19T10:30:00Z
Elapsed: 1h 45m

Goal
────
Add JWT token validation to the authentication middleware. Tokens should
be validated for signature, expiration, and required claims.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Options:
  1. Continue working on this milestone
  2. Skip to next TODO milestone
  3. Cancel

Choose an option (1-3): 1

▶️  Continuing milestone: P02M11

[Milestone section displayed with full acceptance criteria]

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Continue implementing this milestone.
When complete, the milestone status will be updated automatically.
```

## Direct Implementation

When option 1 is chosen, the command implements the milestone directly (no delegation):

**Prompt Template**:

```
Resume milestone: {MILESTONE_ID}

## Context

You were working on this milestone and the work was interrupted.

### Milestone Details

{MILESTONE_SECTION}

### Session Info

- Started: {STARTED_AT}
- Elapsed time: {ELAPSED_TIME}
- Phase: {PHASE_NUM}

### Phase Context

{PHASE_CONTENT}

{DESIGN_GUIDELINES}

## Your Task

1. Review the milestone goal and acceptance criteria
2. Check what work has already been completed (look for files, tests, commits)
3. Continue implementation from where it was left off
4. Complete any remaining acceptance criteria
5. Validate all criteria are met

## Important Notes

- This is a **resume** operation - some work may already be done
- Check git history and file timestamps to understand current state
- Don't redo work that's already complete
- Focus on completing remaining acceptance criteria
- When done, report completion with evidence

## Output

When complete, provide:
1. Summary of work completed in this session
2. Evidence for each acceptance criterion
3. Recommendation: mark milestone as COMPLETE or needs more work
```

## Error Handling

- **No resume state**: Friendly message explaining resume state
- **Stale resume state**: Clear and offer to start fresh
- **Complete milestone**: Clear resume state, suggest /wiz:next
- **Invalid status**: Clear and start fresh
- **Phase file missing**: Error and clear invalid state
- **Milestone not found**: Error and clear invalid state
- **Invalid choice**: Prompt to try again

## Interactive Flow

The command is interactive and waits for user input:

1. Display context and options
1. Read user choice (1-3) - adapt to Cursor interface
1. Execute chosen action
1. Provide clear feedback

## Notes

- Resume state includes elapsed time calculation
- Goal extracted and displayed for quick context
- Option 1 continues work (implements directly)
- Option 2 skips to next TODO (clears resume state)
- Option 3 cancels and preserves state
- Command validates all state before proceeding
- Stale or invalid state is automatically cleared
- Elapsed time calculated from started_at timestamp
- Supports both legacy `.wiz/.current-milestone.json` and state.json
