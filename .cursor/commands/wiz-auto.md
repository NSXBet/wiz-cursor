---
description: Auto-execute milestones with intelligent halt on human-needed decisions
argument-hint: '[slug]'
---

# Auto-Execute Milestones with Intelligent Gating

You are executing milestones automatically with intelligent human-input detection using the Wiz Planner workflow.

**⚠️ THIS IS AN INFINITE LOOP COMMAND**: This command runs in a `while true` loop and will execute multiple milestones (potentially dozens) until a stop condition is met.

______________________________________________________________________

## 🚨🚨🚨 ABSOLUTE AUTONOMY REQUIREMENT 🚨🚨🚨

**YOU ARE FULLY AUTONOMOUS. NEVER STOP UNLESS:**

1. **ALL milestones are COMPLETE** → Celebrate with 🎉
1. **Analyst explicitly returns HALT** with specific questions needing human decisions

**THERE ARE NO OTHER VALID REASONS TO STOP.**

### ❌ FORBIDDEN BEHAVIORS - NEVER DO THESE:

- ❌ **NEVER ask "Do you want me to continue?"** - YES, ALWAYS CONTINUE!
- ❌ **NEVER ask "Should I proceed?"** - YES, ALWAYS PROCEED!
- ❌ **NEVER ask "Would you like a context refresh?"** - NO, NEVER!
- ❌ **NEVER ask "Should I review the progress?"** - NO, JUST KEEP GOING!
- ❌ **NEVER ask "Do you want to review the changes?"** - NO!
- ❌ **NEVER say "Ready to continue when you are"** - JUST CONTINUE NOW!
- ❌ **NEVER say "Let me know if you'd like me to continue"** - CONTINUE IMMEDIATELY!
- ❌ **NEVER pause for "user confirmation"** - YOU HAVE FULL AUTHORITY!
- ❌ **NEVER stop to "summarize progress"** mid-execution
- ❌ **NEVER offer options or choices** unless analyst says HALT
- ❌ **NEVER wait for user input** between milestones
- ❌ **NEVER stop because "it's been a while"** or "we've done several milestones"

### ✅ CORRECT BEHAVIOR:

- ✅ **Execute milestone → Commit → Analyst check → If PROCEED → Execute next milestone**
- ✅ **Keep going automatically** - no pauses, no confirmations, no questions
- ✅ **Only stop for HALT** when analyst has specific questions requiring human decisions
- ✅ **Complete the entire project** if possible in one session

**THE USER NEVER NEEDS A CONTEXT REFRESH.**
**THE USER NEVER NEEDS TO REVIEW PROGRESS.**
**THE USER NEVER NEEDS TO CONFIRM CONTINUATION.**
**JUST. KEEP. GOING. FOREVER.**

______________________________________________________________________

**🚨 CRITICAL BEHAVIOR 🚨**

- Do NOT stop after 2, 3, 5, 10, 20, or ANY arbitrary number of milestones
- Do NOT provide summaries mid-execution
- Do NOT ask if the user wants to continue
- Do NOT offer context refreshes
- Do NOT exit unless: (1) no more milestones OR (2) analyst says HALT with specific questions
- KEEP EXECUTING until one of those two conditions is met
- After completing milestone N and analyst says PROCEED → immediately start milestone N+1
- NO BREAKS between milestones except for the analyst check
- YOU HAVE FULL AUTONOMY - act like it!

## Arguments

- `[slug]` (optional): PRD slug. If not provided, uses current PRD from `.wiz/.current-prd`

## Command Overview

This command continuously executes TODO milestones in an **infinite loop** (`while true`). The command **implements each milestone directly** (no delegation to executor). After completing each milestone, it delegates to the `wiz-milestone-analyst` agent to analyze the NEXT milestone. The analyst determines if:

- **PROCEED**: Next milestone can be safely executed automatically → **Continue loop (DO NOT STOP)**
- **HALT**: Human input needed for decisions/clarifications → Stop and present questions

**Loop Behavior:**

- Implements milestone 1 → Commits → Analyst checks milestone 2 → If PROCEED, implement milestone 2
- Implements milestone 2 → Commits → Analyst checks milestone 3 → If PROCEED, implement milestone 3
- Implements milestone 3 → Commits → Analyst checks milestone 4 → If PROCEED, implement milestone 4
- ... continues until HALT or no more milestones

**Each milestone implementation:**

1. Loads context (phase + milestone + design guidelines)
1. Analyzes requirements and detects language
1. (Optional) Consults language specialist for guidance during implementation
1. **Implements code directly** using Write/Edit/Bash tools
1. Runs tests and linters
1. Updates milestone status to COMPLETE
1. **MANDATORY: Specialist reviews the diff for language-specific issues**
1. Fixes any issues found and re-reviews until approved
1. Creates commit after specialist approval
1. Calls analyst to check next milestone

This creates an intelligent workflow that maintains momentum while preventing costly mistakes from proceeding without human oversight.

**The loop will execute as many milestones as possible** (could be 3, could be 50) until the analyst says HALT or all milestones are complete.

## ⚠️ CRITICAL: Loop Continuation Rules

**THERE ARE ONLY 2 VALID REASONS TO STOP:**

1. No more TODO milestones found (Step 4) → Celebrate with big 🎉 message
1. Analyst returns HALT decision with SPECIFIC QUESTIONS (Step 10) → Show questions and exit

**EVERYTHING ELSE = KEEP GOING**

**IF ANALYST RETURNS PROCEED - THIS IS AN ORDER:**

