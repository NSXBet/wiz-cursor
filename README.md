# Wiz Planner for Cursor

**Wiz** is an intelligent project planning and execution system that works seamlessly with Cursor to help you break down complex features into manageable milestones and execute them systematically.

## 🚀 Quick Start

### Prerequisites

- **Cursor 2.0+** - The latest version of Cursor IDE
- **Composer1** - We recommend using Composer1 (not Composer2) for the best experience with Wiz commands
- A project repository (Git-based)

### Installation

#### Option 1: Quick Install (Recommended)

**Method 1: Using GitHub CLI (`gh`)** - Works for both public and private repos:

```bash
gh api repos/NSXBet/wiz-cursor/contents/install.sh?ref=main --jq -r .content | base64 -d | bash
```

> **Note**: Requires GitHub CLI (`gh`) to be installed and authenticated. Install from [cli.github.com](https://cli.github.com/)

**Method 2: Using `curl`** - Works for public repositories:

```bash
curl -fsSL https://raw.githubusercontent.com/NSXBet/wiz-cursor/main/install.sh | bash
```

**Or download and review the script first** (recommended for security):

```bash
# Download the script
curl -fsSL https://raw.githubusercontent.com/NSXBet/wiz-cursor/main/install.sh -o install.sh
# Review the script
cat install.sh
# Then run it
bash install.sh
```

**Method 3: Manual installation** - Clone and copy `.cursor` directory:

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

The install script automatically tries multiple installation methods:
1. **Git sparse checkout** (most efficient, works for public/private repos with git access)
2. **GitHub tarball download** (fallback for public repos, tries multiple URL formats)

The script will:
- Try multiple URLs and methods automatically
- Download the `.cursor` directory from the repository
- Place it in your current directory
- Prompt before overwriting if `.cursor` already exists
- Clean up temporary files automatically
- Provide helpful error messages if all methods fail

#### Option 2: Alternative Manual Installation

If you prefer to clone the entire repository:

```bash
# Clone the repository
git clone https://github.com/NSXBet/wiz-cursor.git
cd wiz-cursor

# Copy .cursor to your project
cp -r .cursor /path/to/your/project/
```

### Your First Project

```bash
# 1. Create a Product Requirements Document (PRD)
/wiz-prd my-feature "Add user authentication with JWT tokens"

# 2. Answer the clarifying questions that Wiz asks
# (Wiz will wait for your answers)

# 3. Generate implementation phases
/wiz-phases my-feature

# 4. Generate detailed milestones
/wiz-milestones my-feature

# 5. Start implementing!
/wiz-next
```

## 📖 What is Wiz?

Wiz Planner helps you:

- **Plan**: Break down complex features into structured phases and ~1-hour milestones
- **Execute**: Systematically implement milestones with quality gates
- **Review**: Validate completed work against acceptance criteria
- **Track**: Monitor progress across phases and milestones

### Key Concepts

- **PRD (Product Requirements Document)**: Comprehensive specification of your feature
- **Phases**: Major blocks of work (typically 3-5 days each)
- **Milestones**: Small, focused tasks (~1 hour each) with clear acceptance criteria
- **Quality Gates**: Automatic checks for tests, linting, security, and code quality

## 🎯 Core Workflow

### 1. Planning Phase

**Create PRD** (`/wiz-prd`)
- Wiz asks clarifying questions about your idea
- You provide answers
- Wiz generates a comprehensive PRD with research-backed recommendations

**Generate Phases** (`/wiz-phases`)
- Wiz breaks down the PRD into logical implementation phases
- Each phase has clear goals and dependencies

**Generate Milestones** (`/wiz-milestones`)
- Wiz creates detailed ~1-hour milestones for each phase
- Each milestone has specific acceptance criteria

### 2. Execution Phase

**Execute Next Milestone** (`/wiz-next`)
- Wiz finds the next TODO milestone
- Implements it completely (code, tests, docs)
- Runs quality checks (tests, linting)
- Creates a commit when done

**Auto-Execute** (`/wiz-auto`)
- Automatically executes multiple milestones in sequence
- Stops for human input when needed (via milestone analyst)
- Perfect for batch implementation

**Resume Work** (`/wiz-resume`)
- Resume interrupted milestone work
- Pick up where you left off

### 3. Review Phase

**Review Milestone** (`/wiz-review-milestone`)
- Comprehensive quality audit of a completed milestone
- Verifies acceptance criteria
- Checks NFR compliance (security, observability, etc.)

**Review Phase** (`/wiz-review-phase`)
- Reviews an entire completed phase
- Verifies integration and phase-level goals

**Validate All** (`/wiz-validate-all`)
- Full codebase validation
- Checks tests, linting, security across entire project

### 4. Tracking

**Status Dashboard** (`/wiz-status`)
- View progress across all phases
- See milestone statistics (TODO, IN_PROGRESS, COMPLETE)
- Track time estimates

## 🛠️ Commands Reference

### Planning Commands

| Command                    | Description                        |
| -------------------------- | ---------------------------------- |
| `/wiz-prd <slug> "<idea>"` | Generate PRD from idea             |
| `/wiz-phases <slug>`       | Break PRD into phases              |
| `/wiz-milestones <slug>`   | Generate milestones for all phases |

### Execution Commands

| Command            | Description                 |
| ------------------ | --------------------------- |
| `/wiz-next [slug]` | Execute next TODO milestone |
| `/wiz-auto [slug]` | Auto-execute milestones     |
| `/wiz-resume`      | Resume interrupted work     |

### Review Commands

| Command                             | Description               |
| ----------------------------------- | ------------------------- |
| `/wiz-review-milestone <slug> <id>` | Review specific milestone |
| `/wiz-review-phase <slug> <n>`      | Review completed phase    |
| `/wiz-validate-all`                 | Validate entire codebase  |

### Utility Commands

| Command               | Description            |
| --------------------- | ---------------------- |
| `/wiz-status`         | Show project progress  |
| `/wiz-help [command]` | Show help for commands |

For detailed documentation on each command, see [docs/commands.md](./docs/commands.md).

## 🤖 Agents

Wiz uses specialized agents for different tasks:

- **wiz-planner**: Strategic planning and research
- **wiz-reviewer**: Quality assurance and NFR checking
- **wiz-milestone-analyst**: Gatekeeper for auto-execution
- **Language Specialists**: Go, TypeScript, Python, C#, Java, Docker expertise

For detailed documentation on each agent, see [docs/agents.md](./docs/agents.md).

## 💡 Best Practices

### Using Composer1

We recommend using **Composer1** (not Composer2) with Cursor 2.0+ for the best experience. Composer1 provides:
- Better context awareness for Wiz commands
- More reliable agent invocation
- Improved file writing capabilities

### Workflow Tips

1. **Start Small**: Begin with a simple feature to learn the workflow
2. **Review PRDs**: Always review the generated PRD before proceeding to phases
3. **Check Status**: Use `/wiz-status` frequently to track progress
4. **Review Milestones**: Review completed milestones before moving to the next phase
5. **Quality First**: Wiz enforces quality gates - fix issues as they arise

### Quality Standards

Wiz enforces strict quality standards:

- ✅ **P0: Correctness** - Code must work
- ✅ **P1: Tests** - All tests must pass (no failures, no skips)
- ✅ **P2: Security** - Input validation, no secrets, secure practices
- ✅ **P3: Quality** - Lint-clean, documented, maintainable
- ✅ **P4: Performance** - Meets performance requirements

**Zero tolerance**: No failing tests, no lint errors, no skipped tests.

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

## 🔍 How It Works

### Planning Stage

1. **PRD Creation**: Wiz analyzes your codebase, asks clarifying questions, researches best practices, and generates a comprehensive PRD
2. **Phase Decomposition**: Wiz breaks the PRD into 3-15 logical phases (each ~3-5 days)
3. **Milestone Generation**: Wiz creates 15-40 milestones per phase (each ~1 hour)

### Execution Stage

1. **Milestone Selection**: Wiz finds the next TODO milestone
2. **Implementation**: Wiz implements the milestone (code, tests, docs)
3. **Quality Checks**: Automatic tests, linting, security checks
4. **Specialist Review**: Language specialists review for best practices
5. **Commit**: Creates a properly formatted commit
6. **Status Update**: Marks milestone as COMPLETE

### Review Stage

1. **Criteria Verification**: Checks each acceptance criterion
2. **Code Quality**: Reviews implementation against standards
3. **NFR Compliance**: Verifies security, observability, reliability, documentation
4. **Report Generation**: Creates detailed review report

## 🎓 Examples

### Example: Adding Authentication

```bash
# 1. Create PRD
/wiz-prd auth-system "Add JWT-based authentication"

# Answer questions about:
# - User registration flow
# - Token expiration
# - OAuth providers
# - Security requirements

# 2. Generate phases
/wiz-phases auth-system

# Result: Phases like:
# - Phase 1: User model and database schema
# - Phase 2: JWT token generation and validation
# - Phase 3: Authentication middleware
# - Phase 4: Login/logout endpoints
# - Phase 5: Testing and documentation

# 3. Generate milestones
/wiz-milestones auth-system

# Result: ~1-hour milestones like:
# - P01M01: Create User model struct
# - P01M02: Add database migration
# - P02M01: Implement JWT token generation
# ...

# 4. Execute
/wiz-next

# Wiz implements P01M01, runs tests, commits, then moves to P01M02
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
- **[.cursor/README.md](./.cursor/README.md)** - Technical details and structure

## 🤝 Contributing

Wiz is designed to be extensible. To add new features:

1. Add command files to `.cursor/commands/`
2. Add agent files to `.cursor/agents/`
3. Follow existing patterns for consistency

## 📝 License

[Add your license information here]

## 🙏 Acknowledgments

Wiz Planner helps you write better code, faster, with confidence.

---

**Happy Planning! 🎯**

