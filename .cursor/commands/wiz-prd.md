______________________________________________________________________

## description: Generate comprehensive PRD through guided Q&A with research argument-hint: <slug> "<idea>"

# Generate PRD from Idea

You are creating a comprehensive Product Requirements Document (PRD) using the Wiz Planner workflow.

## ⚠️ CRITICAL: Human Answers Required

**DO NOT answer questions yourself.** The questions generated in Stage 1 are for the **HUMAN USER** to answer. Your role is to:

- Generate context-aware questions based on codebase analysis
- Present questions to the human user
- **WAIT for the human user to provide answers**
- Parse the human user's answers
- Generate PRD from the human user's decisions

**If you find yourself answering questions without human input, STOP and present the questions to the user instead.**

## ⚠️ CRITICAL: File Writing Requirements

**MAIN AGENT (you, running /wiz-prd) MUST WRITE FILES** at each stage. This command requires creating actual files, not just generating content:

1. **Delegate to wiz-planner agent** for content generation (questions, answers, PRD)
1. **Agent returns content** in code blocks (JSON or markdown)
1. **Main agent writes files** using Write tool (questions.json, answers.json, prd.md, etc.)
1. **Verify files exist** after writing by checking the filesystem
1. **Never skip file creation** - the user needs these files to continue the workflow

**Why this pattern?** Agents invoked via agent references cannot reliably write files. The workaround is: agent generates content, main agent writes files.

## Arguments

- `<slug>`: Unique identifier for this PRD (lowercase, hyphens, alphanumeric only)
- `"<idea>"`: Brief description of the feature or project idea (in quotes)

## Planning Agent

This command delegates content generation to the **wiz-planner** agent (`.cursor/agents/wiz-planner.md`), which provides verbose, research-focused planning output suitable for strategic planning activities.

## Workflow Overview

This command follows a three-stage workflow:

1. **Codebase Analysis**: Analyze repository to detect language, patterns, and infrastructure (BEFORE generating questions)
1. **Question Generation**: Generate 5-20 context-aware clarifying questions that require HUMAN judgment
1. **Answer Collection**: **WAIT for HUMAN USER** to provide answers in chat (do NOT answer questions yourself)
1. **PRD Generation**: Research and create comprehensive PRD document based on HUMAN USER answers

## Stage 1: Codebase Analysis (BEFORE Question Generation)

**⚠️ CRITICAL: You MUST analyze the codebase FIRST before generating questions.**

Before generating any questions, analyze the repository to understand:

- **Primary programming language(s)** - detect from file extensions and existing code
- **Existing patterns and conventions** - frameworks, libraries, architectural patterns
- **Current project structure** - what already exists
- **Testing infrastructure** - what testing frameworks are already in use
- **Dependencies and tools** - what's already configured

**DO NOT ask questions about things you can determine from the codebase.**

### Codebase Analysis Steps

```bash
# Detect primary language by analyzing file counts
GO_FILES=$(find . -name "*.go" -not -path "*/vendor/*" -not -path "*/.git/*" 2>/dev/null | wc -l || echo "0")
TS_FILES=$(find . \( -name "*.ts" -o -name "*.tsx" \) -not -path "*/node_modules/*" -not -path "*/.git/*" 2>/dev/null | wc -l || echo "0")
PY_FILES=$(find . -name "*.py" -not -path "*/.git/*" -not -path "*/venv/*" 2>/dev/null | wc -l || echo "0")
CS_FILES=$(find . -name "*.cs" -not -path "*/.git/*" -not -path "*/bin/*" 2>/dev/null | wc -l || echo "0")
JAVA_FILES=$(find . -name "*.java" -not -path "*/.git/*" -not -path "*/target/*" 2>/dev/null | wc -l || echo "0")

# Determine primary language (language with most files)
PRIMARY_LANG="unknown"
MAX_COUNT=0

if [[ $GO_FILES -gt $MAX_COUNT ]]; then
    PRIMARY_LANG="go"
    MAX_COUNT=$GO_FILES
fi
if [[ $TS_FILES -gt $MAX_COUNT ]]; then
    PRIMARY_LANG="typescript"
    MAX_COUNT=$TS_FILES
fi
if [[ $PY_FILES -gt $MAX_COUNT ]]; then
    PRIMARY_LANG="python"
    MAX_COUNT=$PY_FILES
fi
if [[ $CS_FILES -gt $MAX_COUNT ]]; then
    PRIMARY_LANG="csharp"
    MAX_COUNT=$CS_FILES
fi
if [[ $JAVA_FILES -gt $MAX_COUNT ]]; then
    PRIMARY_LANG="java"
    MAX_COUNT=$JAVA_FILES
fi

# Check for existing test infrastructure
HAS_GO_TESTS=$(find . -name "*_test.go" -not -path "*/vendor/*" 2>/dev/null | wc -l || echo "0")
HAS_TS_TESTS=$(find . \( -name "*.test.ts" -o -name "*.spec.ts" \) -not -path "*/node_modules/*" 2>/dev/null | wc -l || echo "0")
HAS_PY_TESTS=$(find . -name "test_*.py" -o -name "*_test.py" 2>/dev/null | wc -l || echo "0")

# Check for existing benchmarking
HAS_BENCHMARKS=$(find . -name "*_bench_test.go" -o -name "*_benchmark.go" 2>/dev/null | wc -l || echo "0")
if [[ $HAS_BENCHMARKS -gt 0 ]]; then
    HAS_BENCHMARKS="yes"
else
    HAS_BENCHMARKS="no"
fi

# Check for existing fuzzing
HAS_FUZZ=$(find . -name "*_fuzz_test.go" -o -name "*_fuzz.go" 2>/dev/null | wc -l || echo "0")
if [[ $HAS_FUZZ -gt 0 ]]; then
    HAS_FUZZ="yes"
else
    HAS_FUZZ="no"
fi

# Save analysis results
CODEBASE_ANALYSIS=$(cat <<EOF
{
  "primary_language": "$PRIMARY_LANG",
  "language_file_counts": {
    "go": $GO_FILES,
    "typescript": $TS_FILES,
    "python": $PY_FILES,
    "csharp": $CS_FILES,
    "java": $JAVA_FILES
  },
  "has_test_infrastructure": $((HAS_GO_TESTS + HAS_TS_TESTS + HAS_PY_TESTS)),
  "has_benchmarks": "$HAS_BENCHMARKS",
  "has_fuzzing": "$HAS_FUZZ"
}
EOF
)
```

