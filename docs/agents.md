# Wiz Agents Documentation

Wiz uses specialized agents to handle different aspects of the planning and execution workflow. Each agent has a specific role and set of capabilities.

## Overview

Agents are specialized AI assistants that provide expertise in specific domains. They are **read-only consultants** that provide guidance and recommendations—they do not implement code themselves. The main command agents (`/wiz-next`, `/wiz-auto`) consult these specialists when needed.

## Core Agents

### wiz-planner

**Role**: Strategic planning and research specialist

**Responsibilities**:

- Generate comprehensive Product Requirements Documents (PRDs)
- Break PRDs into implementation phases
- Create detailed milestones (~1 hour each)
- Research best practices and architectural patterns
- Define acceptance criteria and success metrics

**Key Capabilities**:

- **Question Generation**: Creates 8-12 clarifying questions for PRD creation
- **Research**: Uses WebSearch and WebFetch to gather current best practices
- **Phase Decomposition**: Breaks PRDs into 3-15 logical phases (each ~3-5 days)
- **Milestone Definition**: Creates 15-40 milestones per phase with clear acceptance criteria
- **Design Guidelines**: Generates language-specific design guidelines

**When Used**:

- `/wiz-prd` - PRD generation
- `/wiz-phases` - Phase decomposition
- `/wiz-milestones` - Milestone generation

**Output Format**:

- PRD documents (`.wiz/<slug>/prd.md`)
- Phase documents (`.wiz/<slug>/phases/phase*.md`)
- Design guidelines (`.wiz/design-guidelines/<language>.md`)

**Special Features**:

- Analyzes codebase before generating questions
- **Reviews local context metadata** and loads relevant files before planning
- Researches current best practices (2024-2025)
- **Local context takes absolute precedence** over research and defaults
- Prioritizes NFRs in order: P0 (Correctness) → P1 (Tests) → P2 (Security) → P3 (Quality) → P4 (Performance)

______________________________________________________________________

### wiz-reviewer

**Role**: Quality assurance and NFR compliance auditor

**Responsibilities**:

- Review completed milestones against acceptance criteria
- Audit phases for quality and completeness
- Verify NFR compliance (security, observability, reliability, documentation)
- Generate detailed review reports

**Key Capabilities**:

- **Milestone Review**: Comprehensive audit of individual milestones
- **Phase Review**: Reviews entire completed phases
- **NFR Auditing**: Embedded NFR checker with priority order
- **Code Quality Assessment**: Evaluates code against multiple dimensions
- **Evidence Collection**: Provides file/line references for all findings

**Review Dimensions**:

- **P0: Correctness** - Does it work? Edge cases handled?
- **P1: Tests** - Tests exist? All passing? Edge cases covered?
- **P2: Security** - Input validation? No secrets? Auth/authorization?
- **P3: Quality** - Follows guidelines? Lint-clean? Documented?
- **P4: Performance** - Meets requirements? Efficient?

**When Used**:

- `/wiz-review-milestone` - Milestone quality audit
- `/wiz-review-phase` - Phase quality audit
- `/wiz-validate-all` - Full codebase validation

**Output Format**:

- Structured review reports with evidence
- Pass/Warn/Fail assessments
- Prioritized recommendations

**Embedded Skill: NFR Checker**:

- **Security Audit**: Input validation, auth/authz, secrets, dependencies
- **Observability Audit**: Metrics, logging, tracing, monitoring
- **Reliability Audit**: Timeouts, retries, failure modes
- **Documentation Audit**: User docs, developer docs, API docs

______________________________________________________________________

### wiz-milestone-analyst

**Role**: Strategic gatekeeper for auto-execution

**Responsibilities**:

- Analyze next TODO milestone before execution
- Determine if milestone requires human input
- Prevent costly mistakes from proceeding without oversight
- Provide structured decision with rationale

**Decision Types**:

- **PROCEED**: Requirements clear, low risk, obvious implementation path
- **HALT**: Ambiguities, design decisions needed, high complexity, security concerns

**Analysis Factors**:

- Requirement clarity and ambiguity
- Architectural decision requirements
- Complexity and risk assessment
- Security implications
- Multiple valid approaches
- Existing implementation checks

