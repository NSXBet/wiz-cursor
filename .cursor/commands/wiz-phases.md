---
description: Generate implementation phases from PRD
argument-hint: <slug>
---

# Generate Implementation Phases

You are breaking down a comprehensive PRD into implementation phases using the Wiz Planner workflow.

## Arguments

- `<slug>`: PRD slug (must exist at `.wiz/<slug>/prd.md`)

## Planning Agent

This command delegates content generation to the **wiz-planner** agent (`.cursor/agents/wiz-planner.md`), which provides verbose, research-focused planning output suitable for strategic phase decomposition.

## Command Overview

This command reads the PRD document and generates 3-15 implementation phases, each containing detailed milestones. Phases represent major blocks of work that build on each other (foundation → features → quality → deployment).

## Prerequisites

- PRD must exist at `.wiz/<slug>/prd.md` (created by `/wiz-prd`)
- PRD should have `status: "Draft"` or `status: "Approved"`

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

### Template Functions

```bash
# wiz_load_template - Load a template file
wiz_load_template() {
    local template_path="$1"

    if [[ ! -f "$template_path" ]]; then
        echo "ERROR: Template file not found: $template_path" >&2
        return 1
    fi

    if [[ ! -r "$template_path" ]]; then
        echo "ERROR: Permission denied reading template: $template_path" >&2
        return 1
    fi

    cat "$template_path"
    return 0
}

# wiz_render_template - Render a template with variable substitution
wiz_render_template() {
    local template="$1"
    shift

    local strict=false
    if [[ "${1:-}" == "--strict" ]]; then
        strict=true
        shift
    fi

    local rendered="$template"

    # Process variable assignments
    while [[ $# -gt 0 ]]; do
        local var_assignment="$1"
        shift

        if [[ ! "$var_assignment" =~ ^[a-zA-Z_][a-zA-Z0-9_]*= ]]; then
            echo "ERROR: Invalid variable assignment: $var_assignment" >&2
            echo "Expected format: VAR=value" >&2
            return 1
        fi

        local var_name="${var_assignment%%=*}"
        local var_value="${var_assignment#*=}"

        # Replace all occurrences of {{var_name}} with var_value
        # Using a temporary delimiter to avoid issues with special characters
        rendered=$(echo "$rendered" | sed "s|{{${var_name}}}|${var_value}|g")
    done

    # Handle escaped braces: \{{ becomes {{
    rendered=$(echo "$rendered" | sed 's|\\{{|{{|g')

    # Check for unresolved placeholders if in strict mode
    if [[ "$strict" == true ]]; then
        if echo "$rendered" | grep -q '{{[^}]*}}'; then
            echo "ERROR: Unresolved placeholders found:" >&2
            echo "$rendered" | grep -o '{{[^}]*}}' | sort -u >&2
            return 1
        fi
    fi

    echo "$rendered"
    return 0
}
```

## Execution Steps

### Step 1: Validate Arguments and Load PRD

```bash
#!/usr/bin/env bash
set -euo pipefail

# Parse arguments
SLUG="${1:-}"

# Validate slug
if [[ -z "$SLUG" ]]; then
    wiz_log_error "Missing slug argument"
    echo "Usage: /wiz-phases <slug>"
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
    echo "Run /wiz-prd $SLUG \"<idea>\" first to create a PRD"
    exit 1
fi

# Check if phases already exist
PHASES_DIR=".wiz/$SLUG/phases"
if [[ -d "$PHASES_DIR" ]] && [[ -n "$(ls -A "$PHASES_DIR" 2>/dev/null)" ]]; then
    wiz_log_error "Phases directory already exists and is not empty: $PHASES_DIR"
    echo "Remove existing phases or use a different slug"
    exit 1
fi

wiz_log_info "Validated arguments - slug: $SLUG"
wiz_log_info "Loading PRD from $PRD_FILE"
```

### Step 2: Create Phases Directory