Use the analysis results to inform question generation. **DO NOT ask questions about things you already know from the codebase.**

## Stage 2: Question Generation

Generate 5-20 clarifying questions to understand the project requirements. Questions MUST be:

1. **Context-Aware**: Skip questions about things already determined from codebase analysis
1. **Require Human Judgment**: Only ask questions that need human decision-making
1. **Pertinent**: Focus on aspects that matter for this specific idea and codebase

**Conditional Required Questions** (only ask if not already determined):

1. **Primary language** - ONLY ask if codebase analysis shows:

   - No clear primary language (multiple languages with similar file counts)
   - No code files found (new project)
   - Otherwise, use detected language and state it: "Detected primary language: Go (from codebase analysis). Confirm or specify different language(s) if needed?"

1. **Benchmarking policy** - Ask as: "What is the benchmarking policy? (hot spots only, comprehensive, or skip)" - BUT include context from analysis if benchmarks already exist

1. **Fuzzing policy** - Ask as: "What is the fuzzing policy? (core areas only, comprehensive, or skip)" - BUT include context from analysis if fuzzing already exists

**Additional Questions** (based on the idea):

- Target users and personas
- Key objectives and success metrics
- Technical constraints and assumptions
- Integration requirements
- Performance expectations
- Security requirements
- Observability needs
- Timeline and scope

### Question Generation Guidelines

When generating questions, follow these principles:

1. **Specificity**: Ask concrete questions that lead to actionable answers

   - Good: "What authentication methods should be supported? (e.g., email/password, OAuth, SSO)"
   - Bad: "Tell me about authentication"

1. **Scope Clarity**: Help users understand what level of detail is needed

   - Good: "What is the expected peak request rate? (e.g., 100 req/s, 1000 req/s)"
   - Bad: "What are the performance requirements?"

1. **Context Awareness**: Tailor questions to the specific idea provided

   - For a CLI tool: Ask about platforms, distribution, dependencies
   - For a web API: Ask about endpoints, data formats, rate limiting
   - For a library: Ask about API surface, target consumers, backward compatibility

1. **NFR Coverage**: Ensure questions cover P0-P4 priorities

   - P0 Correctness: Edge cases, error scenarios, validation rules
   - P1 Tests: Testing strategy, coverage expectations
   - P2 Security: Auth, data protection, vulnerability concerns
   - P3 Quality: Code standards, review process, documentation needs
   - P4 Performance: Latency targets, throughput, resource limits

1. **Question Count**: Generate 5-20 questions based on complexity

   - Simple features: 5-8 questions
   - Medium complexity: 9-14 questions
   - Complex systems: 15-20 questions

### Question Format and Validation

Each question must conform to the JSON schema:

```json
{
  "index": 1,
  "question": "What are the primary language(s) for this project? (Go, TypeScript, Python, C#, Java, or other)",
  "rationale": "Determines which design guidelines to generate and which language specialist subagents to consult during implementation"
}
```

**Required Fields:**

- `index` (integer): 1-based question number
- `question` (string): The clarifying question with examples or options when helpful
- `rationale` (string): Brief explanation of why this matters for the PRD

