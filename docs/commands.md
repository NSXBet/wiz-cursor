# Wiz Commands Documentation

Complete reference for all Wiz Planner commands available in Cursor.

## Command Categories

- **Planning Commands**: Create PRDs, phases, and milestones
- **Execution Commands**: Implement milestones and manage work
- **Review Commands**: Quality assurance and validation
- **Utility Commands**: Status tracking and help

______________________________________________________________________

## Planning Commands

### `/wiz-prd`

**Description**: Generate comprehensive Product Requirements Document through guided Q&A with research

**Usage**:

```bash
/wiz-prd <slug> "<idea>"
```

**Arguments**:

- `<slug>`: Unique identifier for this PRD (lowercase, hyphens, alphanumeric only)
- `"<idea>"`: Brief description of the feature or project idea (in quotes)

**Workflow**:

1. **Codebase Analysis**: Analyzes repository to detect language, patterns, and infrastructure
1. **Question Generation**: Creates 8-12 clarifying questions based on codebase context
1. **Human Answers**: Waits for you to provide answers (DO NOT answer yourself)
1. **Research Phase**: Researches best practices, architectural patterns, and current standards
1. **PRD Generation**: Creates comprehensive PRD document

**Output**:

- `.wiz/<slug>/prd.md` - Comprehensive PRD document
- `.wiz/<slug>/intake/questions.json` - Generated questions
- `.wiz/<slug>/intake/answers.json` - Your answers
- `.wiz/<slug>/intake/qa.md` - Q&A session summary

**Example**:

```bash
/wiz-prd auth-system "Add user authentication with email/password and OAuth"
```

**Agent Used**: `wiz-planner`

**Important Notes**:

- ⚠️ Questions MUST be answered by HUMAN, NOT by AI
- Command analyzes codebase first to skip obvious questions
- **Loads local context metadata** from `.wiz/context/**/*.md` before generating questions
- Research phase uses WebSearch/WebFetch for current best practices
- PRD includes overview, requirements, architecture, success criteria, risks, and implementation notes
- **Local context takes precedence** over research and default recommendations

______________________________________________________________________

### `/wiz-phases`

**Description**: Break PRD into implementation phases

**Usage**:

```bash
/wiz-phases <slug>
```

**Arguments**:

- `<slug>`: PRD slug (must exist at `.wiz/<slug>/prd.md`)

**Workflow**:

1. Reads PRD document
1. Generates 3-15 logical implementation phases
1. Each phase is ~3-5 days of work
1. Creates phase files with goals, dependencies, and acceptance criteria
1. Generates design guidelines for detected languages

**Output**:

- `.wiz/<slug>/phases/phase1.md`, `phase2.md`, etc. - Phase documents
- `.wiz/design-guidelines/<language>.md` - Language-specific design guidelines

**Phase Structure**:

- Phase title and duration
- Dependencies on other phases
- Phase-level goal
- Phase-level acceptance criteria
- Design guidelines references

**Example**:

```bash
/wiz-phases auth-system
```

**Agent Used**: `wiz-planner`

**Important Notes**:

- **Loads local context metadata** from `.wiz/context/**/*.md` before generating phases
- Phases build on each other logically
- Each phase delivers working functionality
- Design guidelines generated for each detected language
- **Local context takes precedence** over default recommendations

______________________________________________________________________

### `/wiz-milestones`

**Description**: Generate detailed milestones for all phases

**Usage**:

```bash
/wiz-milestones <slug>
```

**Arguments**:

- `<slug>`: PRD slug (phases must exist at `.wiz/<slug>/phases/`)

**Workflow**:

1. Reads all phase documents
1. Generates 15-40 milestones per phase
1. Each milestone is ~1 hour of focused work
1. Adds milestones to phase files
1. Generates IMPLEMENTATION_GUIDE.md

**Output**:

- Updated phase files with milestones added
- `.wiz/<slug>/IMPLEMENTATION_GUIDE.md` - Developer guide

**Milestone Structure**:

```markdown
### P##M##: <Title>

**Status:** 🚧 TODO
**ID:** P##M##

**Goal**
[Single clear sentence]

**Acceptance Criteria**
- [ ] Specific, testable criterion 1
- [ ] Specific, testable criterion 2
- [ ] All tests passing
- [ ] Documentation updated
```

