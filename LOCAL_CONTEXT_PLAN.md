# Plan: Integrating Local Context Support

## Overview

This plan outlines changes to enable Wiz commands and agents to **FIRST** consider user-provided local context from `.wiz/context/**/*.md` before consulting specialists or using default recommendations. Local context must have **100% preference** over specialist recommendations, and specialists must explicitly defer to it.

## Goals

1. ✅ Commands that plan (`/wiz-prd`, `/wiz-phases`, `/wiz-milestones`) load local context FIRST
2. ✅ Commands that execute (`/wiz-next`, `/wiz-auto`) load local context FIRST before consulting specialists
3. ✅ Language specialists explicitly defer to local context when it exists
4. ✅ `wiz-milestone-analyst` considers local context in analysis
5. ✅ Local context does NOT interfere with Wiz workflow (file structure, quality gates, etc.)

## Local Context Structure

Users create context files in `.wiz/context/**/*.md` with **frontmatter metadata** for intelligent loading.

### Context File Format

Each context file MUST have YAML frontmatter with metadata:

```markdown
---
description: Preferred frameworks and libraries for this project
tags: [frameworks, libraries, dependencies]
languages: [go, typescript, python]
applies_to: [planning, execution]
---

# Preferred Frameworks

- **Backend**: FastAPI for APIs, SQLAlchemy for ORM
- **Testing**: pytest with pytest-asyncio
- **HTTP Client**: httpx (not requests)
```

### Frontmatter Fields

- **`description`** (required): Brief description of what this context covers
- **`tags`** (optional): Array of tags for categorization (e.g., `[frameworks, architecture, patterns]`)
- **`languages`** (optional): Array of languages this applies to (e.g., `[go, typescript]`)
  - If not specified, applies to all languages
- **`applies_to`** (optional): Array of when this applies (e.g., `[planning, execution, review]`)
  - If not specified, applies to everything (planning, execution, review)

### Example Context Files

```
.wiz/
└── context/
    ├── frameworks.md          # Framework preferences
    ├── technologies.md        # Technology decisions (gRPC vs HTTP)
    ├── go/
    │   └── patterns.md        # Go-specific patterns
    └── architecture/
        └── decisions.md       # Architectural decisions
```

## Implementation Plan

### Phase 1: Create Context Metadata Loading Function

**File**: Update all command files with shared utility function

**Function**: `wiz_load_context_metadata()`

This function loads ONLY the frontmatter from all context files, allowing AI to decide which files to read.

```bash
# Load metadata (frontmatter) from all local context files
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
                local description=$(echo "$frontmatter" | grep -E "^description:" | sed 's/^description:[[:space:]]*//' | sed 's/^"//;s/"$//')
                local tags=$(echo "$frontmatter" | grep -E "^tags:" | sed 's/^tags:[[:space:]]*//' | sed "s/^\[//;s/\]$//" | tr ',' '\n' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | jq -R . | jq -s . 2>/dev/null || echo "[]")
                local languages=$(echo "$frontmatter" | grep -E "^languages:" | sed 's/^languages:[[:space:]]*//' | sed "s/^\[//;s/\]$//" | tr ',' '\n' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | jq -R . | jq -s . 2>/dev/null || echo "[]")
                local applies_to=$(echo "$frontmatter" | grep -E "^applies_to:" | sed 's/^applies_to:[[:space:]]*//' | sed "s/^\[//;s/\]$//" | tr ',' '\n' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | jq -R . | jq -s . 2>/dev/null || echo "[]")
                
                # If languages/applies_to are empty, they apply to everything (represented as empty array)
                # AI will interpret empty array as "applies to all"
                
                # Build JSON entry
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
    done < <(find "$context_dir" -type f -name "*.md" -print0 2>/dev/null | sort -z)
    
    echo "$metadata_json"
}

# Load full content of a specific context file
wiz_load_context_file() {
    local context_file="$1"
    local full_path=".wiz/context/$context_file"
    
    if [[ ! -f "$full_path" ]]; then
        echo ""
        return 1
    fi
    
    # Return file content (without frontmatter for cleaner output)
    awk '/^---$/{count++; if(count==2) flag=1; next} flag' "$full_path"
}
```

**Placement**: Add to "Embedded Utility Functions" section in:
- `.cursor/commands/wiz-prd.md`
- `.cursor/commands/wiz-phases.md`
- `.cursor/commands/wiz-milestones.md`
- `.cursor/commands/wiz-next.md`
- `.cursor/commands/wiz-auto.md`

### Phase 2: Modify Planning Commands

#### 2.1: `/wiz-prd` Command