**Validation Requirements:**

- Questions 1-3 must be the required questions in exact order
- All indices must be sequential (1, 2, 3, ...)
- No duplicate questions or indices
- Each rationale should connect to PRD sections or implementation needs

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

### Step 1: Validate Arguments

```bash
#!/usr/bin/env bash
set -euo pipefail

# Parse arguments
SLUG="${1:-}"
IDEA="${2:-}"

# Validate slug
if [[ -z "$SLUG" ]]; then
    wiz_log_error "Missing slug argument"
    echo "Usage: /wiz-prd <slug> \"<idea>\""
    exit 1
fi

if ! wiz_validate_slug "$SLUG"; then
    wiz_log_error "Invalid slug format: $SLUG"
    echo "Slug must be lowercase, alphanumeric, and hyphens only"
    exit 1
fi

# Validate idea
if [[ -z "$IDEA" ]]; then
    wiz_log_error "Missing idea argument"
    echo "Usage: /wiz-prd <slug> \"<idea>\""
    exit 1
fi

# Check if PRD already exists
PRD_DIR=".wiz/$SLUG"
if [[ -d "$PRD_DIR" ]]; then
    wiz_log_error "PRD directory already exists: $PRD_DIR"
    echo "Use a different slug or remove the existing PRD directory"
    exit 1
fi

wiz_log_info "Validated arguments - slug: $SLUG, idea: $IDEA"
```

### Step 2: Create Directory Structure

```bash
# Create intake directory
INTAKE_DIR="$PRD_DIR/intake"
wiz_ensure_dir "$INTAKE_DIR"

wiz_log_info "Created directory structure at $PRD_DIR"
```

### Step 3: Invoke wiz-planner Agent

The `wiz-planner` agent provides verbose, research-focused planning output suitable for strategic planning activities. When you reference `.cursor/agents/wiz-planner.md` in the next step, it will automatically provide comprehensive, detailed planning content.

### Step 4: Analyze Codebase (BEFORE Question Generation)

**⚠️ CRITICAL: Analyze codebase FIRST to avoid asking obvious questions.**

Before delegating to the agent, perform codebase analysis:

```bash
#!/usr/bin/env bash
set -euo pipefail

# Detect primary language by analyzing file counts
GO_FILES=$(find . -name "*.go" -not -path "*/vendor/*" -not -path "*/.git/*" 2>/dev/null | wc -l || echo "0")
TS_FILES=$(find . \( -name "*.ts" -o -name "*.tsx" \) -not -path "*/node_modules/*" -not -path "*/.git/*" 2>/dev/null | wc -l || echo "0")
PY_FILES=$(find . -name "*.py" -not -path "*/.git/*" -not -path "*/venv/*" 2>/dev/null | wc -l || echo "0")
CS_FILES=$(find . -name "*.cs" -not -path "*/.git/*" -not -path "*/bin/*" 2>/dev/null | wc -l || echo "0")
JAVA_FILES=$(find . -name "*.java" -not -path "*/.git/*" -not -path "*/target/*" 2>/dev/null | wc -l || echo "0")

# Determine primary language (language with most files)
PRIMARY_LANG="unknown"
MAX_COUNT=0

if [[ $GO_FILES -gt $MAX_COUNT ]]; then
    PRIMARY_LANG="go"
    MAX_COUNT=$GO_FILES
fi
if [[ $TS_FILES -gt $MAX_COUNT ]]; then
    PRIMARY_LANG="typescript"
    MAX_COUNT=$TS_FILES
fi
if [[ $PY_FILES -gt $MAX_COUNT ]]; then
    PRIMARY_LANG="python"
    MAX_COUNT=$PY_FILES
fi
if [[ $CS_FILES -gt $MAX_COUNT ]]; then
    PRIMARY_LANG="csharp"
    MAX_COUNT=$CS_FILES
fi
if [[ $JAVA_FILES -gt $MAX_COUNT ]]; then
    PRIMARY_LANG="java"
    MAX_COUNT=$JAVA_FILES
fi

# Check for existing test infrastructure
HAS_GO_TESTS=$(find . -name "*_test.go" -not -path "*/vendor/*" 2>/dev/null | wc -l || echo "0")
HAS_TS_TESTS=$(find . \( -name "*.test.ts" -o -name "*.spec.ts" \) -not -path "*/node_modules/*" 2>/dev/null | wc -l || echo "0")
HAS_PY_TESTS=$(find . -name "test_*.py" -o -name "*_test.py" 2>/dev/null | wc -l || echo "0")

# Check for existing benchmarking
HAS_BENCHMARKS=$(find . -name "*_bench_test.go" -o -name "*_benchmark.go" 2>/dev/null | wc -l || echo "0")
if [[ $HAS_BENCHMARKS -gt 0 ]]; then
    HAS_BENCHMARKS="yes"
else
    HAS_BENCHMARKS="no"
fi

# Check for existing fuzzing
HAS_FUZZ=$(find . -name "*_fuzz_test.go" -o -name "*_fuzz.go" 2>/dev/null | wc -l || echo "0")
if [[ $HAS_FUZZ -gt 0 ]]; then
    HAS_FUZZ="yes"
else
    HAS_FUZZ="no"
fi

# Save analysis results as JSON
CODEBASE_ANALYSIS=$(cat <<EOF
{
  "primary_language": "$PRIMARY_LANG",
  "language_file_counts": {
    "go": $GO_FILES,
    "typescript": $TS_FILES,
    "python": $PY_FILES,
    "csharp": $CS_FILES,
    "java": $JAVA_FILES
  },
  "has_test_infrastructure": $((HAS_GO_TESTS + HAS_TS_TESTS + HAS_PY_TESTS)),
  "has_benchmarks": "$HAS_BENCHMARKS",
  "has_fuzzing": "$HAS_FUZZ"
}
EOF
)

wiz_log_info "Codebase analysis complete - Primary language: $PRIMARY_LANG"
wiz_log_info "File counts - Go: $GO_FILES, TS: $TS_FILES, Python: $PY_FILES, C#: $CS_FILES, Java: $JAVA_FILES"
```

