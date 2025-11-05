# Wiz Integration Testing Plan

## Overview

This document outlines the integration testing strategy for Wiz's core commands, focusing on end-to-end validation of the planning and execution workflows using prompt/context testing frameworks.

## Testing Goals

Integration test the following commands:

**Planning Commands:**

- `/wiz-prd` - Generate Product Requirements Document
- `/wiz-phases` - Break PRD into implementation phases
- `/wiz-milestones` - Create detailed milestones for phases

**Execution Commands:**

- `/wiz-next` - Execute next TODO milestone
- `/wiz-auto` - Automatically execute multiple milestones

## Testing Framework

We will use **Promptfoo** - an open-source prompt/context testing framework (not bats) to test these commands with realistic AI interactions.

### Promptfoo ⭐ (Recommended)

[Promptfoo](https://github.com/promptfoo/promptfoo) is the recommended framework for integration testing:

**Why Promptfoo:**

- ✅ **Open source** - MIT licensed, 8.9k+ stars, actively maintained
- ✅ **Developer-first** - Fast, with features like live reload and caching
- ✅ **Private** - LLM evals run 100% locally - prompts never leave your machine
- ✅ **Flexible** - Works with any LLM API or programming language
- ✅ **Battle-tested** - Powers LLM apps serving 10M+ users in production
- ✅ **CI/CD integration** - Simple declarative configs with command line and CI/CD integration
- ✅ **Comprehensive** - Test prompts, agents, and RAGs with automated evaluations
- ✅ **Security** - Includes red teaming and vulnerability scanning for LLMs
- ✅ **Model comparison** - Compare GPT, Claude, Gemini, Llama, and more side-by-side

**Key Features:**

- Automated prompt evaluations
- Test suites with multiple scenarios
- Model comparison and benchmarking
- CI/CD integration
- Local execution (privacy-focused)
- Red teaming and vulnerability scanning
- Web viewer and command line interface

**Installation:**

```bash
# Install and initialize project
npx promptfoo@latest init

# Run evaluations
npx promptfoo eval
```

**Alternative Open Source Options:**

- **ChainForge** - Visual toolkit with graphical interface (https://github.com/ianarawjo/ChainForge)
- **PromptTools** - Suite of tools for testing prompts (https://github.com/hegelai/prompttools)
- **Promptimize** - Systematic testing at scale (https://github.com/preset-io/promptimize)

**Requirements**: Framework must be **open source** to ensure:

- No vendor lock-in
- Full control over test infrastructure
- Ability to customize and extend
- No licensing costs or restrictions

## Test Scenarios

### 1. Planning Workflow Integration Tests

#### 1.1 `/wiz-prd` Integration Test

**Goal**: Test complete PRD generation workflow with context integration

**Test Steps**:

1. Set up test codebase (language detection, existing structure)
1. Create test context files (`.wiz/context/**/*.md`) with various metadata
1. Execute `/wiz-prd <slug> "<idea>"` command
1. Verify outputs:
   - `.wiz/<slug>/prd.md` exists and contains expected sections
   - `.wiz/<slug>/intake/questions.json` contains context-aware questions
   - Questions skip obvious things (detected language, existing patterns)
   - PRD references local context when available
   - Context metadata is loaded before question generation

**Context Scenarios**:

- Empty context directory (no local context)
- Single context file with framework specification
- Multiple context files with different scopes (languages, applies_to)
- Context files with empty arrays (applies to all)
- Nested context files (`.wiz/context/go/patterns.md`)

**Validation**:

- PRD structure is complete (overview, requirements, architecture, success criteria)
- Local context takes precedence over research/defaults
- Questions are context-aware (don't ask about detected language)
- Context metadata correctly included in prompts

#### 1.2 `/wiz-phases` Integration Test

**Goal**: Test phase generation with PRD input and context integration

**Test Steps**:

1. Use PRD from 1.1 test (or create test PRD fixture)
1. Set up context files relevant to phase planning
1. Execute `/wiz-phases <slug>` command
1. Verify outputs:
   - Phase files created (`.wiz/<slug>/phases/phase1.md`, etc.)
   - Phases reference context-specified frameworks/patterns
   - Design guidelines generated (`.wiz/design-guidelines/<language>.md`)
   - Phase structure is logical (3-15 phases, ~3-5 days each)
   - Context metadata loaded before phase generation

**Context Scenarios**:

- Context specifies technology stack → phases use it
- Context specifies architectural patterns → phases follow patterns
- Context conflicts with PRD → context takes precedence
- Multiple context files → correct filtering by languages/applies_to

**Validation**:

- Phases break down PRD logically
- Phases respect local context specifications
- Design guidelines align with context
- Phase dependencies are clear

#### 1.3 `/wiz-milestones` Integration Test

**Goal**: Test milestone generation with phases input and context integration

**Test Steps**:

1. Use phases from 1.2 test (or create test phase fixtures)
1. Set up context files relevant to milestone planning
1. Execute `/wiz-milestones <slug>` command
1. Verify outputs:
   - Milestones added to phase files (15-40 per phase)
   - Milestones are ~1 hour each (30 min - 2 hours acceptable)
   - Each milestone has clear acceptance criteria
   - NFR requirements included (P0-P4 priority order)
   - `.wiz/<slug>/IMPLEMENTATION_GUIDE.md` created
   - Context metadata loaded before milestone generation

**Context Scenarios**:

- Context specifies testing frameworks → milestones include tests
- Context specifies patterns → milestones follow patterns
- Context specifies tools → milestones use those tools

**Validation**:

- Milestones are appropriately sized (~1 hour)
- Acceptance criteria are testable
- NFR priorities correct (P0 → P1 → P2 → P3 → P4)
- Milestones respect local context specifications

### 2. Execution Workflow Integration Tests

#### 2.1 `/wiz-next` Integration Test

**Goal**: Test milestone execution with context integration and quality gates

**Test Steps**:

1. Use milestones from 1.3 test (or create test milestone fixtures)
1. Set up context files relevant to implementation
1. Execute `/wiz-next [slug] [count]` command
1. Verify execution:
   - Next TODO milestone identified correctly
   - Context metadata loaded FIRST (before design guidelines)
   - Relevant context files loaded based on metadata
   - Implementation follows context specifications
   - Code written according to milestone requirements
   - Tests written and passing
   - Linters pass (zero errors)
   - Commit created with proper format: `feat(P##M##): <Title>`
   - Milestone status updated to COMPLETE

**Context Scenarios**:

- Context specifies framework → implementation uses it
- Context specifies patterns → implementation follows patterns
- Context conflicts with specialist → context takes precedence
- Empty context → falls back to design guidelines/specialist

**Quality Gates**:

- ✅ All tests pass (no failures, no skips)
- ✅ All linters pass (zero errors)
- ✅ Entire codebase healthy (not just new code)
- ✅ Language specialist approval (if consulted)

**Validation**:

- Context loaded before design guidelines
- Local context takes precedence over specialist recommendations
- Implementation matches milestone acceptance criteria
- Quality gates enforced correctly
- Commit format correct

#### 2.2 `/wiz-auto` Integration Test

**Goal**: Test automated milestone execution loop with context integration

**Test Steps**:

1. Use milestones from 1.3 test (or create test milestone fixtures)
1. Set up context files relevant to implementation
1. Execute `/wiz-auto [slug] [count]` command
1. Verify execution:
   - Context metadata loaded ONCE before loop starts
   - Multiple milestones executed in sequence
   - Each milestone follows same quality gates as `/wiz-next`
   - Loop stops on error or when count reached
   - Progress tracked correctly
   - All milestones committed properly

**Context Scenarios**:

- Context loaded once and reused for all milestones
- Context consistency across multiple milestone executions
- Context applied correctly to different milestone types

**Validation**:

- Context loaded efficiently (once, not per milestone)
- Multiple milestones execute successfully
- Quality gates enforced for each milestone
- Progress tracking accurate

### 3. Full Workflow Integration Tests

#### 3.1 Complete Planning → Execution Workflow

**Goal**: Test complete workflow from PRD to milestone execution

**Test Steps**:

1. Execute `/wiz-prd` with test idea and context
1. Execute `/wiz-phases` using generated PRD
1. Execute `/wiz-milestones` using generated phases
1. Execute `/wiz-next` to complete first milestone
1. Execute `/wiz-auto` to complete multiple milestones
1. Verify:
   - Context flows through all stages
   - Context precedence maintained throughout
   - Outputs from each stage feed into next stage correctly
   - Workflow produces coherent, consistent results

**Context Flow**:

- Context specified in planning → reflected in PRD
- Context used in phases → reflected in phase structure
- Context used in milestones → reflected in milestone tasks
- Context used in execution → reflected in implementation

**Validation**:

- Complete workflow executes successfully
- Context consistency maintained across all stages
- Outputs are coherent and build on each other

#### 3.2 Context Precedence Validation

**Goal**: Verify local context truly takes precedence throughout workflow

**Test Scenarios**:

1. Context specifies framework → PRD uses it (not researched alternative)
1. Context specifies pattern → Phases use it
1. Context specifies approach → Milestones use it
1. Context conflicts with specialist → Specialist defers to context
1. Multiple context files → Correct precedence order

**Validation**:

- Context takes precedence over research in `/wiz-prd`
- Context takes precedence over defaults in `/wiz-phases`
- Context takes precedence over defaults in `/wiz-milestones`
- Context takes precedence over specialist in `/wiz-next` and `/wiz-auto`

## Test Infrastructure

### Test Fixtures

**Context Files** (`.wiz/context/**/*.md`):

- `frameworks.md` - Framework specifications
- `technologies.md` - Technology stack choices
- `patterns.md` - Architectural patterns
- `go/patterns.md` - Language-specific patterns
- `testing.md` - Testing framework specifications

**Workflow Fixtures**:

- Test PRDs (`.wiz/<slug>/prd.md`)
- Test phases (`.wiz/<slug>/phases/phase*.md`)
- Test milestones (embedded in phase files)
- Test state files (`.wiz/state.json`)

**Codebase Fixtures**:

- Minimal test repositories (Go, TypeScript, Python)
- Existing code patterns to detect
- Test infrastructure to verify

### Test Configuration

**Prompt Testing Framework Setup**:

- Install Promptfoo (`npx promptfoo@latest init`)
- Configure test suites for each command
- Set up evaluation metrics and assertions
- Create test data fixtures

**Directory Structure**:

```
tests/
├── fixtures/
│   ├── context/              # Test context files
│   │   ├── frameworks.md
│   │   ├── technologies.md
│   │   └── go/
│   │       └── patterns.md
│   ├── workflows/            # Test PRDs, phases, milestones
│   │   ├── test-prd.md
│   │   └── test-phases/
│   └── codebases/            # Minimal test repositories
│       ├── go-project/
│       ├── ts-project/
│       └── py-project/
├── prompts/                  # Promptfoo configuration
│   ├── promptfoo.yaml        # Main Promptfoo config
│   └── test-suites/          # Test suite configurations
│       ├── wiz-prd.yaml
│       ├── wiz-phases.yaml
│       ├── wiz-milestones.yaml
│       ├── wiz-next.yaml
│       └── wiz-auto.yaml
└── integration/
    ├── test-wiz-prd.sh       # Integration test scripts
    ├── test-wiz-phases.sh
    ├── test-wiz-milestones.sh
    ├── test-wiz-next.sh
    ├── test-wiz-auto.sh
    └── test-full-workflow.sh
```

## Implementation Plan

### Phase 1: Framework Setup (Week 1)

**Tasks**:

1. Install Promptfoo (`npx promptfoo@latest init`)
1. Configure Promptfoo for Wiz command testing
1. Set up test directory structure
1. Create test fixtures (context files, codebases, workflows)
1. Extract prompts from command files for testing
1. Create Promptfoo test suites for each command

**Deliverables**:

- Prompt testing framework installed and configured
- Test directory structure created
- Basic test fixtures created

### Phase 2: Planning Command Tests (Week 2)

**Tasks**:

1. Create `/wiz-prd` integration test suite
1. Create `/wiz-phases` integration test suite
1. Create `/wiz-milestones` integration test suite
1. Test context integration for each command
1. Test context precedence scenarios

**Deliverables**:

- Integration test suites for all planning commands
- Context integration tests passing
- Context precedence validation working

### Phase 3: Execution Command Tests (Week 2-3)

**Tasks**:

1. Create `/wiz-next` integration test suite
1. Create `/wiz-auto` integration test suite
1. Test quality gates enforcement
1. Test context integration during execution
1. Test commit creation and status updates

**Deliverables**:

- Integration test suites for execution commands
- Quality gate tests passing
- Context integration tests passing

### Phase 4: Full Workflow Tests (Week 3)

**Tasks**:

1. Create full workflow integration test
1. Test context flow through all stages
1. Test context precedence end-to-end
1. Validate workflow coherence

**Deliverables**:

- Full workflow integration test
- End-to-end context precedence validation
- Workflow coherence tests passing

### Phase 5: CI/CD Integration (Week 3-4)

**Tasks**:

1. Integrate tests into CI/CD pipeline
1. Set up test reporting and monitoring
1. Configure test execution in GitHub Actions
1. Add Makefile targets for test execution

**Deliverables**:

- CI/CD integration complete
- Test reporting configured
- Makefile targets added

## Makefile Targets

```makefile
# Integration testing targets
test-integration: test-prd test-phases test-milestones test-next test-auto test-workflow
test-prd: ## Run /wiz-prd integration tests
test-phases: ## Run /wiz-phases integration tests
test-milestones: ## Run /wiz-milestones integration tests
test-next: ## Run /wiz-next integration tests
test-auto: ## Run /wiz-auto integration tests
test-workflow: ## Run full workflow integration tests
test-prompts: ## Run prompt testing framework tests
```

## CI/CD Integration

### GitHub Actions Workflow

```yaml
name: Integration Tests

on: [push, pull_request]

jobs:
  integration-tests:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Set up Promptfoo
        run: |
          npm install -g promptfoo
          promptfoo init
      - name: Run /wiz-prd tests
        run: make test-prd
      - name: Run /wiz-phases tests
        run: make test-phases
      - name: Run /wiz-milestones tests
        run: make test-milestones
      - name: Run /wiz-next tests
        run: make test-next
      - name: Run /wiz-auto tests
        run: make test-auto
      - name: Run full workflow tests
        run: make test-workflow
```

## Success Criteria

### Test Coverage

- ✅ All 5 core commands have integration test suites
- ✅ Context integration tested for each command
- ✅ Context precedence validated throughout workflow
- ✅ Quality gates tested for execution commands
- ✅ Full workflow tested end-to-end

### Quality Metrics

- **Reliability**: Tests produce consistent results
- **Completeness**: All major scenarios covered
- **Maintainability**: Tests easy to update when commands change
- **Speed**: Full test suite runs in reasonable time (< 30 minutes)

## Challenges and Solutions

### Challenge 1: AI Non-Determinism

**Problem**: AI agents produce different outputs for same input

**Solution**:

- Use prompt testing framework with evaluation metrics
- Test for structure and key content, not exact text
- Use schema validation for outputs (JSON, markdown structure)
- Test prompts separately from execution
- Focus on context integration, not exact AI output

### Challenge 2: Test Execution Cost

**Problem**: Running tests with real LLM calls can be expensive

**Solution**:

- Use framework's mocking capabilities when possible
- Cache test results where appropriate
- Use cheaper models for integration tests
- Run expensive tests on schedule, not every commit

### Challenge 3: Context File Management

**Problem**: Need various context file combinations for testing

**Solution**:

- Create comprehensive test fixtures
- Use test framework's data-driven testing
- Automate context file setup/teardown
- Test context filtering logic separately

## References

- [Promptfoo Documentation](https://github.com/promptfoo/promptfoo) - Open source (MIT License) ⭐ Recommended
- [Promptfoo Getting Started](https://www.promptfoo.dev/docs/getting-started/)
- [Promptfoo CI/CD Integration](https://www.promptfoo.dev/docs/configuration/ci-cd/)
- [Ultimate Guide to Automated Prompt Testing](https://www.newline.co/@zaoyang/ultimate-guide-to-automated-prompt-testing--44e97593)
- [ChainForge Documentation](https://github.com/ianarawjo/ChainForge) - Alternative open source option
- [PromptTools Documentation](https://github.com/hegelai/prompttools) - Alternative open source option

## Next Steps

1. **Set Up Promptfoo** - Install and configure Promptfoo for integration testing
1. **Set Up Infrastructure** - Install framework and create test structure
1. **Create Test Fixtures** - Build context files, codebases, and workflow fixtures
1. **Start with `/wiz-prd`** - Create first integration test suite
1. **Iterate** - Add tests for remaining commands incrementally