**Location**: `.cursor/commands/wiz-prd.md`

**Changes**:
1. Load context metadata BEFORE codebase analysis
2. Present metadata to AI, let AI decide which files to read
3. Include loaded context in prompt to `wiz-planner` agent
4. Make it clear to planner that local context takes precedence

**Modification Point**: After argument validation, before codebase analysis

```bash
# Load context metadata FIRST
CONTEXT_METADATA=$(wiz_load_context_metadata)
if [[ "$CONTEXT_METADATA" != "[]" ]] && [[ -n "$CONTEXT_METADATA" ]]; then
    wiz_log_info "Found local context files in .wiz/context/"
    # Log available context files
    echo "$CONTEXT_METADATA" | jq -r '.[] | "  - \(.path): \(.description)"' || true
fi
```

**AI Decision Point**: The AI should:
1. Review the metadata JSON
2. Identify which context files are relevant:
   - If `applies_to` is empty array → applies to everything (planning, execution, review)
   - If `languages` is empty array → applies to all languages
   - If `applies_to` contains current command type → relevant
   - If `languages` contains detected language → relevant
   - If `tags` or `description` suggest relevance → relevant
3. Read only relevant files using `wiz_load_context_file()`
4. Use the loaded context in planning

**Prompt Modification**: When delegating to `wiz-planner`, include:

```
## Available Local Context

The following local context files are available in `.wiz/context/**/*.md`:

{CONTEXT_METADATA_JSON}

**Your Task:**
1. Review the metadata above
2. Identify which context files are relevant for PRD generation
3. Read only the relevant files using: `wiz_load_context_file("<path>")`
4. Use the loaded context in your planning

**CRITICAL**: When local context is loaded:
- **LOCAL CONTEXT TAKES ABSOLUTE PRECEDENCE** over your default recommendations
- If local context specifies frameworks → Use those, not your defaults
- If local context specifies technology choices → Respect those decisions
- If local context specifies patterns → Use those patterns
- Only use your defaults when local context doesn't address the topic

**Priority**: Local context > Your recommendations > General best practices
```

#### 2.2: `/wiz-phases` Command

**Location**: `.cursor/commands/wiz-phases.md`

**Changes**:
1. Load context metadata before reading PRD
2. Present metadata to AI, let AI decide which files to read
3. Include loaded context in prompt to `wiz-planner` for phase generation

**Modification Point**: After PRD validation, before delegating to planner

```bash
# Load context metadata FIRST
CONTEXT_METADATA=$(wiz_load_context_metadata)
if [[ "$CONTEXT_METADATA" != "[]" ]] && [[ -n "$CONTEXT_METADATA" ]]; then
    wiz_log_info "Found local context files in .wiz/context/"
fi
```

**Prompt Modification**: Similar to `/wiz-prd` - present metadata, let AI decide what to read

#### 2.3: `/wiz-milestones` Command

**Location**: `.cursor/commands/wiz-milestones.md`

**Changes**:
1. Load context metadata before reading phases
2. Present metadata to AI, let AI decide which files to read
3. Include loaded context in milestone generation

**Modification Point**: After phase validation, before milestone generation

```bash
# Load context metadata FIRST
CONTEXT_METADATA=$(wiz_load_context_metadata)
if [[ "$CONTEXT_METADATA" != "[]" ]] && [[ -n "$CONTEXT_METADATA" ]]; then
    wiz_log_info "Found local context files in .wiz/context/"
fi
```

### Phase 3: Modify Execution Commands

#### 3.1: `/wiz-next` Command

**Location**: `.cursor/commands/wiz-next.md`

**Changes**:
1. Load context metadata BEFORE loading design guidelines
2. Present metadata to AI, let AI decide which files to read
3. Include loaded context in execution context
4. Pass context metadata to specialists when consulting them

**Modification Point**: Step 6 - "Load Context" section

```bash
# Load context metadata FIRST (before design guidelines)
CONTEXT_METADATA=$(wiz_load_context_metadata)
if [[ "$CONTEXT_METADATA" != "[]" ]] && [[ -n "$CONTEXT_METADATA" ]]; then
    wiz_log_info "Found local context files in .wiz/context/"
fi

# Load phase document
PHASE_CONTENT=$(cat "$NEXT_PHASE_FILE")

# Extract milestone section
MILESTONE_SECTION=$(awk "/^### ${MILESTONE_ID}:/,/^---$|^### [A-Z0-9]+:/" "$NEXT_PHASE_FILE" | sed '$ d')

# Detect language from milestone/phase to help AI filter context
DETECTED_LANG=""
# (AI will detect language and use it to filter context metadata)

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
```