The analysis results will be provided to the agent to inform question generation and prevent asking obvious questions.

### Step 5: Delegate to wiz-planner Agent

**⚠️ CRITICAL: Agent File Operation Limitation**

Agents invoked via agent references **cannot reliably write files**. This is a known limitation.

**Solution:**

- The `wiz-planner` agent **returns file contents** as code blocks in its response
- The main agent (you, running /wiz-prd) **performs all Write operations**
- Agent focuses on: question generation, answer parsing, PRD content generation
- Main agent handles: all file I/O operations

**⚠️ CRITICAL: Questions MUST be answered by HUMAN, NOT by AI**

**DO NOT answer the questions yourself.** The questions are for the HUMAN USER to answer. Your job is to:

1. Generate the questions
1. Present them to the user
1. Wait for the user to provide answers
1. Parse the user's answers
1. Generate the PRD from the user's answers

**Workflow:**

1. Analyze codebase first (detect language, patterns, infrastructure)
1. Delegate question generation to wiz-planner agent with codebase context
1. Agent returns questions as JSON in code block
1. Main agent writes questions.json using Write tool
1. Main agent creates state.json using Write tool
1. **Main agent presents questions to user and WAITS for human answers**
1. When user provides answers, delegate to wiz-planner to parse and generate PRD
1. Agent returns answers.json and prd.md content as code blocks
1. Main agent writes all files using Write tool

Reference the `.cursor/agents/wiz-planner.md` agent with the following prompt (including the codebase analysis):