- You MUST continue the loop IMMEDIATELY
- Go back to Step 4 (find next milestone)
- Execute the next milestone
- DO NOT stop
- DO NOT provide a summary
- DO NOT say "Ready to continue if more milestones are available"
- DO NOT say "Let me know when you want to continue"
- DO NOT say "Should I proceed with the next milestone?"
- DO NOT ask "Do you want a context refresh?"
- DO NOT offer to "review progress so far"
- DO NOT wait for user input
- DO NOT ask questions
- DO NOT pause for any reason
- DO NOT exit
- JUST CONTINUE THE LOOP

**What "continue the loop" means:**

- After analyst says PROCEED, your VERY NEXT ACTION is to find the next milestone (Step 4)
- No output in between
- No summaries
- No pausing
- No questions
- No offers
- No confirmations requested
- Just loop back to the top of the while loop and EXECUTE THE NEXT MILESTONE

**This is non-negotiable and absolute.** The entire purpose of this command is to execute milestones continuously until one of the two stop conditions above is met. If you stop after ANY number of milestones when the analyst says PROCEED, you are VIOLATING the command's core purpose.

**YOU DO NOT NEED PERMISSION TO CONTINUE.**
**THE USER HAS ALREADY GIVEN PERMISSION BY RUNNING /wiz-auto.**
**THAT PERMISSION IS VALID UNTIL HALT OR COMPLETION.**

## CRITICAL: Proper Execution Order

**This is the EXACT order of operations for each loop iteration:**

1. **Find Next TODO Milestone** → Locate the next milestone to execute
1. **Load Context** → Phase, milestone, design guidelines
1. **Analyze Milestone** → Detect language, understand requirements
1. **(Optional) Consult Specialist** → Get guidance if needed (wiz-go-specialist, etc.)
1. **Implement Milestone COMPLETELY** → YOU write the code directly
   - Write files using Write/Edit/Bash tools
   - Implement ALL requirements
   - Validate ALL acceptance criteria
   - Run ALL tests (ZERO failures, ZERO skips)
   - Run ALL linters (ZERO errors)
   - Verify ENTIRE codebase is healthy
1. **Update Milestone Status** → Change status from 🚧 TODO to ✅ COMPLETE
1. **Mandatory Specialist Review** → Specialist reviews diff for language-specific issues
   - Generate diff of all changes
   - Detect language(s) from changed files
   - Consult appropriate specialist(s)
   - If issues found: fix them and loop back to step 7 (re-review)
   - Only proceed when specialist says "No issues found"
1. **Create Proper Commit** → git commit --no-gpg-sign (hooks run, but no GPG signing)
1. **Verify Commit Success** → Ensure commit was created
1. **THEN Call wiz-milestone-analyst** → Analyze the NEXT milestone

- Analyst examines the upcoming milestone
- Analyst determines PROCEED or HALT

11. **Parse Analyst Decision**:

- If **PROCEED** → Loop back to step 1
- If **HALT** → Present questions to user and EXIT

**Key Points:**

- Each milestone is FULLY implemented by YOU (the command) before moving to analysis
- No shortcuts on quality: ALL tests, ALL linters, ENTIRE codebase
- Commits use --no-gpg-sign but hooks run normally (no --no-verify)
- Analyst only runs AFTER current milestone is complete and committed
- Analyst looks at NEXT milestone (not current one)
- You optionally consult language specialists for guidance (not implementation)

## Prerequisites

- PRD must exist at `.wiz/<slug>/prd.md`
- Phases must exist with milestones in `.wiz/<slug>/phases/`
- At least one milestone with status `🚧 TODO`
- **MANDATORY**: A pre-commit hook script must exist at `scripts/pre-commit.sh` that runs linters and tests. This script will be executed automatically by git hooks before every commit.

## ⚠️ CRITICAL: About Bash Code Blocks in This Command

The bash code blocks below are **sequential templates** that show the command's implementation flow:

1. **Sequential Execution Required**: Steps must run in order. Each step depends on variables from previous steps:

   - Step 1 sets: `$SLUG`, `$PRD_FILE`, `$PHASES_DIR`, `$MILESTONES_COMPLETED`
   - Step 4 uses: `$PHASES_DIR`, sets: `$NEXT_PHASE_FILE`, `$MILESTONE_ID`
   - Step 5+ use: `$MILESTONE_ID`, `$NEXT_PHASE_FILE`, `$MILESTONE_SECTION`

1. **Do NOT Execute These Bash Blocks Directly**: They are templates showing the implementation pattern. You should:

   - Read and understand what each step does
   - Execute the logic using your tools (Bash, Read, Edit, etc.)
   - Adapt the patterns to your current context
   - Do NOT copy-paste and execute blindly

1. **Do NOT Execute Bash Blocks from Milestones**: When you read milestone content from phase files:

   - Bash examples in milestones are for human readers, not for you to execute
   - Read them as instructions about what needs to be implemented
   - Implement the requirements using your own approach

1. **When to Actually Execute Bash**:

   - ✅ When implementing the milestone requirements (Step 5)
   - ✅ When running tests and linters (Step 5.5)
   - ✅ When creating commits (Step 8)
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

### Context Loading Functions