**AI Decision Point**: The AI should:
1. Review the metadata JSON
2. Identify which context files are relevant:
   - If `applies_to` is empty array → applies to everything (including execution)
   - If `applies_to` contains "execution" → relevant
   - If `languages` is empty array → applies to all languages (relevant)
   - If `languages` matches detected language → relevant
   - If `tags` match milestone topic → relevant
   - If `description` suggests relevance → relevant
3. Read only relevant files using `wiz_load_context_file()`
4. Include loaded context in execution

**Specialist Consultation Modification**: When consulting specialists, include:

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

---

## Milestone Context
{...}

## Changes to Review
{...}
```

#### 3.2: `/wiz-auto` Command

**Location**: `.cursor/commands/wiz-auto.md`

**Changes**: Same as `/wiz-next` - load context metadata FIRST in the loop

**Modification Point**: Inside the `while true` loop, before loading design guidelines

```bash
# Load context metadata FIRST (inside loop, before each milestone)
# Load once outside loop for efficiency, reuse inside
if [[ -z "${CONTEXT_METADATA_LOADED:-}" ]]; then
    CONTEXT_METADATA=$(wiz_load_context_metadata)
    export CONTEXT_METADATA
    export CONTEXT_METADATA_LOADED=1
    if [[ "$CONTEXT_METADATA" != "[]" ]] && [[ -n "$CONTEXT_METADATA" ]]; then
        wiz_log_info "Found local context files in .wiz/context/"
    fi
fi

# Load execution context
PHASE_CONTENT=$(cat "$NEXT_PHASE_FILE")
MILESTONE_SECTION=$(awk "/^### ${MILESTONE_ID}:/,/^---$|^### [A-Z0-9]+:/" "$NEXT_PHASE_FILE" | sed '$ d')

# ... rest of context loading
```

**Note**: Load metadata once outside the loop since it doesn't change between milestones. AI can decide which files to read per milestone.

### Phase 4: Modify Language Specialists

**Files to Update**:
- `.cursor/agents/wiz-go-specialist.md`
- `.cursor/agents/wiz-typescript-specialist.md`
- `.cursor/agents/wiz-python-specialist.md`
- `.cursor/agents/wiz-csharp-specialist.md`
- `.cursor/agents/wiz-java-specialist.md`
- `.cursor/agents/wiz-docker-specialist.md`

**Changes**: Add new section at the top (after role description):

```markdown
## ⚠️ CRITICAL: Local Context Precedence

**YOU MUST DEFER TO LOCAL CONTEXT WHEN PROVIDED.**

When the command agent provides local context metadata from `.wiz/context/**/*.md`:

1. **Review the metadata FIRST** to identify relevant context files
2. **Read relevant files** using `wiz_load_context_file("<path>")` if they apply to your domain
3. **If local context addresses the topic** → Use that guidance, acknowledge it explicitly
4. **If local context conflicts with your recommendations** → Explicitly state: "Local context specifies X, so I recommend following that over my general recommendation of Y"
5. **If local context doesn't address the topic** → Provide your expert recommendation as usual

**Relevance Criteria:**
- If `languages` is empty array → applies to all languages (including yours)
- If `languages` includes your language (e.g., "go" for wiz-go-specialist) → relevant
- If `tags` match the topic (e.g., "frameworks", "patterns") → relevant
- If `description` suggests it's relevant → relevant

**Example Response Pattern:**

```markdown
## Recommendation

I reviewed available local context and found `frameworks.md` specifies using [X framework] for this scenario. I recommend following that guidance.

[Your recommendation based on local context]

## Rationale

[Why local context's approach fits, or acknowledge if you'd normally recommend something else]
```

**When NO local context is provided or no relevant files exist:**
- Provide your expert recommendations as usual
- Reference your preferred technology stack (as documented in your agent file)
```

**Placement**: Add this section right after "## Your Role: Advisory & Consultative" and before "## Tools Available"

### Phase 5: Modify wiz-planner Agent

**File**: `.cursor/agents/wiz-planner.md`

**Changes**: Add section about local context precedence

**Modification Point**: After "## Context Usage" section

```markdown
## Local Context Priority

**CRITICAL**: When local context metadata from `.wiz/context/**/*.md` is provided:

1. **Review metadata** to identify relevant context files
2. **Read relevant files** using `wiz_load_context_file("<path>")` based on:
   - If `applies_to` is empty array → applies to everything (including planning)
   - If `applies_to` contains "planning" → relevant
   - If `languages` is empty array → applies to all languages → relevant
   - If `languages` matches detected languages → relevant
   - If `tags` match your planning needs → relevant
   - If `description` suggests relevance → relevant