```
Generate clarifying questions for a PRD about: {IDEA}

## ⚠️ CRITICAL INSTRUCTIONS

**DO NOT ANSWER THE QUESTIONS YOURSELF.** These questions are for the HUMAN USER to answer. Your job is ONLY to generate the questions, not to answer them.

**USE CODEBASE ANALYSIS:** I've analyzed the codebase and found:
{CODEBASE_ANALYSIS}

**Example:** If primary_language is "go" with 500+ files, DON'T ask "What language?" - instead ask "Detected primary language: Go (from codebase analysis). Confirm Go or specify different language(s) if needed?"

Use this information to:
- Skip questions about things already determined (e.g., if primary language is clearly Go, don't ask "what language?" but instead ask "Confirm Go or specify different language(s) if needed?")
- Make questions context-aware (e.g., if benchmarks already exist, ask "Extend existing benchmarking or change policy?")
- Focus on aspects that require HUMAN JUDGMENT and DECISION-MAKING

## Your Task

1. Review the codebase analysis provided above
2. Analyze the idea to determine appropriate question count (5-20 based on complexity)
3. Generate questions following the guidelines in this command
4. **ONLY ask questions that require HUMAN JUDGMENT** - skip obvious questions
5. **DO NOT answer questions yourself** - generate questions only
6. Validate questions against the JSON schema
7. Return questions as JSON in a code block (do NOT write files)

## Conditional Required Questions

**Question 1: Primary Language** (ONLY if not clearly determined from codebase)
- If codebase has clear primary language (e.g., 80%+ Go files): Ask confirmation question like "Detected primary language: Go (from codebase analysis). Confirm Go or specify different language(s) if needed?"
- If codebase has mixed languages or no code: Ask "What are the primary language(s) for this project? (Go, TypeScript, Python, C#, Java, or other)"
- Rationale: "Determines which design guidelines to generate and which language specialist subagents to consult during implementation"

**Question 2: Benchmarking Policy** (ALWAYS ask, but context-aware)
- If benchmarks exist: "Existing benchmarks found in codebase. What is the benchmarking policy going forward? (hot spots only, comprehensive, or skip)"
- If no benchmarks: "What is the benchmarking policy? (hot spots only, comprehensive, or skip)"
- Rationale: "Defines performance measurement requirements for critical code paths and optimization validation"

**Question 3: Fuzzing Policy** (ALWAYS ask, but context-aware)
- If fuzzing exists: "Existing fuzz tests found in codebase. What is the fuzzing policy going forward? (core areas only, comprehensive, or skip)"
- If no fuzzing: "What is the fuzzing policy? (core areas only, comprehensive, or skip)"
- Rationale: "Determines fuzz testing scope for input validation and security-critical components"

## Additional Questions (indices 4+)

**IMPORTANT**: Only generate questions that:
- Require HUMAN JUDGMENT (not things you can determine from codebase)
- Are PERTINENT to the specific idea provided
- Help clarify REQUIREMENTS and DECISIONS that affect implementation

Tailor questions to the specific idea provided. Cover these areas:

**Problem & Users** (typically 2-3 questions):
- Who are the target users? What are their roles/personas?
- What problem does this solve? What pain points are addressed?
- What are the key use cases or user stories?

**Scope & Requirements** (typically 3-5 questions):
- What are the must-have features for the first version?
- What features are explicitly out of scope?
- What are the success metrics or acceptance criteria?
- Are there any hard constraints? (deadlines, budget, compliance)

**Technical Constraints** (typically 2-4 questions):
- What existing systems must this integrate with?
- Are there specific technologies/frameworks that must or cannot be used?
- What are the deployment environments? (cloud, on-prem, edge)
- What are the backward compatibility requirements?

**NFR Priorities** (typically 2-4 questions):
- What are the performance expectations? (latency, throughput, scale)
- What are the security requirements? (auth, encryption, compliance)
- What are the reliability requirements? (uptime, disaster recovery)
- What observability is needed? (logging, metrics, tracing)

**Quality & Process** (typically 1-2 questions):
- What testing strategy should be used? (unit, integration, e2e)
- Are there documentation requirements? (API docs, user guides, runbooks)

## Question Format

Each question must be a JSON object:

{
  "index": <1-based integer>,
  "question": "<specific, actionable question with examples/options when helpful>",
  "rationale": "<brief explanation connecting to PRD sections or implementation needs>"
}

## Return Questions (Do NOT Write Files OR Answer Questions)

**CRITICAL**: 
1. You are an agent and **cannot write files**. Return questions as JSON in a code block.
2. **DO NOT ANSWER THE QUESTIONS YOURSELF.** These are for the HUMAN USER to answer.

**Expected Output Format:**

Return ONLY the questions (not answers) in this exact format:

\`\`\`json
[
  {
    "index": 1,
    "question": "Detected primary language: Go (from codebase analysis). Confirm Go or specify different language(s) if needed?",
    "rationale": "Determines which design guidelines to generate and which language specialist subagents to consult during implementation"
  },
  {
    "index": 2,
    "question": "What is the benchmarking policy? (hot spots only, comprehensive, or skip)",
    "rationale": "Defines performance measurement requirements for critical code paths and optimization validation"
  },
  ...additional questions...
]
\`\`\`

**DO NOT include answers in your response.** Only return the questions. The main agent will:
1. Extract the JSON from your response
2. Validate it against the schema
3. Write it to `.wiz/<slug>/intake/questions.json`
4. Create the state.json file
5. **Present the questions to the HUMAN USER and wait for their answers**
```

**When calling the agent, replace {CODEBASE_ANALYSIS} with the actual JSON from Step 4, and replace {IDEA} with the actual idea from arguments.**

### Step 6: Main Agent Writes Files and Presents Questions

After receiving the agent's response with questions JSON in a code block, the **main agent** (you, executing the /wiz-prd command) must:

1. **Extract JSON from code block** in the agent's response

1. **Write questions.json** using Write tool:

   ```
   file_path: .wiz/<slug>/intake/questions.json
   content: <extracted JSON from agent response>
   ```

1. **Write state.json** using Write tool:

   ```bash
   TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
   cat > ".wiz/$SLUG/intake/state.json" <<EOF
   {
     "stage": "awaiting_answers",
     "created_at": "$TIMESTAMP",
     "updated_at": "$TIMESTAMP",
     "codebase_analysis": $CODEBASE_ANALYSIS
   }
   EOF
   ```

1. **Save current PRD**:

   ```bash
   wiz_set_current_prd "$SLUG"
   wiz_log_info "Set current PRD to: $SLUG"
   ```