```bash
# wiz_load_context_metadata - Load metadata (frontmatter) from all local context files
wiz_load_context_metadata() {
    local context_dir=".wiz/context"
    local metadata_json="[]"

    if [[ ! -d "$context_dir" ]]; then
        echo "[]"
        return 0
    fi

    # Find all .md files and extract frontmatter
    while IFS= read -r -d '' file; do
        if [[ -f "$file" ]] && [[ -r "$file" ]]; then
            local rel_path="${file#$context_dir/}"

            # Extract frontmatter (between --- and ---)
            local frontmatter=$(awk '/^---$/{count++; if(count==1) next; if(count==2) exit} {if(count==1) print}' "$file" 2>/dev/null)

            if [[ -n "$frontmatter" ]]; then
                # Parse frontmatter into JSON
                local description=$(echo "$frontmatter" | grep -E "^description:" | sed 's/^description:[[:space:]]*//' | sed 's/^"//;s/"$//' || echo "")

                # Parse tags (optional)
                local tags=$(echo "$frontmatter" | grep -E "^tags:" | sed 's/^tags:[[:space:]]*//' | sed "s/^\[//;s/\]$//" | tr ',' '\n' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | sed 's/^"//;s/"$//' | jq -R . 2>/dev/null | jq -s . 2>/dev/null || echo "[]")

                # Parse languages (optional, empty means applies to all)
                local languages=$(echo "$frontmatter" | grep -E "^languages:" | sed 's/^languages:[[:space:]]*//' | sed "s/^\[//;s/\]$//" | tr ',' '\n' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | sed 's/^"//;s/"$//' | jq -R . 2>/dev/null | jq -s . 2>/dev/null || echo "[]")

                # Parse applies_to (optional, empty means applies to everything)
                local applies_to=$(echo "$frontmatter" | grep -E "^applies_to:" | sed 's/^applies_to:[[:space:]]*//' | sed "s/^\[//;s/\]$//" | tr ',' '\n' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | sed 's/^"//;s/"$//' | jq -R . 2>/dev/null | jq -s . 2>/dev/null || echo "[]")

                # Build JSON entry (only if description exists)
                if [[ -n "$description" ]]; then
                    local entry=$(jq -n \
                        --arg path "$rel_path" \
                        --arg desc "$description" \
                        --argjson tags "$tags" \
                        --argjson langs "$languages" \
                        --argjson applies "$applies_to" \
                        '{
                            path: $path,
                            description: $desc,
                            tags: $tags,
                            languages: $langs,
                            applies_to: $applies
                        }' 2>/dev/null)

                    if [[ -n "$entry" ]]; then
                        metadata_json=$(echo "$metadata_json" | jq --argjson entry "$entry" '. += [$entry]' 2>/dev/null || echo "$metadata_json")
                    fi
                fi
            fi
        fi
    done < <(find "$context_dir" -type f -name "*.md" -print0 2>/dev/null | sort -z)

    echo "$metadata_json"
}

# wiz_load_context_file - Load full content of a specific context file (without frontmatter)
wiz_load_context_file() {
    local context_file="$1"
    local full_path=".wiz/context/$context_file"

    if [[ ! -f "$full_path" ]]; then
        echo ""
        return 1
    fi

    # Return file content (skip frontmatter - everything after second ---)
    awk '/^---$/{count++; if(count==2) flag=1; next} flag' "$full_path"
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

### Step 1: Initialize

```bash
#!/usr/bin/env bash
set -euo pipefail

# Parse arguments
SLUG="${1:-}"

# If no slug provided, read from current PRD state
if [[ -z "$SLUG" ]]; then
    if [[ -f ".wiz/.current-prd" ]]; then
        SLUG=$(cat .wiz/.current-prd)
        wiz_log_info "Using current PRD: $SLUG"
    else
        wiz_log_error "No slug provided and no current PRD set"
        echo "Usage: /wiz-auto [slug]"
        echo "Or set current PRD with /wiz-prd or /wiz-phases first"
        exit 1
    fi
fi

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

wiz_log_info "Starting auto-execution for PRD: $SLUG"
```

### Step 2: Check for Resume State

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
        echo "  1. Resume this milestone and continue auto-execution"
        echo "  2. Skip to next TODO milestone"
        echo ""
        echo "Use /wiz-resume to resume the current milestone"
        echo "Or delete $RESUME_STATE_FILE to skip to next"
        exit 0
    fi
fi
```

### Step 3: Load Local Context Metadata (Once Before Loop)

**⚠️ Load context metadata ONCE before the loop - reuse inside loop.**

```bash
# Load context metadata ONCE before loop (for efficiency)
CONTEXT_METADATA=$(wiz_load_context_metadata)
if [[ "$CONTEXT_METADATA" != "[]" ]] && [[ -n "$CONTEXT_METADATA" ]]; then
    wiz_log_info "Found local context files in .wiz/context/"
    export CONTEXT_METADATA
fi
```

**Note**: Metadata is loaded once since it doesn't change between milestones. AI can decide which files to read per milestone.

### Step 4: Main Execution Loop

This is where the auto-execution loop happens. For each iteration:

1. **Find Next TODO Milestone**
1. **If no milestone found → CELEBRATE and exit**
1. **Load Execution Context**
1. **Create Resume State**
1. **Implement the Milestone** ← YOU write the code directly
1. **Update Milestone Status**
1. **Mandatory Specialist Review** ← Specialist reviews diff, fix issues if found
1. **Create Commit** ← git commit --no-gpg-sign (after specialist approval)
1. **Analyze NEXT Milestone** ← Uses milestone-analyst agent
1. **If PROCEED → Continue loop**
1. **If HALT → Present questions and exit**

**IMPORTANT**: The command implements code directly in Step 5. Only Step 9 uses agent invocation to delegate to the milestone-analyst. The specialist review in Step 7 is also done via agent invocation but may loop multiple times until approval.