```bash
# Create phases directory
wiz_ensure_dir "$PHASES_DIR"

wiz_log_info "Created phases directory at $PHASES_DIR"
```

### Step 3: Invoke wiz-planner Agent

The `wiz-planner` agent provides verbose, research-focused planning output suitable for strategic phase decomposition. When you reference `.cursor/agents/wiz-planner.md` in the next step, it will automatically provide comprehensive, detailed phase planning content.

### Step 4: Delegate to wiz-planner Agent

**⚠️ CRITICAL: Agent File Operation Limitation**

Agents invoked via agent references **cannot reliably write files**. This is a known limitation.

**Solution:**
- The `wiz-planner` agent **returns phase contents** as code blocks in its response
- The main agent (you, running /wiz-phases) **performs all Write operations**
- Agent focuses on: phase analysis, phase generation, content synthesis
- Main agent handles: all file I/O operations

Reference the `.cursor/agents/wiz-planner.md` agent with the following prompt:

```
Generate 3-15 implementation phases for PRD: {SLUG}

## Your Task

1. Read and analyze the PRD at `.wiz/{SLUG}/prd.md`
2. Determine appropriate phase count (3-15) based on project complexity
3. Define each phase with clear goals, dependencies, and duration
4. Generate phase documents (return as markdown code blocks, do NOT write files)
5. Return all phases in structured format

## Phase Structure Guidelines

### Number of Phases (3-15 total)

**Simple Projects** (3-5 phases):
- Phases should be organized to progressively build the solution
- Each phase builds on the previous, adding incremental value
- Together, all phases must cover the complete PRD requirements
- Quality gates (tests, security, performance) should be addressed throughout

**Medium Projects** (5-10 phases):
- Phases should break down the work into logical, sequential increments
- Each phase depends on and builds upon previous phases
- All functional and non-functional requirements from the PRD must be covered
- Quality gates should be integrated appropriately across phases

**Complex Projects** (8-15 phases):
- Phases should decompose the work into manageable, sequential blocks
- Each phase builds incrementally on previous phases
- The complete PRD (functional requirements, NFRs, integrations) must be fully covered
- Quality gates (P0-P4 priorities) should be addressed systematically across phases

**Key Principle**: Phases must be organized such that:
1. **Sequential Dependencies**: Each phase builds on previous phases (Phase N depends on Phase N-1)
2. **Complete Coverage**: All PRD requirements are addressed across the phases
3. **Quality Integration**: Quality gates (correctness, tests, security, quality, performance) are covered
4. **Logical Progression**: Work flows naturally from foundation → features → integration → quality → deployment

**Phase Naming**: Use descriptive names that reflect the actual work being done in that phase. Names should be specific to the project and its requirements, not generic templates.

### Phase Characteristics

Each phase should:

1. **Build on Previous Phases**: Clear dependency chain
2. **Contain 15-40 Milestones**: Each milestone ~1h of work (phases are 2-5 days)
3. **Have Clear Goal**: What is the phase trying to achieve?
4. **Include Acceptance Criteria**: How do we know the phase is complete?
5. **Note Dependencies**: What must be done before this phase?

### Phase Naming

Use descriptive names that reflect the actual work and goals of each phase. Names should be:
- **Specific to the project**: Based on the PRD requirements, not generic templates
- **Action-oriented**: Clearly indicate what the phase accomplishes
- **Context-appropriate**: Match the complexity and nature of the work being done

Avoid generic names like "Phase 1", "Phase 2". Instead, use meaningful names that help understand the phase's purpose within the overall project context.

## Phase Document Structure

Each phase file should contain:

1. **YAML-style Metadata Section**:
   ```
   # Phase {N}: {Title}

   **Duration**: ~{duration} days ({milestone_count} milestones @ 1h each)
   **Dependencies**: {dependencies}
   **Status**: 🚧 TODO
   ```

2. **Goal Section**: Clear statement of what the phase achieves

3. **Phase-level Acceptance Criteria**: Bulleted list of completion criteria

4. **Milestones Section**: Placeholder for milestones (will be added by `/wiz-milestones`)
   ```markdown
   ## Milestones

   <!-- Milestones appended by /wiz-milestones -->
   ```

## Content Synthesis

### Phase Goals

Extract from PRD sections:
- **Functional Requirements**: What features need to be built?
- **Non-Functional Requirements**: What quality attributes are needed?
- **Technical Architecture**: What components need to be implemented?
- **Milestones and Phasing**: Any timeline or sequencing hints

Synthesize into phase goals that:
- Are specific and measurable
- Connect directly to PRD requirements
- Build logically on previous phases
- Can be validated through acceptance criteria
- Are tailored to the specific project needs, not generic templates

**Good phase goals**:
- "Implement user authentication system with email/password and OAuth providers"
- "Build REST API endpoints for user management and profile operations"
- "Create deployment pipeline with CI/CD, automated testing, and staging environments"
- "Integrate with external payment processing system and implement transaction handling"

**Avoid generic goals**:
- "Implement features" (too vague)
- "Add functionality" (not specific)
- "Complete development" (doesn't describe what)

### Phase Dependencies

Define clear dependency chain based on logical work sequencing:
- Each phase should explicitly state what it depends on
- Phase 1 typically has no dependencies (foundation)
- Subsequent phases depend on previous phases that provide necessary foundation
- Dependencies should reflect actual technical/work dependencies, not arbitrary ordering

If phases can run in parallel (rare), note: "Depends on Phase 1 (can run parallel with Phase 3)"

### Phase Duration

Estimate based on milestone count:
- 15-25 milestones: ~2-3 days (15-25 hours)
- 26-35 milestones: ~3-4 days (26-35 hours)
- 36-40 milestones: ~4-5 days (36-40 hours)

Note: Milestones will be generated by `/wiz-milestones` command in Phase 2

### Phase Acceptance Criteria

Define 5-10 clear criteria that verify phase completion:
- Specific deliverables (files created, components implemented)
- Quality gates (tests passing, code reviewed)
- Integration points (APIs working, services connected)
- Documentation (READMEs updated, examples provided)

## Phase Ordering

Phases must follow logical dependency order where each phase builds on previous work:

1. **Early phases** typically establish foundation, infrastructure, and core functionality
2. **Middle phases** build features, integrations, and user-facing capabilities
3. **Later phases** focus on quality, optimization, and deployment

However, the specific ordering should be determined by the PRD requirements and logical dependencies. The key is that:
- **Dependencies are clear**: Each phase explicitly states what it depends on
- **Sequential building**: Work flows naturally from one phase to the next
- **PRD coverage**: All requirements are addressed across the phases
- **Quality throughout**: Quality gates are integrated appropriately, not deferred to the end

## File Naming Convention

- Use sequential numbering: `phase1.md`, `phase2.md`, ..., `phaseN.md`
- Do NOT use zero-padding in filenames (phase1, not phase01)
- Milestone IDs inside files use zero-padding (P01M01)

## Milestone Count Distribution

Distribute work evenly across phases:
- Total estimated work: 80-200 hours (typical projects)
- Per phase: 15-40 milestones (15-40 hours)
- Adjust based on phase complexity

Example distribution for 100-hour project (5 phases):
- Phase 1: 25 milestones (foundation is often larger)
- Phase 2: 20 milestones
- Phase 3: 20 milestones
- Phase 4: 20 milestones
- Phase 5: 15 milestones (deployment often smaller)

## Return Phase Documents (Do NOT Write Files)

**CRITICAL**: You are an agent and **cannot write files**. Return each phase as a separate markdown code block.

**Expected Output Format:**

Return phases in this exact format:

\`\`\`markdown:phase1.md
# Phase 1: {Title}

**Duration**: ~{duration} days ({milestone_count} milestones @ 1h each)
**Dependencies**: {dependencies}
**Status**: 🚧 TODO

## Goal

{Clear statement of what the phase achieves}

## Phase Acceptance Criteria

- Criterion 1
- Criterion 2
- ... (5-10 criteria total)

## Milestones

<!-- Milestones appended by /wiz-milestones -->
\`\`\`

\`\`\`markdown:phase2.md
# Phase 2: {Title}
...
\`\`\`

[... continue for all phases ...]

The main agent will:
1. Extract each phase markdown from code blocks
2. Write them to `.wiz/{SLUG}/phases/phase1.md` through `phaseN.md`
3. Verify all files were created
```