1. **Present questions to user**:

   ```
   📋 PRD Question Generation Complete

   I've analyzed the codebase and generated N clarifying questions to help create a comprehensive PRD for: {IDEA}

   **Codebase Analysis Summary:**
   - Primary language detected: {PRIMARY_LANG} ({MAX_COUNT} files)
   - Test infrastructure: {HAS_TESTS} test files found
   - Existing benchmarks: {HAS_BENCHMARKS}
   - Existing fuzzing: {HAS_FUZZ}

   **Note**: Questions have been tailored based on this analysis. Questions about things already determined from the codebase have been skipped or made context-aware.

   **Questions for YOU to answer:**

   <display questions in numbered list format with rationale>

   ⚠️ **IMPORTANT**: These questions require YOUR HUMAN JUDGMENT and DECISION-MAKING.
   Please provide YOUR answers to these questions in the chat. You do NOT need to re-run this command.

   Once you provide YOUR answers, I will automatically:
   1. Parse and save your answers
   2. Research relevant technical details
   3. Generate a comprehensive PRD document based on YOUR decisions

   Format your answers however is comfortable for you - I'll parse them intelligently.
   ```

1. **STOP and WAIT for user answers** - Do NOT proceed to Stage 2 until the user provides answers

1. **Verify files exist**:

   ```bash
   ls -la .wiz/$SLUG/intake/
   ```

## Stage 2: Answer Processing

**⚠️ CRITICAL: WAIT for HUMAN USER to provide answers. DO NOT answer questions yourself.**

When the HUMAN USER provides answers in the chat (as a continuation), the `wiz-planner` agent will detect and process them.

### Detection and Parsing

**⚠️ CRITICAL: Parse HUMAN USER answers, DO NOT generate answers yourself.**

The agent should:

1. **Detect Answer Context**: Recognize that the HUMAN USER is responding to the questions from Stage 1

   - Check if state is "awaiting_answers"
   - Load questions from `.wiz/<slug>/intake/questions.json`
   - Load codebase analysis from state.json

1. **Parse HUMAN USER Answers Intelligently**: Extract answers from the HUMAN USER's message

   - Support various formats: numbered lists, natural language, mixed formats
   - Match answers to questions by index or content
   - Handle multi-line answers and code blocks
   - Allow "skip" or "N/A" for optional questions
   - **DO NOT** infer or guess answers - only use what the HUMAN USER explicitly provided

1. **Validate Completeness**: Ensure required questions have HUMAN USER answers

   - Questions 1-3 (language, benchmarking, fuzzing) MUST have non-empty answers from HUMAN USER
   - If answers are missing, prompt HUMAN USER for missing answers - DO NOT generate answers yourself

### Answer Format

Answers must conform to JSON schema:

```json
[
  {
    "index": 1,
    "answer": "Go and TypeScript"
  },
  {
    "index": 2,
    "answer": "hot spots only"
  },
  {
    "index": 3,
    "answer": "core areas only"
  }
]
```

**Required Fields:**

- `index` (integer): Matches question index (1-based)
- `answer` (string): User's answer (non-empty for required questions)

### Parsing Examples

**Example 1: Numbered List Format**

```
User: Here are my answers:
1. Go
2. hot spots only
3. comprehensive
4. Developers building CLI tools
5. Simplify common CLI patterns like flags, subcommands, help text
```

Parser should extract each answer by index.

**Example 2: Natural Language Format**

```
User: For the language I want to use Go. The benchmarking should focus on hot spots only.
For fuzzing, let's do comprehensive testing. The target users are developers building CLI tools...
```

Parser should match phrases to questions and extract answers.

**Example 3: Mixed Format with Code Blocks**

```
User:
1. Primary language: Go
2. Benchmarking: hot spots only
3. Fuzzing: comprehensive

The target users are developers building CLI tools. They need to:
- Parse command-line flags
- Implement subcommands
- Generate help text

Example usage:
\`\`\`go
cli.NewApp().Run(os.Args)
\`\`\`
```

Parser should handle mixed format and preserve code blocks in answers.

### Return Answers (Do NOT Write Files)

**CRITICAL**: You are an agent and **cannot write files**. Return the parsed answers as JSON in a code block.

**Expected Output Format:**

Return the answers in this exact format:

\`\`\`json
\[
{
"index": 1,
"answer": "Go and TypeScript"
},
{
"index": 2,
"answer": "hot spots only"
},
...additional answers...
\]
\`\`\`

The main agent will:

1. Extract the JSON from your response
1. Validate it against the schema
1. Write it to `.wiz/<slug>/intake/answers.json`

### Return Q&A Summary (Do NOT Write Files)

**CRITICAL**: You are an agent and **cannot write files**. Return the Q&A summary as markdown in a code block.

**Expected Output Format:**

\`\`\`markdown

# Q&A Session

**PRD**: <slug>
**Created**: 2025-10-19T10:30:00Z
**Status**: Answers collected

## Questions and Answers

### 1. What are the primary language(s) for this project?

**Rationale**: Determines which design guidelines to generate and which language specialist subagents to consult during implementation

**Answer**: Go and TypeScript

______________________________________________________________________

### 2. What is the benchmarking policy?

**Rationale**: Defines performance measurement requirements for critical code paths and optimization validation

**Answer**: hot spots only

______________________________________________________________________

[... continue for all questions ...]
\`\`\`

The main agent will write this to `.wiz/<slug>/intake/qa.md`

### Main Agent: Update State and Files

After receiving the agent's response with answers and Q&A summary:

1. **Write answers.json** using Write tool

1. **Write qa.md** using Write tool

1. **Update state.json**:

   ```bash
   TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
   cat > ".wiz/$SLUG/intake/state.json" <<EOF
   {
     "stage": "researching",
     "created_at": "<original_timestamp>",
     "updated_at": "$TIMESTAMP",
     "questions_generated_at": "<original_timestamp>",
     "answers_collected_at": "$TIMESTAMP"
   }
   EOF
   ```

1. **Inform user**:

   ```
   Thank you! I've saved your answers and generated a Q&A summary at .wiz/<slug>/intake/qa.md

   I'm now proceeding to Stage 3: PRD Generation
   - Researching relevant technical details
   - Loading PRD template
   - Rendering comprehensive PRD document

   This may take 2-3 minutes...
   ```

Then immediately continue to Stage 3 without user intervention.

## Stage 3: PRD Generation

The `wiz-planner` agent will research, synthesize, and generate a comprehensive PRD document.

### Research Phase

Before generating the PRD, conduct targeted research to enhance quality:

1. **Language-Specific Research**: Based on answer to question 1 (primary language)

   - Look up current language version and ecosystem best practices
   - Research relevant frameworks and libraries for the project type
   - Find design patterns and idioms specific to the language

1. **Domain-Specific Research**: Based on the project idea and requirements

   - Research similar projects or reference implementations
   - Look up industry standards or compliance requirements
   - Find performance benchmarks for similar systems

1. **Technical Research**: Based on integration and technical constraints

   - Research APIs or systems mentioned in answers
   - Look up compatibility requirements
   - Find deployment best practices for target environments

**Research Guidelines**:

- Limit research to 5-10 focused queries (2-3 minutes total)
- Prioritize official documentation and authoritative sources
- Extract actionable insights, not general information
- Document sources for future reference

**If research tools unavailable**: Proceed with PRD generation using available information from answers and agent knowledge.

### Template Loading and Rendering

1. **Load Template**: Read PRD template if available, or use standard structure

   - YAML frontmatter with metadata fields
   - Markdown sections with `{{variable}}` placeholders
   - WIZ:SECTION anchors for phase/milestone parsing

1. **Prepare Template Variables**: Extract data from answers and research

```bash
# Load questions and answers
QUESTIONS=$(wiz_read_json ".wiz/$SLUG/intake/questions.json")
ANSWERS=$(wiz_read_json ".wiz/$SLUG/intake/answers.json")