**Example**:

```bash
/wiz-milestones auth-system
```

**Agent Used**: `wiz-planner`

**Important Notes**:

- **Loads local context metadata** from `.wiz/context/**/*.md` before generating milestones
- Milestones are ~1 hour each (30 minutes to 2 hours acceptable)
- Each milestone has clear, testable acceptance criteria
- Milestones include NFR requirements (P0-P4)
- **Local context takes precedence** over default recommendations

______________________________________________________________________

## Execution Commands

### `/wiz-next`

**Description**: Execute the next TODO milestone

**Usage**:

```bash
/wiz-next [slug] [count]
```

**Arguments**:

- `[slug]` (optional): PRD slug (defaults to current PRD from state)
- `[count]` (optional): Number of milestones to execute (default: 1)

**Workflow**:

1. **Find Next Milestone**: Locates next TODO milestone
1. **Load Context**: Phase, milestone, design guidelines
1. **Analyze Milestone**: Detects language, understands requirements
1. **Optional Specialist Consultation**: Gets guidance from language specialists
1. **Implement Milestone**: Writes code, tests, documentation
1. **Validate**: Runs ALL tests (zero failures, zero skips)
1. **Lint**: Runs ALL linters (zero errors)
1. **Specialist Review**: Language specialists review diff
1. **Create Commit**: Creates properly formatted commit
1. **Update Status**: Marks milestone as COMPLETE

**Context Loading**:

- **Loads local context metadata FIRST** from `.wiz/context/**/*.md` before design guidelines
- AI reviews metadata and loads only relevant context files
- Local context shared with language specialists during consultation
- **Local context takes precedence** over specialist recommendations

**Quality Gates**:

- ✅ All tests pass (no failures, no skips)
- ✅ All linters pass (zero errors)
- ✅ Entire codebase healthy (not just new code)
- ✅ Language specialist approval

**Commit Format**:

```
feat(P##M##): <Milestone Title>

Completed milestone P##M##.

🤖 Generated with Wiz Planner

Co-Authored-By: Wiz <wiz@flutterbrazil.com>
```

**Example**:

```bash
/wiz-next
/wiz-next auth-system
/wiz-next auth-system 3
```

**Agents Used**:

- Language specialists (for guidance and review)
- Optional: `wiz-milestone-analyst` (for complex milestones)

**Important Notes**:

- ⚠️ CRITICAL: Entire codebase must be healthy (fixes regressions)
- Zero tolerance for failing/skipped tests or lint errors
- Creates resume state for interruption recovery
- Automatically commits when milestone complete

______________________________________________________________________

### `/wiz-auto`

**Description**: Auto-execute milestones with intelligent gating

**Usage**:

```bash
/wiz-auto [slug] [max-milestones]
```

**Arguments**:

- `[slug]` (optional): PRD slug (defaults to current PRD from state)
- `[max-milestones]` (optional): Maximum milestones to execute (default: unlimited)

**Workflow**:

1. **Find Next Milestone**: Locates next TODO milestone
1. **Analyze NEXT Milestone**: `wiz-milestone-analyst` evaluates NEXT milestone
1. **If PROCEED**: Execute current milestone (same as `/wiz-next`)
1. **If HALT**: Present questions to user and wait for input
1. **Repeat**: Loop until no more milestones or max reached

**Context Loading**:

- **Loads local context metadata ONCE** before loop (reuses inside loop)
- AI reviews metadata and loads only relevant context files per milestone
- Local context shared with language specialists during consultation
- **Local context takes precedence** over specialist recommendations

**Gating Logic**:

- Analyst checks NEXT milestone (not current)
- PROCEED: Requirements clear, low risk, obvious path
- HALT: Ambiguities, design decisions, high complexity, security concerns

**Quality Gates**: Same as `/wiz-next`

**Example**:

```bash
/wiz-auto
/wiz-auto auth-system
/wiz-auto auth-system 10
```

**Agents Used**:

- `wiz-milestone-analyst` (for gating decisions)
- Language specialists (for guidance and review)

**Important Notes**:

- Stops for human input when analyst recommends HALT
- Analyzes NEXT milestone after current completes
- Perfect for batch implementation with safety checks
- Can be interrupted and resumed with `/wiz-resume`

______________________________________________________________________

### `/wiz-resume`

**Description**: Resume work on in-progress milestone

**Usage**:

```bash
/wiz-resume
```

**Arguments**: None

**Workflow**:

1. **Load Resume State**: Reads `.wiz/.current-milestone.json`
1. **Display Context**: Shows milestone details and elapsed time
1. **Offer Options**:
   - Continue working on this milestone
   - Skip to next TODO milestone
   - Cancel and return to shell

**Resume State**:

- Created automatically by `/wiz-next` and `/wiz-auto`
- Includes milestone ID, phase info, start time
- Preserved on interruption

**Example**:

```bash
/wiz-resume
```

**Options**:

1. **Continue**: Resume implementation of current milestone
1. **Skip**: Move to next TODO milestone (clears resume state)
1. **Cancel**: Exit without changes

**Important Notes**:

- Resume state created automatically during execution
- Elapsed time calculated from start timestamp
- Stale resume state automatically cleared
- Works with both legacy and new state formats

______________________________________________________________________

## Review Commands

### `/wiz-review-milestone`

**Description**: Review completed milestone for quality and completeness

**Usage**:

```bash
/wiz-review-milestone <slug> <milestone-id>
```

**Arguments**:

- `<slug>`: PRD slug
- `<milestone-id>`: Milestone ID (e.g., `P01M05`)

**Workflow**:

1. **Load Milestone**: Extracts goal and acceptance criteria
1. **Verify Criteria**: Checks each criterion systematically
1. **Assess Code Quality**: Reviews implementation against standards
1. **Check NFR Compliance**: Verifies P0-P4 requirements
1. **Test Coverage**: Verifies tests exist and pass
1. **Generate Report**: Creates detailed review report

**Review Report Structure**:

- Summary (2-3 sentence assessment)
- Acceptance Criteria Verification (Met/Partial/Not Met for each)
- Code Quality Assessment (Excellent/Good/Acceptable/Needs Improvement/Poor)
- NFR Compliance (P0-P4 status)
- Recommendations (High/Medium/Low priority)
- Overall Assessment (Pass/Warn/Fail)

**Example**:

```bash
/wiz-review-milestone auth-system P02M15
```

**Agent Used**: `wiz-reviewer`

**Important Notes**:

- Provides evidence (file:line) for all findings
- Distinguishes between requirements and preferences
- Notes strengths alongside weaknesses
- Assigns overall Pass/Warn/Fail verdict

______________________________________________________________________

### `/wiz-review-phase`

**Description**: Review completed phase for quality and integration

**Usage**:

```bash
/wiz-review-phase <slug> <phase-number>
```

**Arguments**:

- `<slug>`: PRD slug
- `<phase-number>`: Phase number (e.g., `1`, `2`)

**Workflow**:

1. **Verify Completion**: All milestones marked COMPLETE
1. **Check Integration**: Components work together
1. **Assess Phase Goals**: Phase-level acceptance criteria met
1. **NFR Compliance**: All priorities addressed
1. **Quality Standards**: Consistent quality across milestones
1. **Documentation**: Phase goals documented
1. **Generate Report**: Overall phase assessment

**Review Focus**:

- Completeness (all milestones done)
- Integration (components work together)
- Quality consistency (no weak spots)
- NFR compliance (standards maintained)
- Documentation (phase well-documented)

**Example**:

```bash
/wiz-review-phase auth-system 2
```

**Agent Used**: `wiz-reviewer`

**Important Notes**:

- Reviews entire phase, not individual milestones
- Checks integration between components
- Verifies phase-level acceptance criteria
- Provides comprehensive phase assessment

______________________________________________________________________

### `/wiz-validate-all`

**Description**: Validate entire codebase for quality and health

**Usage**:

```bash
/wiz-validate-all
```

**Arguments**: None

**Workflow**:

1. **Detect Languages**: Identifies all languages in codebase
1. **Run Tests**: Executes test suites for all languages
1. **Run Linters**: Executes linters for all languages
1. **Security Scan**: Checks for security vulnerabilities
1. **Generate Report**: Creates comprehensive validation report

**Validation Checks**:

- ✅ All tests pass (no failures, no skips)
- ✅ All linters pass (zero errors)
- ✅ No security vulnerabilities
- ✅ Code quality standards met

**Output**:

- `.wiz/validation-report.md` - Comprehensive validation report
- Console output with summary

**Example**:

```bash
/wiz-validate-all
```

**Agents Used**: Language specialists (for language-specific checks)

**Important Notes**:

- Validates ENTIRE codebase, not just recent changes
- Fails fast on critical issues (P0)
- Provides actionable recommendations
- Creates detailed report for review

______________________________________________________________________

## Utility Commands

### `/wiz-status`

**Description**: Display project progress and milestone statistics

**Usage**:

```bash
/wiz-status
```

**Arguments**: None

**Displays**:

- Current PRD information
- Phase completion percentages
- Milestone statistics (TODO, IN_PROGRESS, COMPLETE)
- Time estimates
- Current and next milestones

**Output Format**:

```
╔══════════════════════════════════════════════════════════╗
║           Wiz Planner - Project Status                  ║
╚══════════════════════════════════════════════════════════╝

PRD: auth-system
Status: In Progress

Phase 1: Foundation & User Model
  Progress: ████████████████████░░░░ 85% (17/20 milestones)
  Status: ✅ COMPLETE

Phase 2: Authentication Logic
  Progress: ████████████░░░░░░░░░░░░ 60% (12/20 milestones)
  Status: 🚧 IN PROGRESS
  Current: P02M13 - Implement JWT validation middleware
  Next: P02M14 - Add refresh token endpoint

...

Overall Progress: 145/300 milestones (48%)
Estimated Time Remaining: ~155 hours
```

**Example**:

```bash
/wiz-status
```

**Important Notes**:

- Reads from `.wiz/state.json` or phase files
- Calculates progress percentages
- Shows time estimates based on milestone counts
- Displays current and next milestones

______________________________________________________________________

### `/wiz-help`

**Description**: Show help for Wiz Planner commands

**Usage**:

```bash
/wiz-help [command-name]
```

**Arguments**:

- `[command-name]` (optional): Name of command to show help for (without `/` prefix)

**Behavior**:

- **No argument**: Shows quick help summary for all commands
- **With argument**: Shows detailed help for specific command

**Help Content**:

- Description from YAML frontmatter
- Usage information with argument hints
- Examples from command documentation
- Common options if available
- Troubleshooting tips

**Example**:

```bash
/wiz-help
/wiz-help wiz-next
/wiz-help wiz-prd
```

**Important Notes**:

- Extracts information from command files automatically
- Shows examples from command documentation
- Links to complete documentation

______________________________________________________________________

## Local Context Integration

All planning and execution commands support **local context** from `.wiz/context/**/*.md`:

### How It Works

1. **Metadata Loading**: Commands call `wiz_load_context_metadata()` which extracts frontmatter from all context files
1. **Intelligent Selection**: AI reviews metadata (description, tags, languages, applies_to) and selects relevant files
1. **Selective Reading**: Only relevant files are fully loaded using `wiz_load_context_file()` to save tokens
1. **Precedence**: Local context takes **absolute precedence** over specialist recommendations and research

### Context File Format

Context files use YAML frontmatter with:

- `description` (required): Brief description
- `tags` (optional): Array of tags for categorization
- `languages` (optional): Array of languages (empty = all languages)
- `applies_to` (optional): Array of stages (empty = all stages)

### Commands That Use Local Context

| Command | When Context Loaded | Usage |
|---------|---------------------|-------|
| `/wiz-prd` | Before question generation | Influences questions and PRD recommendations |
| `/wiz-phases` | Before phase generation | Influences phase structure and technology choices |
| `/wiz-milestones` | Before milestone generation | Influences milestone tasks and patterns |
| `/wiz-next` | Before design guidelines | Influences implementation approach |
| `/wiz-auto` | Once before loop | Influences implementation approach for all milestones |

### Example Context Usage

If `.wiz/context/frameworks.md` specifies "Use FastAPI":

- `/wiz-prd` won't ask about framework choice → assumes FastAPI
- `/wiz-phases` plans phases with FastAPI in mind
- `/wiz-next` and language specialists recommend FastAPI patterns
- All other recommendations defer to FastAPI choice