**When Used**:

- `/wiz-auto` - Before each milestone execution (checks NEXT milestone after current completes)

**Output Format**:

```markdown
## MILESTONE ANALYSIS
**Milestone ID:** [ID]
**Decision:** [PROCEED|HALT]

### Analysis Summary
[Summary]

### Risk Assessment
[Assessment]

### Decision Rationale
[Rationale]

### Human Input Required (if HALT)
**Category:** [Ambiguity|Design Decision|Complexity|Verification|Clarification|Security]
**Questions:** [Specific questions]
**Suggested Options:** [2-4 concrete options]
```

**Special Features**:

- Conservative approach (when in doubt, HALT)
- **Reviews local context metadata** and considers local guidance in analysis
- Grounds analysis in actual codebase context
- Provides actionable questions and options
- **Flags conflicts** between milestones and local context

______________________________________________________________________

## Language Specialists

Language specialists provide expertise for specific programming languages and frameworks. They are **advisory consultants** that guide implementation but do not write code themselves.

**⚠️ CRITICAL: Local Context Precedence**

All language specialists **MUST defer to local context** when provided:
1. **Review metadata FIRST** to identify relevant context files
2. **Read relevant files** using `wiz_load_context_file()` if they apply
3. **If local context addresses the topic** → Use that guidance, acknowledge it explicitly
4. **If local context conflicts with recommendations** → Explicitly defer to local context
5. **If no relevant local context** → Provide expert recommendation as usual

**Priority**: Local context > Specialist recommendations > General best practices

### wiz-go-specialist

**Role**: Go language consultant and advisor

**Expertise**:

- Idiomatic Go patterns (Effective Go, official style)
- Error handling best practices
- Concurrency patterns (goroutines, channels, context)
- Testing strategies (testify, mockio)
- HTTP patterns and middleware
- Package structure and organization

**Preferred Technology Stack**:

- **Concurrency**: `sync/atomic`, `xsync/v4` (lock-free patterns)
- **Dependency Injection**: `uber/fx`
- **Logging**: `uber/zap`
- **Metrics**: `prometheus/client_golang`
- **ORM**: `gorm`
- **Jobs**: `riverqueue/river`
- **Kafka**: `franz-go`
- **CLI**: `cobra`

**Testing Standards**:

- **CRITICAL**: Always use `require.*` from `testify` (never `t.Errorf` or `t.Fatalf`)
- Must have `testify` in `go.mod`
- Optional: `mockio` for mocking

**Embedded Skill: Go Quality Gates**:
Automatic quality enforcement following NFR priority order:

1. **P0: Testing Standards** - Verify testify/mockio dependencies
1. **P0: Correctness** - Run tests, all must pass
1. **P1: Coverage** - Check test coverage (≥70% threshold)
1. **P2: Security** - Run gosec security scanner
1. **P3: Quality** - Run golangci-lint or go vet
1. **P4: Performance** - Optional fuzz testing

**When Used**:

- Automatically when `.go` files are modified
- During `/wiz-next` and `/wiz-auto` execution
- Language-specific code review

______________________________________________________________________

### wiz-typescript-specialist

**Role**: TypeScript/JavaScript consultant and advisor

**Expertise**:

- TypeScript best practices and type safety
- React patterns (hooks, components, state management)
- Node.js patterns (async/await, streams, modules)
- Testing strategies (Jest, Vitest, React Testing Library)
- Modern JavaScript features (ES6+, async patterns)
- Framework guidance (Next.js, Express, NestJS)

**Preferred Technology Stack**:

- **Testing**: Jest or Vitest with React Testing Library
- **Linting**: ESLint with TypeScript plugin
- **Formatting**: Prettier
- **Type Checking**: TypeScript strict mode
- **Bundling**: Vite, Webpack, or esbuild

**Common Patterns**:

- Proper TypeScript type definitions
- React hooks best practices
- Async/await error handling
- Module organization

**When Used**:

- When `.ts`, `.tsx`, `.js`, `.jsx` files are modified
- During implementation guidance for TypeScript/JavaScript code