# Build template variables (example values)
TEMPLATE_VARS='{
  "title": "<derived from idea>",
  "slug": "'$SLUG'",
  "version": "1.0.0",
  "status": "Draft",
  "created": "2025-10-19",
  "owner": "<from answer or 'TBD'>",
  "primary_language": "<from answer 1>",
  "benchmarking_policy": "<from answer 2>",
  "fuzzing_policy": "<from answer 3>",
  "background": "<synthesized from idea and answers>",
  "problem_statement": "<synthesized from answers>",
  "goals": "<synthesized from answers>",
  "non_goals": "<synthesized from answers>",
  "target_users": "<from answers>",
  "success_metrics": "<from answers>",
  "...": "..."
}'
```

3. **Render Template**: Use template utility to substitute variables (if template available)

### Content Synthesis

For each PRD section, synthesize content from answers and research:

**Section: Background**

- Combine idea description with problem context from answers
- Add relevant domain context from research
- Keep concise (2-3 paragraphs)

**Section: Problem Statement**

- Extract from user pain points and use case answers
- Make specific and measurable
- Include current state vs. desired state

**Section: Goals and Non-Goals**

- Goals: Extract from objectives and must-have features
- Non-Goals: Extract from out-of-scope answers
- Format as bulleted lists (3-7 items each)

**Section: User Personas and Use Cases**

- Extract personas from target user answers
- Create 2-4 detailed use cases with scenarios
- Include expected outcomes

**Section: Technical Architecture**

- Describe high-level architecture based on answers
- Include integration points
- Add component diagrams (text-based) if helpful

**Section: Functional Requirements**

- List must-have features from answers
- Organize by component or user journey
- Use clear, testable language (e.g., "System shall...")

**Section: Non-Functional Requirements**

- Organize by P0-P4 priority order:
  - P0: Correctness (error handling, edge cases)
  - P1: Regression Prevention (test coverage, CI/CD)
  - P2: Security (auth, encryption, compliance)
  - P3: Quality (code standards, documentation, maintainability)
  - P4: Performance (latency, throughput, resource limits)
- Include specific targets from answers (e.g., "P99 latency < 100ms")

**Section: Design Guidelines**

- Reference language-specific guidelines
- Note: "Detailed design guidelines will be applied during implementation (Phase 1)"

**Section: Milestones and Phasing**

- Note: "Will be generated by /wiz-phases command after PRD approval"
- Provide rough timeline estimate if deadline mentioned in answers

**Section: Open Questions**

- List any unclear requirements or needed decisions
- Include questions where answers were "skip" or "TBD"

**Section: Appendix**

- Research sources and references
- Relevant standards or compliance documents

### Return PRD Document (Do NOT Write Files)

**CRITICAL**: You are an agent and **cannot write files**. Return the complete PRD as markdown in a code block.

**Expected Output Format:**

## \`\`\`markdown

## title: "<Project Title>" slug: "<slug>" version: "1.0.0" status: "Draft" created: "2025-10-19" owner: "\<from answer or 'TBD'>" primary_language: "\<from answer 1>" benchmarking_policy: "\<from answer 2>" fuzzing_policy: "\<from answer 3>"

# Product Requirements Document: <Project Title>

## Background

[Synthesized background from idea and answers...]

## Problem Statement

[Specific problem statement from user answers...]

## Goals and Non-Goals

### Goals

- Goal 1
- Goal 2
  ...

### Non-Goals

- Non-goal 1
  ...

[... complete PRD content following template structure ...]
\`\`\`

The main agent will write this to `.wiz/<slug>/prd.md`

### Main Agent: Write PRD and Update State

After receiving the agent's response with PRD content in a code block:

1. **Extract PRD markdown** from code block

1. **Write prd.md** using Write tool:

   ```
   file_path: .wiz/<slug>/prd.md
   content: <extracted markdown from agent response>
   ```

1. **Update state.json**:

   ```bash
   TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
   cat > ".wiz/$SLUG/intake/state.json" <<EOF
   {
     "stage": "done",
     "created_at": "<original_timestamp>",
     "updated_at": "$TIMESTAMP",
     "questions_generated_at": "<original_timestamp>",
     "answers_collected_at": "<answers_timestamp>",
     "prd_generated_at": "$TIMESTAMP"
   }
   EOF
   ```

1. **Verify files exist**:

   ```bash
   ls -la .wiz/$SLUG/intake/
   ls -la .wiz/$SLUG/prd.md
   ```

### Success Message

After successfully writing all files, display completion message to user:

```
✅ PRD Generated Successfully!

**Location**: .wiz/<slug>/prd.md
**Title**: <title>
**Status**: Draft
**Primary Language**: <language>

## Next Steps

1. **Review PRD**: Read `.wiz/<slug>/prd.md` and verify requirements
2. **Generate Phases**: Run `/wiz-phases <slug>` to break down into implementation phases
3. **Start Implementation**: Run `/wiz-next` to begin Phase 1, Milestone 1

## Files Created

- `.wiz/<slug>/prd.md` - Comprehensive PRD document
- `.wiz/<slug>/intake/qa.md` - Q&A session summary
- `.wiz/<slug>/intake/questions.json` - Generated questions
- `.wiz/<slug>/intake/answers.json` - Your answers
- `.wiz/<slug>/intake/state.json` - Workflow state

You can now review the PRD and proceed with phasing when ready.
```

## Error Handling

- **Invalid slug format**: Show format requirements
- **Missing arguments**: Show usage example
- **Directory exists**: Suggest using different slug or removing existing
- **File write errors**: Check permissions and disk space. If main agent fails to write, retry the Write operation
- **Agent errors**: Show detailed error message and recovery steps
- **Agent returns no content**: If agent response doesn't contain code blocks with expected content, ask agent to retry with explicit formatting instructions

## Example Usage

```bash
/wiz-prd auth-system "Add user authentication with email/password and OAuth"
```

This will:

1. Create `.wiz/auth-system/intake/` directory
1. Generate clarifying questions
1. Wait for user answers in chat
1. Research and create comprehensive PRD
1. Save PRD to `.wiz/auth-system/prd.md`

## Notes

- This is a **three-stage** command that continues automatically
- User answers questions **in chat**, no need to re-run command
- Research phase uses web tools if available
- PRD template includes all standard sections with NFR priority order
- Command delegates to `wiz-planner` agent (reference `.cursor/agents/wiz-planner.md`)