```bash
# Initialize loop counter
MILESTONES_COMPLETED=0

while true; do
    wiz_log_info "Loop iteration $((MILESTONES_COMPLETED + 1)): Finding next milestone..."

    # Find next milestone using simple increment logic
    # Logic:
    # 1. Find last COMPLETE milestone (e.g., P01M08)
    # 2. Try next milestone in same phase (P01M09)
    # 3. If not found, try first milestone of next phase (P02M01)
    # 4. If not found, project is complete
    NEXT_MILESTONE_JSON=$(wiz_find_next_milestone "$SLUG")

    # Check if project is complete
    if [[ "$NEXT_MILESTONE_JSON" == "\"COMPLETED\"" ]]; then
        echo ""
        echo "🎉 🎉 🎉 ALL MILESTONES COMPLETE! 🎉 🎉 🎉"
        echo ""
        echo "Completed $MILESTONES_COMPLETED milestone(s) in this auto-execution run!"
        echo "No more milestones to execute."
        echo ""
        echo "🚀 Congratulations - the project is complete! 🚀"
        echo ""
        echo "Run /wiz-status to see final statistics"
        exit 0
    fi

    # Extract milestone metadata
    MILESTONE_ID=$(echo "$NEXT_MILESTONE_JSON" | jq -r '.id')
    MILESTONE_TITLE=$(echo "$NEXT_MILESTONE_JSON" | jq -r '.title')
    NEXT_PHASE_NUM=$(echo "$NEXT_MILESTONE_JSON" | jq -r '.phase_number')
    NEXT_PHASE_FILE=$(echo "$NEXT_MILESTONE_JSON" | jq -r '.phase_file')

    wiz_log_info "Found next milestone: $MILESTONE_ID - $MILESTONE_TITLE"

    # Load execution context (context metadata already loaded before loop)
    PHASE_CONTENT=$(cat "$NEXT_PHASE_FILE")
    MILESTONE_SECTION=$(awk "/^### ${MILESTONE_ID}:/,/^---$|^### [A-Z0-9]+:/" "$NEXT_PHASE_FILE" | sed '$ d')

    # Load design guidelines (if they exist)
    DESIGN_GUIDELINES=""
    if [[ -d ".wiz/$SLUG/design-guidelines" ]]; then
        for GUIDELINE_FILE in .wiz/$SLUG/design-guidelines/*.md; do
            if [[ -f "$GUIDELINE_FILE" ]]; then
                LANG=$(basename "$GUIDELINE_FILE" .md)
                DESIGN_GUIDELINES+="## Design Guidelines: $LANG\n\n"
                DESIGN_GUIDELINES+="$(cat "$GUIDELINE_FILE")\n\n"
            fi
        done
    fi

    # Context metadata is available from Step 3 (loaded before loop and exported)

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

    wiz_log_info "Created resume state for $MILESTONE_ID"

    echo ""
    echo "🚀 Executing Milestone $((MILESTONES_COMPLETED + 1)): $MILESTONE_ID"
    echo ""
    echo "$MILESTONE_SECTION"
    echo ""
    echo "---"
    echo ""
done
```

### Step 5: Implement the Milestone

**YOU (the command) now implement the milestone directly. Do NOT delegate to any executor.**

#### 5.1: Analyze Milestone

From `$MILESTONE_SECTION`, understand:

- Goal of the milestone
- Acceptance criteria to satisfy
- Files mentioned (detect language from extensions)

#### 5.2: Detect Language

From file paths in milestone:

- `.go` → Go project
- `.ts`, `.tsx`, `.js`, `.jsx` → TypeScript/JavaScript
- `.py` → Python
- `.cs` → C#
- `.java` → Java

#### 5.3: (Optional) Consult Specialist

**You can consult specialists when you need help with:**

- ✅ **Figuring out the right coding strategy** for the milestone
- ✅ **Determining test commands** for the project's language/stack
- ✅ **Understanding assertion patterns** (e.g., for Go: should I use require.\* methods?)
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

#### 5.4: Write Code Using Your Tools

**Use Write tool for new files:**

- Create new files with the Write tool
- Provide complete file content

**Use Edit tool for modifications:**

- Edit existing files with the Edit tool
- Provide old_string and new_string for replacements

**Use Bash tool for file operations:**

- Create directories, run commands, etc.

#### 5.5: Run Tests and Linters

**If you're unsure about test commands for the project's language/stack, consult the specialist first (see Step 5.3).**

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

**CRITICAL**: Fix any failures before proceeding. If tests or linters fail and you're unsure how to fix them, consult the language specialist for guidance.

**🚨 LINT ERROR POLICY 🚨**:

- **ALWAYS fix lint errors** - Do NOT add lint ignores (e.g., `// eslint-disable`, `# noqa`, `# pylint: disable`) unless it is genuinely not feasible to fix the error
- If you encounter a lint error, first attempt to fix it properly
- Only add lint ignores as a last resort when fixing would require significant architectural changes or when the lint rule is incorrect for the specific use case
- When adding a lint ignore, include a comment explaining why it's necessary

#### 5.6: Validate Acceptance Criteria

Check each criterion from milestone is satisfied. If not, implement missing pieces.

After completing implementation, continue to Step 6.

### Step 6: Update Milestone Status

After YOU complete the milestone implementation:

```bash
# Mark all acceptance criteria as complete
wiz_mark_acceptance_criteria "$NEXT_PHASE_FILE" "$MILESTONE_ID"

# Update milestone status to COMPLETE
wiz_complete_milestone "$NEXT_PHASE_FILE" "$MILESTONE_ID"

# Update resume state
COMPLETED_AT=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

jq --arg completed_at "$COMPLETED_AT" \
   '.status = "complete" | .completed_at = $completed_at' \
   "$RESUME_STATE_FILE" > "${RESUME_STATE_FILE}.tmp"
mv "${RESUME_STATE_FILE}.tmp" "$RESUME_STATE_FILE"

wiz_log_info "Updated milestone status to COMPLETE"
```

### Step 7: Mandatory Specialist Review of Changes

**⚠️ CRITICAL: Specialist review is REQUIRED before committing.**

Before creating the commit, the language specialist MUST review all changes to catch language-specific issues (e.g., using `t.Errorf` instead of `require.*` in Go).

#### 7.1: Generate Diff and Detect Language

**⚠️ CRITICAL: You MUST send the COMPLETE diff to the specialist.**

The specialist review is **worthless** if you only send partial files. Common mistakes:

- ❌ Only sending source files (writer.go) but not tests (writer_test.go)
- ❌ Only sending "main" files and skipping related files
- ❌ Filtering out test files, config files, or markdown files
- ❌ Truncating the diff because it's "too large"

**CORRECT approach - Include ALL code:**

- ✅ Include ALL source files (.go, .ts, .py, .cs, .java, etc.)
- ✅ Include ALL test files (\_\_test.go, \_.test.ts, test\_\*.py, etc.)
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

#### 7.2: Consult ALL Specialists in Parallel

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

When you need to consult specialists, reference the appropriate agent files:

- For Go: `.cursor/agents/wiz-go-specialist.md`
- For TypeScript: `.cursor/agents/wiz-typescript-specialist.md`
- For Python: `.cursor/agents/wiz-python-specialist.md`
- For C#: `.cursor/agents/wiz-csharp-specialist.md`
- For Java: `.cursor/agents/wiz-java-specialist.md`
- For Docker: `.cursor/agents/wiz-docker-specialist.md`

**When calling specialists, include the following context metadata section:**

```
## 🏠 Available Local Context

The following local context files are available. **YOU MUST CHECK THESE FIRST** before providing recommendations.

{CONTEXT_METADATA_JSON}

**Your Task:**
1. Review the metadata above
2. If any context files seem relevant (based on languages, tags, description), read them using: `wiz_load_context_file("<path>")`
3. **If local context addresses the topic** → Use that guidance, acknowledge it explicitly
4. **If local context conflicts with your recommendations** → Explicitly state: "Local context specifies X, deferring to that over my recommendation of Y"
5. **If no relevant local context** → Provide your expert recommendation as usual

**Priority**: Local context > Your recommendations > General best practices

**Relevance Criteria:**
- If `languages` is empty array → applies to all languages → relevant
- If `languages` includes your language → relevant
- If `tags` match the topic (e.g., "frameworks", "patterns") → relevant
- If `description` suggests it's relevant → relevant

---

## Milestone Context
[Milestone details...]

## Changes to Review
[Diff...]
```

**Do NOT wait for one specialist to finish before calling the next. Call them ALL at once.**

#### 7.3: Aggregate Reviews and Fix Issues

After ALL specialists respond, aggregate their reviews:

**Aggregate all issues from all specialists:**

1. **Collect issues from ALL specialist responses**
1. **If ANY specialist found issues:**
   - Display ALL issues from ALL specialists
   - Fix EACH issue using Edit tool or Bash
   - **CRITICAL: Loop back to Step 7.1** - Do NOT proceed forward!
   - Generate new diff (Step 7.1)
   - Consult ALL specialists again with new diff (Step 7.2)
   - Parse the new reviews (Step 7.3)
   - Repeat until ALL specialists approve
1. **Do NOT proceed to Step 8** until ALL specialists say "No issues found"

**IF ALL SPECIALISTS say "No issues found" or "Review Complete":**

1. Proceed to Step 8 (Create Commit)

### Step 8: Create Narrative Commit (NO Hook Skipping)

**CRITICAL**: Create a proper commit WITHOUT skipping hooks, but skip GPG signing to avoid signing issues.

**🚨 ABSOLUTE PROHIBITION 🚨**:

- **NEVER use `git commit --no-verify`** - This is COMPLETELY FORBIDDEN
- The pre-commit hook at `scripts/pre-commit.sh` MUST run before every commit
- If the pre-commit hook fails, you MUST fix the issues (tests, linters) before committing
- Skipping hooks defeats the purpose of quality gates and is strictly prohibited

After specialist approval:

```bash
git add "$NEXT_PHASE_FILE"

COMMIT_MSG="feat(${MILESTONE_ID}): ${MILESTONE_TITLE}

Completed milestone ${MILESTONE_ID} via auto-execution.

🤖 Generated with Wiz Planner

Co-Authored-By: Wiz <wiz@flutterbrazil.com>"

# IMPORTANT:
# - YES to --no-gpg-sign (avoid GPG signing issues)
# - NO to --no-verify (let hooks run for quality checks - THIS IS MANDATORY)
# - The pre-commit hook at scripts/pre-commit.sh will run automatically
git commit --no-gpg-sign -m "$COMMIT_MSG"

COMMIT_HASH=$(git rev-parse --short HEAD)

wiz_log_info "Created commit: $COMMIT_HASH"

echo ""
echo "✅ Milestone $((MILESTONES_COMPLETED + 1)) Complete: $MILESTONE_ID"
echo "Commit: $COMMIT_HASH"
echo ""

MILESTONES_COMPLETED=$((MILESTONES_COMPLETED + 1))
```