______________________________________________________________________

### wiz-python-specialist

**Role**: Python consultant and advisor

**Expertise**:

- Pythonic patterns and PEP 8 compliance
- Async/await patterns
- Type hints and generics
- Testing with pytest
- Framework guidance (Django, Flask, FastAPI)
- Decorators, generators, context managers

**Preferred Technology Stack**:

- **Testing**: pytest with pytest-cov
- **Linting**: ruff or flake8
- **Formatting**: black
- **Type Checking**: mypy
- **Framework**: FastAPI (preferred), Django, Flask

**Common Patterns**:

- Proper type hints
- Async/await patterns
- Error handling with exceptions
- Context managers for resource management
- Decorators for cross-cutting concerns

**When Used**:

- When `.py` files are modified
- During implementation guidance for Python code

______________________________________________________________________

### wiz-csharp-specialist

**Role**: C# and .NET consultant and advisor

**Expertise**:

- C# best practices and modern features
- ASP.NET Core patterns
- Entity Framework Core
- Dependency injection
- LINQ and async/await
- Records, pattern matching, nullable reference types

**Preferred Technology Stack**:

- **Framework**: ASP.NET Core
- **ORM**: Entity Framework Core
- **Testing**: xUnit or NUnit
- **Linting**: dotnet format, Roslyn analyzers

**Common Patterns**:

- Dependency injection with built-in DI container
- Repository pattern with EF Core
- Async/await throughout
- LINQ for data manipulation
- Minimal APIs or controllers

**When Used**:

- When `.cs` files are modified
- During implementation guidance for C# code

______________________________________________________________________

### wiz-java-specialist

**Role**: Java consultant and advisor

**Expertise**:

- Modern Java best practices (Java 17+)
- Spring Boot patterns
- Hibernate/JPA
- Testing with JUnit and Mockito
- Streams, lambdas, Optional
- Records and sealed classes

**Preferred Technology Stack**:

- **Framework**: Spring Boot
- **ORM**: Hibernate/JPA
- **Testing**: JUnit 5, Mockito
- **Build**: Maven or Gradle

**Common Patterns**:

- Spring Boot dependency injection
- Repository pattern with JPA
- Service layer architecture
- REST controllers
- Exception handling

**When Used**:

- When `.java` files are modified
- During implementation guidance for Java code

______________________________________________________________________

### wiz-docker-specialist

**Role**: Docker and containerization specialist

**Expertise**:

- Dockerfile best practices
- docker-compose configuration
- Multi-stage builds
- Security hardening
- Image optimization
- Container orchestration patterns

**Key Review Areas**:

- **Security**: Non-root users, no secrets, minimal packages
- **Performance**: Multi-stage builds, efficient caching, small images
- **Best Practices**: Specific tags, health checks, resource limits
- **Configuration**: Proper .dockerignore, environment variables

**Common Recommendations**:

- Use specific image tags (not `latest`)
- Multi-stage builds for compiled languages
- Non-root users for security
- Efficient layer caching
- Health checks in docker-compose
- Resource limits

**When Used**:

- When `Dockerfile` or `docker-compose.yml` files are modified
- During containerization guidance

______________________________________________________________________

## Local Context Integration

All agents support **local context** from `.wiz/context/**/*.md` with **absolute precedence**.

### How Agents Use Local Context

#### wiz-planner

- Reviews local context metadata before PRD/phase/milestone generation
- Loads relevant context files based on metadata (tags, languages, applies_to)
- **Local context takes precedence** over research and best practices
- Example: If context specifies "Use FastAPI", planner uses FastAPI without researching alternatives

#### wiz-milestone-analyst

- Reviews local context metadata during milestone analysis
- Checks if milestone requirements align with local context patterns
- Flags conflicts between milestones and local context (may require human clarification)
- Considers local context when making PROCEED/HALT decisions

#### Language Specialists

All language specialists (`wiz-go-specialist`, `wiz-typescript-specialist`, `wiz-python-specialist`, `wiz-csharp-specialist`, `wiz-java-specialist`, `wiz-docker-specialist`):

