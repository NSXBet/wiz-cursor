# Wiz Integration Tests

This directory contains integration tests for Wiz's core commands using Promptfoo and bash integration scripts.

## Structure

```
tests/
├── fixtures/              # Test data and fixtures
│   ├── context/          # Context files for testing
│   ├── workflows/        # Sample PRDs, phases, milestones
│   └── codebases/        # Minimal test repositories
├── prompts/              # Promptfoo configuration
│   ├── promptfoo.yaml    # Main Promptfoo config
│   └── test-suites/      # Test suites for each command
└── integration/          # Bash integration test scripts
```

## Running Tests

### Integration Tests (Bash Scripts)

Run all integration tests:
```bash
make test-integration
```

Run specific command tests:
```bash
make test-prd          # Test /wiz-prd
make test-phases        # Test /wiz-phases
make test-milestones    # Test /wiz-milestones
make test-next          # Test /wiz-next
make test-auto          # Test /wiz-auto
make test-workflow      # Test full workflow
```

Run individual test scripts:
```bash
bash tests/integration/test-wiz-prd.sh
bash tests/integration/test-wiz-phases.sh
# etc.
```

### Promptfoo Tests

Run Promptfoo prompt tests:
```bash
make test-prompts
```

Or run manually:
```bash
cd tests/prompts
npx promptfoo@latest eval
```

Run specific test suite:
```bash
cd tests/prompts
npx promptfoo@latest eval test-suites/wiz-prd.yaml
```

## Test Fixtures

### Context Files

Context files in `fixtures/context/` are used to test local context integration:

- `frameworks.md` - Framework specifications
- `go/patterns.md` - Go-specific patterns

### Codebase Fixtures

Minimal test repositories in `fixtures/codebases/` for testing codebase analysis:

- `go-project/` - Simple Go project

### Workflow Fixtures

Sample workflow artifacts in `fixtures/workflows/` (to be created):

- Test PRDs
- Test phases
- Test milestones

## Writing New Tests

### Adding Integration Tests

1. Create a new test script in `tests/integration/`
2. Follow the pattern from existing scripts:
   - Set up test environment
   - Execute command (or simulate)
   - Verify outputs
   - Clean up

Example:
```bash
#!/usr/bin/env bash
set -euo pipefail

# Test setup
test_my_command() {
    # Setup
    # Execute
    # Verify
    # Cleanup
}
```

### Adding Promptfoo Tests

1. Create a new test suite YAML file in `tests/prompts/test-suites/`
2. Define test cases with:
   - `vars` - Variables for the test
   - `assert` - Assertions to verify
   - `options` - LLM options

Example:
```yaml
tests:
  - vars:
      command: wiz-my-command
      slug: test-slug
    assert:
      - type: contains
        value: expected-output
```

## Test Coverage

Current test coverage:

- ✅ `/wiz-prd` - PRD generation with context
- ✅ `/wiz-phases` - Phase generation with context
- ✅ `/wiz-milestones` - Milestone generation with context
- ✅ `/wiz-next` - Milestone execution with context
- ✅ `/wiz-auto` - Automated milestone execution
- ✅ Full workflow (PRD → Phases → Milestones → Execution)

## Requirements

- **Node.js** - For Promptfoo (via npx)
- **Bash** - For integration test scripts
- **Make** - For running tests via Makefile

## CI/CD

Tests can be run in CI/CD pipelines. See `.github/workflows/` for GitHub Actions configuration.

## Notes

- Integration tests currently set up the test structure but don't execute actual commands (requires Cursor environment)
- Promptfoo tests validate prompt/LLM interactions
- Actual command execution tests require the Cursor IDE environment