### Step 5: Main Agent Writes Phase Files

After receiving the agent's response with phase markdown in code blocks, the **main agent** (you, executing the /wiz-phases command) must:

1. **Extract each phase markdown** from code blocks in the agent's response
2. **Write phase files** using Write tool for each phase:
   ```
   file_path: .wiz/<slug>/phases/phase1.md
   content: <extracted markdown from agent response for phase 1>
   
   file_path: .wiz/<slug>/phases/phase2.md
   content: <extracted markdown from agent response for phase 2>
   
   ... continue for all phases ...
   ```

3. **Verify files exist**:
   ```bash
   ls -la .wiz/$SLUG/phases/
   ```

4. **Update state**:
   ```bash
   wiz_set_current_prd "$SLUG"
   wiz_log_info "Set current PRD to: $SLUG"
   ```

5. **Display phase summary**:
   ```
   ✅ Phases Generated Successfully!
   
   **PRD**: {SLUG}
   **Phases Created**: {N}
   **Location**: .wiz/{SLUG}/phases/
   
   ## Phase Summary
   
   1. **Phase 1**: {Title} (~{duration} days, {milestone_count} milestones)
      Goal: {brief_goal}
   
   2. **Phase 2**: {Title} (~{duration} days, {milestone_count} milestones)
      Goal: {brief_goal}
   
   [... continue for all phases ...]
   
   ## Next Steps
   
   1. **Generate Milestones**: Run `/wiz-milestones {SLUG}` to generate detailed milestones for each phase
   2. **Review Phases**: Read phase files to understand the implementation roadmap
   3. **Start Implementation**: After milestones are generated, run `/wiz-next` to begin Phase 1, Milestone 1
   
   ## Files Created
   
   - `.wiz/{SLUG}/phases/phase1.md` through `phase{N}.md` - Phase documents with goals and acceptance criteria
   
   Note: Milestones will be appended to phase files by `/wiz-milestones` command.
   ```