3. **Local context takes ABSOLUTE precedence** over research and best practices
4. If local context specifies frameworks → Use those, don't research alternatives
5. If local context specifies patterns → Use those patterns
6. If local context specifies technology choices → Respect those decisions
7. Only research when local context doesn't address a topic

**Example:**
- Local context says "Use FastAPI" → Use FastAPI, don't research Django/Flask
- Local context says "gRPC for internal services" → Plan gRPC, not HTTP REST
- Local context says "Follow X pattern" → Use X pattern, not alternatives

**When generating PRDs/Phases/Milestones:**
- Reference local context explicitly in output
- Note when recommendations align with local context
- Acknowledge when deviating from general best practices due to local context
- Only read context files that are relevant to avoid unnecessary token usage
```

### Phase 6: Modify wiz-milestone-analyst Agent

**File**: `.cursor/agents/wiz-milestone-analyst.md`

**Changes**: Consider local context metadata in analysis

**Modification Point**: Update "## Analysis Workflow" section

```markdown
### Step 2: Gather Context

- Search for related files and patterns
- Check for existing implementations
- **Review local context metadata from `.wiz/context/**/*.md` (if provided)**
  - If relevant context files exist, read them using `wiz_load_context_file("<path>")`
  - If `applies_to` is empty → applies to everything (including execution/planning)
  - If `applies_to` includes "execution" or "planning" → relevant
  - If `languages` is empty → applies to all languages → relevant
  - If `languages` matches detected language → relevant
- Review design guidelines for relevant languages
- Check previous milestones in the phase

**When local context exists:**
- Consider if local context provides guidance for this milestone
- Note if milestone requirements align with local context patterns
- Flag if milestone conflicts with local context (may need human clarification)
```

**Also update "## Context Analysis" section**:

```markdown
**Technical Context:**
- Existing codebase patterns and architecture
- **Local context guidance (if provided)** - check metadata, read relevant files
- Related files and dependencies
- Previous milestones in the same phase
- Design guidelines for relevant languages
```

### Phase 7: Update Documentation

**Files to Update**:
- `README.md` - Add section about local context
- `docs/commands.md` - Document local context loading
- `docs/agents.md` - Document local context precedence

**New Section in README.md** (after "## Best Practices"):

```markdown
## Local Context Support

Wiz respects user-provided local context for project-specific guidance. Context files use frontmatter metadata to enable intelligent, selective loading.

### Creating Local Context

Create markdown files in `.wiz/context/**/*.md` with YAML frontmatter. Each file MUST include a `description` field, and can optionally include tags, languages, and applies_to fields.

**Required Frontmatter:**
- `description`: Brief description of what this context covers

**Optional Frontmatter:**
- `tags`: Array of tags (e.g., `[frameworks, architecture, patterns]`)
- `languages`: Array of languages this applies to (e.g., `[go, typescript]`)
  - If omitted, applies to all languages
- `applies_to`: Array of when this applies (e.g., `[planning, execution, review]`)
  - If omitted, applies to everything (planning, execution, review)

**Example `.wiz/context/frameworks.md`:**

```markdown
---
description: Preferred frameworks and libraries for this project
tags: [frameworks, libraries, dependencies]
languages: [python, typescript]
applies_to: [planning, execution]
---

# Preferred Frameworks

- **Backend**: FastAPI for APIs, SQLAlchemy for ORM
- **Testing**: pytest with pytest-asyncio
- **HTTP Client**: httpx (not requests)
- **Background Jobs**: Celery with Redis
```

**Example `.wiz/context/technologies.md`:**

```markdown
---
description: Technology decisions for service communication and protocols
tags: [architecture, protocols, communication]
applies_to: [planning, execution]
---

# Technology Decisions

## gRPC vs HTTP REST

- Use **gRPC** for internal service-to-service communication
- Use **HTTP REST** for external/public APIs
- Use **WebSockets** for real-time features (not Server-Sent Events)
```

### How Local Context Works

1. **Metadata Loading**: Commands load frontmatter metadata from all context files
2. **Intelligent Selection**: AI reviews metadata and decides which files are relevant
3. **Selective Reading**: Only relevant context files are fully loaded (saves tokens)
4. **Highest Priority**: Local context takes precedence over all specialist recommendations
5. **Planning**: `/wiz-prd`, `/wiz-phases`, `/wiz-milestones` check metadata and load relevant context
6. **Execution**: `/wiz-next` and `/wiz-auto` check metadata and load relevant context before consulting specialists
7. **Specialists**: Language specialists check metadata and read relevant files before providing recommendations

### Local Context Examples