See [README.md](../README.md#local-context-support) for detailed examples and usage.

______________________________________________________________________

## Command Workflow

### Typical Workflow

```bash
# 1. Planning Phase
/wiz-prd my-feature "Add feature description"
# Answer questions when prompted

/wiz-phases my-feature
# Review generated phases

/wiz-milestones my-feature
# Review generated milestones

# 2. Execution Phase
/wiz-next
# Executes first milestone, commits, moves to next

# Or auto-execute with gating
/wiz-auto my-feature 10
# Executes up to 10 milestones, stops for human input when needed

# 3. Review Phase
/wiz-review-milestone my-feature P01M10
# Review milestone before moving to next phase

/wiz-review-phase my-feature 1
# Review entire phase when complete

# 4. Validation
/wiz-validate-all
# Validate entire codebase before moving forward
```

### Interruption and Recovery

```bash
# Work interrupted? Resume where you left off
/wiz-resume

# Check current status
/wiz-status

# Continue execution
/wiz-next
```

______________________________________________________________________

## Command Arguments Reference

### Slug Format

- **Required**: Lowercase letters, numbers, and hyphens only
- **Not allowed**: Spaces, underscores, special characters
- **Examples**: ✅ `auth-system`, ✅ `user-profile`, ❌ `Auth System`, ❌ `user_profile`

### Milestone ID Format

- **Format**: `P##M##` (zero-padded)
- **Phase**: `P01`, `P02`, etc. (2 digits)
- **Milestone**: `M01`, `M02`, etc. (2 digits)
- **Examples**: `P01M01`, `P02M15`, `P03M42`

### Phase Number Format

- **Format**: Integer (`1`, `2`, `3`, etc.)
- **Corresponds to**: `phase1.md`, `phase2.md`, etc.

______________________________________________________________________

## Error Handling

### Common Errors

**"PRD not found"**

- Ensure PRD exists at `.wiz/<slug>/prd.md`
- Check slug spelling
- Run `/wiz-prd` first

**"No next milestone found"**

- All milestones may be complete
- Check with `/wiz-status`
- Generate more milestones if needed

**"Tests failing"**

- Fix failing tests before proceeding
- Quality gates enforce zero failures
- Run `/wiz-validate-all` to check entire codebase

**"Lint errors"**

- Fix lint errors before proceeding
- Quality gates enforce zero errors
- Run language-specific linters

### Recovery

- **Stale resume state**: Clear `.wiz/.current-milestone.json` and restart
- **Invalid state**: Check `.wiz/state.json` or regenerate phases/milestones
- **Quality gate failures**: Fix issues, then retry command

______________________________________________________________________

## Best Practices

### Planning

1. ✅ Review PRD before generating phases
1. ✅ Review phases before generating milestones
1. ✅ Adjust milestones if needed before execution

### Execution

1. ✅ Use `/wiz-status` frequently to track progress
1. ✅ Review milestones before moving to next phase
1. ✅ Fix quality issues immediately (don't accumulate debt)

### Review

1. ✅ Review milestones when phase completes
1. ✅ Use `/wiz-validate-all` before major releases
1. ✅ Address review recommendations promptly

______________________________________________________________________

## Summary

| Command | Category | Purpose | Key Feature |
|---------|----------|---------|-------------|
| `/wiz-prd` | Planning | Create PRD | Research-backed |
| `/wiz-phases` | Planning | Generate phases | Logical decomposition |
| `/wiz-milestones` | Planning | Generate milestones | ~1 hour granularity |
| `/wiz-next` | Execution | Execute milestone | Quality gates |
| `/wiz-auto` | Execution | Auto-execute | Intelligent gating |
| `/wiz-resume` | Execution | Resume work | Interruption recovery |
| `/wiz-review-milestone` | Review | Review milestone | Comprehensive audit |
| `/wiz-review-phase` | Review | Review phase | Integration check |
| `/wiz-validate-all` | Review | Validate codebase | Full health check |
| `/wiz-status` | Utility | Show progress | Progress dashboard |
| `/wiz-help` | Utility | Show help | Command reference |

For more details on specific commands, see their definitions in `.cursor/commands/`.
