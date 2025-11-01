# Wiz Planner for Cursor

**Wiz** is an intelligent project planning and execution system that works seamlessly with Cursor to help you break down complex features into manageable milestones and execute them systematically.

## Installing

Install the latest stable release:

```bash
curl -fsSL https://raw.githubusercontent.com/NSXBet/wiz-cursor/refs/heads/main/install.sh | bash
```

**Install a specific version:**

```bash
curl -fsSL https://raw.githubusercontent.com/NSXBet/wiz-cursor/refs/heads/main/install.sh | bash -- --version 0.1.2
```

**Install latest from main branch (development version):**

```bash
curl -fsSL https://raw.githubusercontent.com/NSXBet/wiz-cursor/refs/heads/main/install.sh | bash -- --version HEAD
```

For further installation instructions, see [Installation Instructions](#installation-instructions).

### Updating Wiz

To update Wiz, simply run the installation command again. The script automatically detects existing installations and updates them:

**Update to latest stable release:**

```bash
curl -fsSL https://raw.githubusercontent.com/NSXBet/wiz-cursor/refs/heads/main/install.sh | bash
```

**Update to a specific version:**

```bash
curl -fsSL https://raw.githubusercontent.com/NSXBet/wiz-cursor/refs/heads/main/install.sh | bash -- --version 0.1.2
```

**Update to latest development version:**

```bash
curl -fsSL https://raw.githubusercontent.com/NSXBet/wiz-cursor/refs/heads/main/install.sh | bash -- --version HEAD
```

> **Note**: Updates work the same as fresh installs - the script automatically removes old Wiz files and installs the specified version without asking for confirmation.

## Using Wiz to create a new project or Feature

Wiz helps you plan and structure your projects through a three-step process: creating a Product Requirements Document (PRD), breaking it into phases, and generating detailed milestones.

### Step 1: Create a Product Requirements Document (PRD)

Start by creating a comprehensive PRD for your feature or project:

```bash
/wiz-prd <slug> "<idea>"
```

**Example:**

```bash
/wiz-prd auth-system "Add user authentication with JWT tokens"
```

**What happens:**

1. Wiz analyzes your codebase to understand your project structure
1. Wiz asks 8-12 clarifying questions about your idea
1. You answer the questions (Wiz waits for your responses)
1. Wiz researches best practices and current standards
1. Wiz generates a comprehensive PRD document

**Output:** `.wiz/<slug>/prd.md` - A detailed PRD with overview, requirements, architecture, success criteria, risks, and implementation notes.

### Step 2: Generate Implementation Phases

Break your PRD into logical implementation phases:

```bash
/wiz-phases <slug>
```

**Example:**

```bash
/wiz-phases auth-system
```

**What happens:**

1. Wiz reads your PRD
1. Wiz breaks it into 3-15 logical phases (each ~3-5 days of work)
1. Each phase has clear goals, dependencies, and acceptance criteria
1. Wiz generates design guidelines for your project's languages

**Output:** `.wiz/<slug>/phases/phase1.md`, `phase2.md`, etc. - Phase documents with goals and dependencies.

### Step 3: Generate Detailed Milestones

Create ~1-hour milestones for each phase:

```bash
/wiz-milestones <slug>
```

**Example:**

```bash
/wiz-milestones auth-system
```

**What happens:**

1. Wiz reads all phase documents
1. Wiz creates 15-40 milestones per phase (each ~1 hour)
1. Each milestone has specific, testable acceptance criteria
1. Milestones include NFR requirements (P0-P4 priority order)

**Output:** Updated phase files with milestones added, plus `.wiz/<slug>/IMPLEMENTATION_GUIDE.md`.

**Example milestone structure:**

```markdown
### P01M01: Create User Model

**Status:** 🚧 TODO
**ID:** P01M01

**Goal**
Create the User model struct with required fields.

**Acceptance Criteria**
- [ ] User struct defined with email, password hash, and timestamps
- [ ] Database migration created
- [ ] Unit tests written and passing
- [ ] Documentation updated
```

### Your First Project

## Iterating on your milestones

Once you have milestones, you can execute them systematically using `/wiz-next` and `/wiz-auto`.

### Using `/wiz-next`

Execute the next TODO milestone one at a time:

```bash
/wiz-next [slug] [count]
```

**What happens:**

1. Wiz finds the next TODO milestone
1. Wiz loads context (phase, milestone, design guidelines)
1. Wiz consults language specialists for guidance
1. Wiz implements the milestone (code, tests, documentation)
1. Wiz runs quality checks:
   - ✅ All tests pass (zero failures, zero skips)
   - ✅ All linters pass (zero errors)
   - ✅ Entire codebase healthy (not just new code)
1. Wiz creates a properly formatted commit
1. Wiz marks milestone as COMPLETE

**Example:**

```bash
/wiz-next                # Execute one milestone
/wiz-next auth-system    # Execute one milestone for specific project
/wiz-next auth-system 3  # Execute 3 milestones
```

**Commit format:**

```
feat(P01M01): Create User Model

Completed milestone P01M01.

🤖 Generated with Wiz Planner

Co-Authored-By: Wiz <wiz@flutterbrazil.com>
```

### Using `/wiz-auto`

Automatically execute multiple milestones with intelligent gating:

```bash
/wiz-auto [slug] [max-milestones]
```

**What happens:**

1. Wiz finds the next TODO milestone
1. **Before executing**, `wiz-milestone-analyst` evaluates the NEXT milestone
1. **If PROCEED**: Requirements clear, low risk → execute milestone
1. **If HALT**: Ambiguities detected → present questions to you and wait for input
1. Repeat until no more milestones or max reached

**Gating logic:**

- **PROCEED**: Clear requirements, obvious implementation path, low risk
- **HALT**: Ambiguities, design decisions needed, high complexity, security concerns

**Example:**

```bash
/wiz-auto                # Auto-execute until done or halted
/wiz-auto auth-system    # Auto-execute for specific project
/wiz-auto auth-system 10 # Auto-execute up to 10 milestones
```

**Why use `/wiz-auto`?**

- Perfect for batch implementation with safety checks
- Automatically stops when human input is needed
- Saves time by executing straightforward milestones automatically
- Conservative approach prevents costly mistakes

### Resuming interrupted work

If work is interrupted, resume where you left off:

```bash
/wiz-resume
```

This command:

- Loads your resume state
- Shows milestone details and elapsed time
- Lets you continue, skip, or cancel

## Installation Instructions

There are several ways to install Wiz in your project for Cursor:

### Prerequisites

- **Cursor 2.0+** - The latest version of Cursor IDE
- **Composer1** - We recommend using Composer1 (not Composer2) for the best experience with Wiz commands
- A project repository (Git-based)

### Method 1: Quick Install Script (Recommended)

**Install latest stable release:**

```bash
curl -fsSL https://raw.githubusercontent.com/NSXBet/wiz-cursor/refs/heads/main/install.sh | bash
```

**Install a specific version:**

```bash
curl -fsSL https://raw.githubusercontent.com/NSXBet/wiz-cursor/refs/heads/main/install.sh | bash -- --version 0.1.2
```

**Install latest from main branch (development):**

```bash
curl -fsSL https://raw.githubusercontent.com/NSXBet/wiz-cursor/refs/heads/main/install.sh | bash -- --version HEAD
```

**Download and review the script first** (recommended for security):

```bash
# Download the script
curl -fsSL https://raw.githubusercontent.com/NSXBet/wiz-cursor/refs/heads/main/install.sh -o install.sh
# Review the script
cat install.sh
# Then run it (with optional version)
bash install.sh                    # Latest stable release
bash install.sh --version 0.1.2    # Specific version
bash install.sh --version HEAD     # Latest from main branch
```

**Using GitHub CLI (`gh`)** (works for both public and private repos):

```bash
# Latest stable release
gh api "repos/NSXBet/wiz-cursor/contents/install.sh?ref=main" --jq '.content' | base64 -d | bash

# Specific version
gh api "repos/NSXBet/wiz-cursor/contents/install.sh?ref=main" --jq '.content' | base64 -d | bash -- --version 0.1.2
```

> **Note**: GitHub CLI (`gh`) requires authentication. Install from [cli.github.com](https://cli.github.com/)

**Version Options:**

- **No version specified**: Automatically installs the latest stable release from GitHub
- **`--version 0.1.2`**: Installs a specific release version (replace with desired version)
- **`--version HEAD`**: Installs the latest code from the main branch (development version)

The install script automatically tries multiple installation methods:

1. **Git sparse checkout** (most efficient, works for public/private repos with git access)
1. **GitHub tarball download** (fallback for public repos, tries multiple URL formats)

The script will:

- Automatically detect the latest stable release if no version is specified
- Try multiple URLs and methods automatically
- Download the `.cursor` directory from the repository
- Place it in your current directory
- Automatically update existing installations (removes old Wiz files and installs new version)
- Clean up temporary files automatically
- Provide helpful error messages if all methods fail

### Method 2: Manual Installation with Git Sparse Checkout

Clone just the `.cursor` directory using sparse checkout:

```bash
# Clone just the .cursor directory using sparse checkout
PROJECT_DIR=$(pwd)
git clone --depth 1 --branch main --filter=blob:none --sparse https://github.com/NSXBet/wiz-cursor.git /tmp/wiz-install
cd /tmp/wiz-install
git sparse-checkout init --cone
git sparse-checkout set .cursor
cp -r .cursor "$PROJECT_DIR"
cd "$PROJECT_DIR"
rm -rf /tmp/wiz-install
```

### Method 3: Full Repository Clone

If you prefer to clone the entire repository:

```bash
# Clone the repository
git clone https://github.com/NSXBet/wiz-cursor.git
cd wiz-cursor

# Copy .cursor to your project
cp -r .cursor /path/to/your/project/
```

## Agents

Wiz uses specialized agents for different tasks. Each agent is a read-only consultant that provides guidance and recommendations—they do not implement code themselves.

**Core Agents:**

- **wiz-planner**: Strategic planning and research specialist - generates PRDs, phases, and milestones with research-backed recommendations
- **wiz-reviewer**: Quality assurance and NFR compliance auditor - reviews milestones and phases for quality and completeness
- **wiz-milestone-analyst**: Strategic gatekeeper for auto-execution - determines when milestones need human input vs. can proceed automatically

**Language Specialists:**

- **wiz-go-specialist**: Go language consultant for Effective Go patterns, testing, and preferred stack guidance
- **wiz-typescript-specialist**: TypeScript/JavaScript consultant for React, Node.js, and modern patterns
- **wiz-python-specialist**: Python consultant for Pythonic patterns, pytest, and framework guidance
- **wiz-csharp-specialist**: C# and .NET consultant for ASP.NET Core and Entity Framework patterns
- **wiz-java-specialist**: Java consultant for Spring Boot, Hibernate/JPA, and modern Java patterns
- **wiz-docker-specialist**: Docker specialist for Dockerfile best practices, security, and optimization

For detailed documentation on each agent, see [docs/agents.md](./docs/agents.md).

## Commands

**Planning Commands:**

- `/wiz-prd <slug> "<idea>"` - Generate Product Requirements Document from an idea through guided Q&A
- `/wiz-phases <slug>` - Break PRD into logical implementation phases (~3-5 days each)
- `/wiz-milestones <slug>` - Generate detailed ~1-hour milestones for all phases

**Execution Commands:**

- `/wiz-next [slug] [count]` - Execute the next TODO milestone with quality gates and automatic commits
- `/wiz-auto [slug] [max-milestones]` - Auto-execute milestones with intelligent gating (stops for human input when needed)
- `/wiz-resume` - Resume interrupted milestone work from where you left off

**Review Commands:**

- `/wiz-review-milestone <slug> <id>` - Comprehensive quality audit of a completed milestone
- `/wiz-review-phase <slug> <n>` - Review an entire completed phase for integration and quality
- `/wiz-validate-all` - Validate entire codebase for tests, linting, security, and quality

**Utility Commands:**

- `/wiz-status` - Display project progress dashboard with milestone statistics
- `/wiz-help [command]` - Show help for Wiz Planner commands

For detailed documentation on each command, see [docs/commands.md](./docs/commands.md).

## Best Practices

### Using Composer1

We strongly recommend using **Composer1** (not Composer2) with Cursor 2.0+ for the best Wiz experience. Composer1 provides:

- Better context awareness for Wiz commands
- More reliable agent invocation
- Improved file writing capabilities

To switch to Composer1 in Cursor:

1. Open Cursor Settings
1. Search for "Composer"
1. Select "Composer1" as your composer mode

### How to Best Use Wiz

1. **Start Small**: Begin with a simple feature to learn the workflow before tackling complex projects
1. **Review PRDs**: Always review the generated PRD before proceeding to phases - refine if needed
1. **Check Status Frequently**: Use `/wiz-status` to track progress and identify bottlenecks
1. **Review Milestones**: Review completed milestones before moving to the next phase to catch issues early
1. **Quality First**: Wiz enforces quality gates - fix issues as they arise, don't accumulate technical debt
1. **Use `/wiz-auto` Wisely**: Great for batch work, but review milestones when the analyst halts for input
1. **Iterate on Plans**: Don't hesitate to regenerate phases or milestones if the plan doesn't match your needs
1. **Leverage Language Specialists**: They provide expert guidance automatically - pay attention to their recommendations

### Quality Standards

Wiz enforces strict quality standards with zero tolerance:

- ✅ **P0: Correctness** - Code must work, handle edge cases
- ✅ **P1: Tests** - All tests must pass (zero failures, zero skips)
- ✅ **P2: Security** - Input validation, no secrets, secure practices
- ✅ **P3: Quality** - Lint-clean, documented, maintainable
- ✅ **P4: Performance** - Meets performance requirements

**Zero tolerance policy**: No failing tests, no lint errors, no skipped tests. The entire codebase must be healthy, not just new code.

## 📁 Project Structure

Wiz creates a `.wiz/` directory in your project root:

```
.wiz/
├── <slug>/
│   ├── prd.md                 # Product Requirements Document
│   ├── intake/
│   │   ├── questions.json     # Generated questions
│   │   ├── answers.json       # Your answers
│   │   └── qa.md              # Q&A summary
│   └── phases/
│       ├── phase1.md          # Phase 1 with milestones
│       ├── phase2.md          # Phase 2 with milestones
│       └── ...
├── state.json                 # Current project state
└── .current-milestone.json   # Resume state (if interrupted)
```

## 🐛 Troubleshooting

### Command Not Found

- Ensure `.cursor/` directory is in your project root
- Verify Cursor version is 2.0+
- Try restarting Cursor

### Quality Gate Failures

- Review the error messages
- Fix failing tests first (P0)
- Address lint errors (P3)
- Run `/wiz-validate-all` to check entire codebase

### Resume State Issues

- Clear stale resume state: `rm .wiz/.current-milestone.json`
- Run `/wiz-status` to check current state
- Use `/wiz-resume` to continue interrupted work

## 📚 Documentation

- **[Commands Documentation](./docs/commands.md)** - Detailed command reference
- **[Agents Documentation](./docs/agents.md)** - Agent capabilities and roles

## Contributing

Wiz is designed to be extensible and welcomes contributions! Here's how you can help:

### Adding New Commands

1. Create a new command file in `.cursor/commands/`
1. Follow the existing command pattern with YAML frontmatter
1. Include comprehensive documentation and examples
1. Test your command thoroughly

### Adding New Agents

1. Create a new agent file in `.cursor/agents/`
1. Define the agent's role, responsibilities, and capabilities
1. Document when and how the agent is used
1. Update `docs/agents.md` with agent documentation

### Reporting Issues

Found a bug or have a feature request? Please open an issue on GitHub with:

- Clear description of the problem or feature
- Steps to reproduce (for bugs)
- Expected vs. actual behavior

### Improving Documentation

Documentation improvements are always welcome! Whether it's:

- Fixing typos or clarifying explanations
- Adding examples or use cases
- Improving code comments

### Code Style

- Follow existing patterns and conventions
- Ensure all tests pass
- Update documentation when adding features
- Keep commits clear and focused

For more details, see the existing command and agent files as examples.

## License

This project is licensed under the MIT License. See the [LICENSE.md](LICENSE.md) file for details.

______________________________________________________________________

**Happy Planning! 🎯**