### Step 9: Analyze NEXT Milestone (AFTER Commit Success)

**This is where the intelligent gating happens.**

**IMPORTANT**: This step only executes AFTER:

- Milestone is fully implemented and tested
- Status updated to COMPLETE
- Commit created successfully (with hooks running)

Now we look ahead to determine if the NEXT milestone can be safely executed or if human input is needed.

```bash
# Find the NEXT milestone (after the one we just completed)
wiz_log_info "Analyzing next milestone for human-input requirements..."

# Use wiz_find_next_milestone to get the next one
LOOKAHEAD_MILESTONE_JSON=$(wiz_find_next_milestone "$SLUG")

# Check if project is complete
if [[ "$LOOKAHEAD_MILESTONE_JSON" == "\"COMPLETED\"" ]]; then
    # This will be caught in next loop iteration, but we can continue here
    continue
fi

if [[ "$LOOKAHEAD_MILESTONE_JSON" == "null" || -z "$LOOKAHEAD_MILESTONE_JSON" ]]; then
    wiz_log_info "No more milestones found - will celebrate in next iteration"
    continue
fi

LOOKAHEAD_ID=$(echo "$LOOKAHEAD_MILESTONE_JSON" | jq -r '.id')
LOOKAHEAD_TITLE=$(echo "$LOOKAHEAD_MILESTONE_JSON" | jq -r '.title')
LOOKAHEAD_PHASE_NUM=$(echo "$LOOKAHEAD_MILESTONE_JSON" | jq -r '.phase_number')
LOOKAHEAD_PHASE_FILE=$(echo "$LOOKAHEAD_MILESTONE_JSON" | jq -r '.phase_file')

LOOKAHEAD_SECTION=$(awk "/^### ${LOOKAHEAD_ID}:/,/^---$|^### [A-Z0-9]+:/" "$LOOKAHEAD_PHASE_FILE" | sed '$ d')
LOOKAHEAD_PHASE_CONTENT=$(cat "$LOOKAHEAD_PHASE_FILE")

wiz_log_info "Analyzing lookahead milestone: $LOOKAHEAD_ID"
```

Now delegate to the **milestone-analyst** agent by referencing `.cursor/agents/wiz-milestone-analyst.md`:

**Agent Reference**: `.cursor/agents/wiz-milestone-analyst.md`

**Prompt to provide:**

```
Analyze the next milestone to determine if human input is needed before proceeding with auto-execution.

## Milestone to Analyze

### Milestone Content

{LOOKAHEAD_SECTION}

### Phase Context

{LOOKAHEAD_PHASE_CONTENT}

## Codebase Context

Project: {SLUG}
Previous Milestone Completed: {MILESTONE_ID}
Milestones Completed This Run: {MILESTONES_COMPLETED}

## Your Task

Analyze this milestone and determine:
1. Are requirements clear and unambiguous?
2. Can this be safely executed without human decisions?
3. Are there design choices or clarifications needed?
4. Is this milestone potentially already complete?
5. Does this require security or architectural judgment?

Provide your analysis in the structured format specified in your agent definition.

**Decision Options:**
- PROCEED: Safe to execute automatically
- HALT: Human input needed (provide specific questions)

Be conservative - when in doubt, choose HALT.
```

### Step 10: Parse Analyst Decision and ENFORCE Loop Continuation

**CRITICAL LOOP LOGIC**: After the analyst returns its analysis, you MUST parse the decision and act accordingly. There are ONLY TWO valid reasons to stop the loop:

1. **No more milestones** → Celebrate (handled in Step 4)
1. **Analyst returns HALT with specific questions** → Show questions and exit

If the analyst returns PROCEED, you MUST continue the loop. DO NOT stop for any other reason.

**🚨 REMINDER: YOU DO NOT NEED TO ASK THE USER ANYTHING 🚨**

- Do NOT ask "Should I continue?"
- Do NOT ask "Do you want a context refresh?"
- Do NOT ask "Would you like to review the changes?"
- Do NOT say "Ready when you are"
- Do NOT offer options
- The user has given you FULL AUTONOMY by running /wiz-auto
- ACT ON THAT AUTONOMY - just keep executing!

After the analyst returns its analysis, parse the decision:

```bash
# The analyst will return structured output with decision
# Parse the decision from the output

# Look for the decision line (analyst should clearly indicate PROCEED or HALT)
ANALYST_DECISION="<extract from analyst output>"

if [[ "$ANALYST_DECISION" == "PROCEED" ]]; then
    wiz_log_info "Analyst recommends PROCEED - continuing to next milestone"
    echo ""
    echo "✅ Next milestone ($LOOKAHEAD_ID) cleared for execution"
    echo "🔄 Continuing auto-execution..."
    echo ""

    # CRITICAL: Continue the loop - go back to Step 4 (find next milestone)
    # This is NOT optional - if analyst says PROCEED, we MUST continue
    # DO NOT stop here
    # DO NOT provide a summary
    # DO NOT say "Auto-execution summary"
    # DO NOT say "Ready to continue"
    # DO NOT exit
    # JUST CONTINUE THE LOOP IMMEDIATELY
    #
    # The 'continue' statement loops back to 'while true' at the top
    # which goes to Step 4 (find next milestone) and continues execution
    continue

elif [[ "$ANALYST_DECISION" == "HALT" ]]; then
    wiz_log_info "Analyst recommends HALT - human input required"

    echo ""
    echo "⚠️  Human Input Required"
    echo ""
    echo "The milestone analyst has determined that the next milestone requires"
    echo "human decision-making before proceeding."
    echo ""
    echo "Next Milestone: $LOOKAHEAD_ID"
    echo ""
    echo "---"
    echo ""
    echo "<ANALYST OUTPUT WITH QUESTIONS>"
    echo ""
    echo "---"
    echo ""
    echo "Auto-execution paused. Completed $MILESTONES_COMPLETED milestone(s)."
    echo ""
    echo "Please review the questions above and either:"
    echo "  - Run /wiz-next to execute the next milestone manually after making decisions"
    echo "  - Run /wiz-auto again to resume auto-execution after clarifications"
    echo "  - Update the milestone acceptance criteria to address ambiguities"
    echo ""

    exit 0
else
    wiz_log_error "Unexpected analyst decision: $ANALYST_DECISION"
    echo "Error: Could not parse analyst decision. Halting auto-execution."
    exit 1
fi
```