**`.wiz/context/go/patterns.md`:**
```markdown
---
description: Go-specific patterns and conventions for this project
tags: [patterns, conventions, go]
languages: [go]
applies_to: [execution]
---

# Go Patterns

- Use `uber/fx` for dependency injection
- Prefer `xsync/v4` for concurrent maps (not sync.Map)
- Use `uber/zap` for logging
```

**`.wiz/context/architecture.md`:**
```markdown
---
description: High-level architectural decisions and patterns
tags: [architecture, design, patterns]
applies_to: [planning]
---

# Architecture Decisions

- Microservices communicate via gRPC
- Database per service pattern
- Event-driven architecture with Kafka
```
```

## Implementation Checklist

### Commands
- [ ] Add `wiz_load_context_metadata()` function to `/wiz-prd`
- [ ] Add `wiz_load_context_file()` function to `/wiz-prd`
- [ ] Add `wiz_load_context_metadata()` function to `/wiz-phases`
- [ ] Add `wiz_load_context_file()` function to `/wiz-phases`
- [ ] Add `wiz_load_context_metadata()` function to `/wiz-milestones`
- [ ] Add `wiz_load_context_file()` function to `/wiz-milestones`
- [ ] Add `wiz_load_context_metadata()` function to `/wiz-next`
- [ ] Add `wiz_load_context_file()` function to `/wiz-next`
- [ ] Add `wiz_load_context_metadata()` function to `/wiz-auto`
- [ ] Add `wiz_load_context_file()` function to `/wiz-auto`
- [ ] Modify `/wiz-prd` to load metadata and present to AI
- [ ] Modify `/wiz-phases` to load metadata and present to AI
- [ ] Modify `/wiz-milestones` to load metadata and present to AI
- [ ] Modify `/wiz-next` to load metadata FIRST
- [ ] Modify `/wiz-next` to pass metadata to specialists
- [ ] Modify `/wiz-auto` to load metadata FIRST (once outside loop)
- [ ] Modify `/wiz-auto` to pass metadata to specialists

### Agents
- [ ] Add local context precedence section to `wiz-go-specialist`
- [ ] Add local context precedence section to `wiz-typescript-specialist`
- [ ] Add local context precedence section to `wiz-python-specialist`
- [ ] Add local context precedence section to `wiz-csharp-specialist`
- [ ] Add local context precedence section to `wiz-java-specialist`
- [ ] Add local context precedence section to `wiz-docker-specialist`
- [ ] Add local context priority section to `wiz-planner`
- [ ] Update `wiz-milestone-analyst` to consider local context

### Documentation
- [ ] Add local context section to `README.md`
- [ ] Update `docs/commands.md` with local context info
- [ ] Update `docs/agents.md` with local context precedence

## Testing Considerations

1. **Test without local context** - Ensure commands work normally
2. **Test with local context** - Verify it's loaded and used
3. **Test conflicts** - Verify specialists defer to local context
4. **Test multiple files** - Verify all `.md` files are loaded
5. **Test nested structure** - Verify recursive loading works
6. **Test empty context** - Verify no errors when context dir doesn't exist

## Non-Interference Guarantees

Local context **DOES NOT** interfere with:

- ✅ File structure (`.wiz/<slug>/` structure unchanged)
- ✅ Quality gates (tests, linting still enforced)
- ✅ Workflow (PRD → Phases → Milestones → Execution)
- ✅ Commit format (still follows Wiz commit format)
- ✅ Resume state (still works as before)
- ✅ State management (`.wiz/state.json` unchanged)

Local context **ONLY** affects:

- ✅ Framework/library recommendations
- ✅ Pattern guidance
- ✅ Technology choices
- ✅ Code style preferences
- ✅ Architecture decisions

## Summary

This plan ensures that:

1. **Context metadata is loaded FIRST** in all planning and execution commands
2. **AI intelligently selects** which context files to read based on metadata
3. **Only relevant context is loaded** - saves tokens and improves efficiency
4. **Local context has absolute precedence** over specialist recommendations
5. **Specialists explicitly defer** to local context when provided
6. **Wiz workflow remains unchanged** - only guidance changes, not structure or process
7. **Clear documentation** explains how to use local context with frontmatter

### Key Benefits of Metadata Approach

- ✅ **Token Efficient**: Only loads relevant context files, not everything
- ✅ **Intelligent**: AI decides what's relevant based on metadata
- ✅ **Flexible**: Users can organize context files however they want
- ✅ **Scalable**: Works even with many context files
- ✅ **Backward Compatible**: If no context exists, everything works as before

The implementation is backward compatible - if no local context exists, everything works as before.