- **Review metadata FIRST** when command agent provides it
- **Read relevant files** using `wiz_load_context_file()` based on:
  - If `languages` is empty → applies to all languages
  - If `languages` includes their language → relevant
  - If `tags` match the topic → relevant
- **Explicitly defer** to local context when it conflicts with their recommendations
- **Acknowledge** when recommendations align with local context

### Example Response Pattern

When local context exists and applies:

```markdown
## Recommendation

I reviewed available local context and found `frameworks.md` specifies using 
[X framework] for this scenario. I recommend following that guidance.

[Recommendation based on local context]

## Rationale

[Why local context's approach fits, or acknowledge if normally recommending something else]
```

### Context File Relevance

Agents determine relevance based on:
- **Empty arrays**: If `languages` or `applies_to` is empty, applies to everything
- **Language matching**: If `languages` includes detected/relevant language
- **Tag matching**: If `tags` match the topic (e.g., "frameworks", "patterns")
- **Description relevance**: If description suggests applicability

### Benefits

- **Token efficient**: Only loads relevant files
- **Project-aware**: Agents respect project-specific decisions
- **Consistent**: Same context used across planning and execution
- **Flexible**: Users organize context files however they want

See [README.md](../README.md#local-context-support) for context file examples and detailed usage.

______________________________________________________________________

## Agent Interaction Patterns

### How Agents Are Invoked

1. **Direct Invocation**: Commands explicitly reference agents

   - `/wiz-prd` → `wiz-planner` for PRD generation
   - `/wiz-review-milestone` → `wiz-reviewer` for quality audit

1. **Automatic Detection**: Language specialists auto-detect based on file changes

   - `.go` files → `wiz-go-specialist`
   - `.ts`/`.tsx` files → `wiz-typescript-specialist`
   - `.py` files → `wiz-python-specialist`
   - etc.

1. **Consultation Pattern**: Main command agents consult specialists for guidance

   - `/wiz-next` consults language specialists before implementing
   - `/wiz-auto` consults `wiz-milestone-analyst` before each milestone

### Agent Limitations

All agents are **read-only**:

- ✅ Can read files, search code, research documentation
- ✅ Can provide guidance, recommendations, examples
- ❌ Cannot write files or modify code
- ❌ Cannot execute commands (except for read-only operations)

**File Writing Pattern**:
When agents need to generate content:

1. Agent generates content (returns in code blocks)
1. Main command agent writes files using Write/Edit tools
1. This ensures reliable file operations

______________________________________________________________________

## Quality Standards

All agents enforce strict quality standards:

### NFR Priority Order

1. **P0: Correctness** - Code must work, handle edge cases
1. **P1: Regression Prevention** - Tests must exist and pass (zero failures, zero skips)
1. **P2: Security** - Input validation, no secrets, secure practices
1. **P3: Quality** - Lint-clean, documented, maintainable
1. **P4: Performance** - Meets performance requirements

### Zero Tolerance Policy

- ❌ **No failing tests** - Ever
- ❌ **No skipped tests** - Ever
- ❌ **No lint errors** - Ever
- ✅ **Entire codebase healthy** - Not just new code

______________________________________________________________________

## Summary

| Agent | Role | When Used | Key Feature |
|-------|------|-----------|-------------|
| `wiz-planner` | Strategic planning | PRD, phases, milestones | Research-backed planning |
| `wiz-reviewer` | Quality assurance | Reviews, validation | NFR compliance checking |
| `wiz-milestone-analyst` | Gatekeeper | Auto-execution | PROCEED/HALT decisions |
| `wiz-go-specialist` | Go expertise | Go code changes | Quality gates + preferred stack |
| `wiz-typescript-specialist` | TS/JS expertise | TS/JS code changes | Modern patterns guidance |
| `wiz-python-specialist` | Python expertise | Python code changes | Pythonic patterns |
| `wiz-csharp-specialist` | C# expertise | C# code changes | .NET best practices |
| `wiz-java-specialist` | Java expertise | Java code changes | Spring Boot patterns |
| `wiz-docker-specialist` | Docker expertise | Dockerfile changes | Security + optimization |

For more details on specific agents, see their definitions in `.cursor/agents/`.