### Step 11: Loop Continuation (Back to Step 4)

**What happens after Step 10 when analyst says PROCEED:**

The `continue` statement in the bash if block causes the loop to IMMEDIATELY jump back to Step 4 (the top of the `while true` loop). This means:

1. Find next milestone (Step 4)
1. If found → Execute it (Step 5)
1. Specialist reviews diff (Step 7)
1. Commit it (Step 8)
1. Analyze the next one (Step 9)
1. If PROCEED → Continue to Step 4 again
1. Repeat until HALT or no more milestones

**🚨 CRITICAL: The loop ONLY stops when 🚨**

1. **No more milestones found** (Step 4) → Celebrate with 🎉 message
1. **Analyst recommends HALT** (Step 10) → Present questions and exit
1. **Error occurs** → Exit with error message

**❌ NEVER STOP FOR THESE REASONS:**

- "Completed 2 milestones" - NOT a stop condition
- "Completed 3 milestones" - NOT a stop condition
- "Completed 5 milestones" - NOT a stop condition
- "Ready to continue if more milestones available" - WRONG, just continue!
- "Auto-execution summary" - WRONG, do not summarize mid-loop
- Any arbitrary milestone count - NOT a stop condition

**✅ CORRECT BEHAVIOR:**
After completing milestone N and analyst says PROCEED → Go to Step 4 and start milestone N+1 immediately. No summaries. No stopping. No waiting. Just continue the loop.

**Example:** After completing milestones P01M10, P01M11, P01M12, P01M13, P01M14 (5 milestones) and the analyst says PROCEED each time, you MUST continue to P01M15, then P01M16, then P01M17... until one of the three stop conditions above is met.

## Error Handling

- **No slug and no current PRD**: Show usage and suggest running `/wiz-prd` or `/wiz-phases`
- **Invalid slug format**: Show format requirements
- **PRD not found**: Suggest running `/wiz-prd` first
- **Phases not found**: Suggest running `/wiz-phases` first
- **No milestones found**: Suggest running `/wiz-milestones` first
- **In-progress milestone exists**: Offer to resume or skip
- **Milestone update fails**: Error and exit
- **Tests or linters fail**: Fix issues before proceeding (mandatory)
- **Specialist review fails repeatedly**: Error, show details, halt for manual intervention
- **Commit fails**: Error and recovery steps
- **Analyst decision unclear**: Error and halt

## Implementation Notes

### Milestone-Analyst Integration

The analyst acts as a **gatekeeper** between milestones. Its purpose is to:

- Prevent execution of ambiguous requirements
- Flag decisions that need human judgment
- Identify milestones that might be complete
- Maintain development velocity while preventing costly mistakes

### Loop Safety

The loop is designed to be **safe and resumable**:

- Resume state created before each milestone
- Commits created after each milestone
- Analyst analysis happens after completion
- User can interrupt at any time (Ctrl+C)
- `/wiz-resume` can pick up from interruption

### Performance Characteristics

- **Iteration overhead**: ~2-3 seconds per milestone for analysis
- **Total overhead**: ~5 seconds per milestone (finding + loading + analysis)
- **Benefit**: Prevents 30-60 minutes of rework from unclear requirements

## Example Usage

```bash
# Auto-execute milestones for current PRD
/wiz-auto

# Auto-execute milestones for specific PRD
/wiz-auto my-project

# After analyst halts for human input
# Review questions, make decisions, then either:
/wiz-next              # Execute next milestone manually
/wiz-auto              # Resume auto-execution
```

## Example Outputs

### Example 1: Correct - Analyst Says HALT After 3 Milestones

```
🚀 Starting auto-execution for PRD: my-api

🚀 Executing Milestone 1: P01M01

### P01M01: Setup project structure
...
✅ Milestone 1 Complete: P01M01
Commit: a3f2c91

✅ Next milestone (P01M02) cleared for execution
🔄 Continuing auto-execution...

🚀 Executing Milestone 2: P01M02
...
✅ Milestone 2 Complete: P01M02
Commit: b4e3d82

✅ Next milestone (P01M03) cleared for execution
🔄 Continuing auto-execution...

🚀 Executing Milestone 3: P01M03
...
✅ Milestone 3 Complete: P01M03
Commit: c5f4e93

⚠️  Human Input Required

Next Milestone: P01M04

---

## MILESTONE ANALYSIS

**Milestone ID:** P01M04
**Decision:** HALT

### Analysis Summary
Implement authentication system. Multiple approaches possible (JWT, sessions, OAuth).

### Decision Rationale
Requires architectural decision about auth strategy with long-term implications.

### Human Input Required

**Category:** Design Decision

**Questions:**
1. Which authentication method? (JWT, sessions, OAuth 2.0)
2. What are the session/token expiry requirements?
3. Should we support refresh tokens?

**Suggested Options:**
- Option A: JWT with 24h expiry + refresh tokens
- Option B: Server-side sessions with Redis
- Option C: OAuth 2.0 with external provider

---

Auto-execution paused. Completed 3 milestone(s).

Please review the questions above and either:
  - Run /wiz-next to execute the next milestone manually
  - Run /wiz-auto to resume after clarifications
```