## Validation

After generating all phases, validate:

1. **Phase Count**: 3-15 phases total
2. **Phase Numbers**: Sequential (1, 2, 3, ..., N)
3. **Dependencies**: Valid dependency chain
4. **Milestone Counts**: Each phase has 15-40 milestone placeholder
5. **Goal Clarity**: Each goal is specific and actionable
6. **Acceptance Criteria**: Each phase has 5-10 clear criteria

## Error Handling

- **Missing slug**: Show usage example
- **Invalid slug format**: Show format requirements
- **PRD not found**: Suggest running `/wiz-prd` first
- **Phases already exist**: Suggest removing existing phases or using different slug
- **File write errors**: Check permissions and disk space
- **Agent errors**: Show detailed error message and recovery steps
- **Agent returns no content**: If agent response doesn't contain code blocks with expected content, ask agent to retry with explicit formatting instructions

## Example Usage

```bash
/wiz-phases auth-system
```

This will:
1. Read `.wiz/auth-system/prd.md`
2. Generate 3-15 phases based on PRD complexity
3. Save phase documents to `.wiz/auth-system/phases/phase*.md`
4. Display phase summary with next steps

## Notes

- Phase documents contain only phase-level information (no milestones yet)
- Milestones are generated by `/wiz-milestones` command (separate step)
- Phase count and structure depend on PRD complexity
- Each phase builds on previous phases (sequential dependencies)
- Command delegates to `wiz-planner` agent (reference `.cursor/agents/wiz-planner.md`)