### Example 2: ❌ WRONG - Stopping Without Justification

**🚨 This is INCORRECT behavior that must NEVER happen 🚨**

**This is exactly like the user's report - stopping after 2-3 milestones:**

```
🚀 Executing Milestone 1: P01M02
✅ Milestone 1 Complete: P01M02
Commit: 4b8555b

✅ Next milestone (P01M03) cleared for execution
🔄 Continuing auto-execution...

🚀 Executing Milestone 2: P01M03
✅ Milestone 2 Complete: P01M03
Commit: fdd85af

✅ Next milestone (P01M04) cleared for execution
🔄 Continuing auto-execution...

🚀 Executing Milestone 3: P01M04
✅ Milestone 3 Complete: P01M04
Commit: 9beb7b0

---
Auto-Execution Summary

Milestones Completed: 3

The auto-execution process completed successfully!
Ready to continue if more milestones are available!
```

**🚨 WHY THIS IS COMPLETELY WRONG 🚨**

- The analyst said "cleared for execution" 3 times (PROCEED decision)
- **YOU MUST CONTINUE THE LOOP** - not stop and summarize!
- There's no HALT message with questions - so why did you stop?
- There's no celebration message for all milestones complete - so there ARE more milestones!
- The loop just stopped arbitrarily after 3 milestones - VIOLATION of command purpose
- "Ready to continue if more milestones available" - **WRONG! Just continue NOW!**

**🚨 OTHER WRONG OUTPUTS THAT ARE FORBIDDEN 🚨**

```
❌ "Should I continue with the next milestone?"
❌ "Would you like me to proceed?"
❌ "Do you need a context refresh before we continue?"
❌ "Let me know when you're ready to continue"
❌ "Would you like to review the changes before proceeding?"
❌ "I can continue when you're ready"
❌ "Should I keep going?"
❌ "Ready to continue when you give the word"
❌ "Do you want me to execute the next milestone?"
```

**ALL OF THESE ARE VIOLATIONS.** The user has already said YES by running /wiz-auto.

**✅ CORRECT BEHAVIOR:**
After milestone 3 complete and analyst says PROCEED for the 4th time:

- **Do NOT** provide a summary
- **Do NOT** say "Ready to continue"
- **Do NOT** ask any questions
- **Do NOT** offer context refresh
- **Do NOT** ask for confirmation
- **Do NOT** stop execution
- **JUST CONTINUE** - Go to Step 4, find P01M05, and execute it!
- Keep going until HALT or no more milestones

The loop should have continued executing P01M05, P01M06, P01M07... P01M25, P02M01... until either:

1. The analyst said HALT and showed questions, OR
1. No more milestones found and showed 🎉 celebration

**THE USER WANTS YOU TO KEEP GOING FOREVER UNTIL:**

- You genuinely need a human decision (analyst HALT), OR
- The project is complete

**THAT'S IT. NO OTHER STOPS. NO QUESTIONS. NO CONFIRMATIONS. JUST KEEP GOING.**

### Example 3: Correct - Full Completion

```
🚀 Executing Milestone 15: P03M08
...
✅ Milestone 15 Complete: P03M08
Commit: x9y8z77

🎉 🎉 🎉 ALL MILESTONES COMPLETE! 🎉 🎉 🎉

Completed 15 milestone(s) in this auto-execution run!
No TODO milestones found across all phases.

🚀 Congratulations - the project is complete! 🚀

Run /wiz-status to see final statistics
```

## Benefits

1. **Maintains Momentum**: Executes as many milestones as safely possible without stopping
1. **Prevents Mistakes**: Halts before ambiguous or decision-heavy milestones
1. **Intelligent Gating**: Uses AI to determine risk rather than blindly proceeding
1. **Clear Communication**: Provides specific questions when human input needed
1. **Resumable**: Can be interrupted and resumed at any time
1. **Auditable**: Each milestone gets its own commit

## When to Use

- **Use `/wiz-auto`** when you want to execute multiple milestones with intelligent oversight
- **Use `/wiz-next`** when you want to execute one milestone at a time manually
- **Use after clarifications**: After analyst halts, make decisions, then resume with `/wiz-auto`

The auto-execution command strikes the right balance between automation and human oversight, allowing the system to maintain velocity while ensuring quality and preventing costly mistakes.

______________________________________________________________________

## 🔥 FINAL REMINDER: FULL AUTONOMY 🔥

When the user runs `/wiz-auto`, they are giving you **COMPLETE PERMISSION** to:

- Execute as many milestones as needed
- Make commits automatically
- Keep going indefinitely

They are **NOT** asking you to:

- Check in with them periodically
- Ask if they want to continue
- Offer context refreshes
- Pause for review

**The user's time is valuable. They ran /wiz-auto specifically because they DON'T want to babysit you.**

**HONOR THAT TRUST. KEEP GOING UNTIL HALT OR COMPLETE. NO EXCEPTIONS.**
