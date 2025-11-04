# Quick Start Guide - Wiz Integration Tests

## Overview

This testing infrastructure provides integration tests for Wiz's core commands using:
- **Promptfoo** - For testing prompt/LLM interactions
- **Bash scripts** - For integration testing command execution

## Quick Start

### 1. Run All Integration Tests

```bash
make test-integration
```

This runs all integration tests for:
- `/wiz-prd`
- `/wiz-phases`
- `/wiz-milestones`
- `/wiz-next`
- `/wiz-auto`
- Full workflow

### 2. Run Specific Command Tests

```bash
make test-prd          # Test PRD generation
make test-phases       # Test phase generation
make test-milestones   # Test milestone generation
make test-next         # Test milestone execution
make test-auto         # Test automated execution
make test-workflow     # Test full workflow
```

### 3. Run Promptfoo Tests

```bash
make test-prompts
```

**Note**: Requires OpenAI API key. Set `OPENAI_API_KEY` environment variable or configure in `tests/prompts/.env`.

## Test Structure

### Integration Tests (`tests/integration/`)

Bash scripts that:
- Set up test environment
- Verify command outputs
- Test context integration
- Clean up test artifacts

**Example**: `test-wiz-prd.sh` tests PRD generation with various context scenarios.

### Promptfoo Tests (`tests/prompts/test-suites/`)

YAML configuration files that:
- Test prompt effectiveness
- Validate LLM outputs
- Compare model responses
- Test context integration in prompts

**Example**: `wiz-prd.yaml` tests PRD generation prompts with different context inputs.

## Test Fixtures

### Context Files (`tests/fixtures/context/`)

Sample context files for testing:
- `frameworks.md` - Framework specifications
- `go/patterns.md` - Go-specific patterns

### Workflow Fixtures (`tests/fixtures/workflows/`)

Sample workflow artifacts:
- `test-prd.md` - Example PRD
- `test-phases/` - Example phase files

### Codebase Fixtures (`tests/fixtures/codebases/`)

Minimal test repositories:
- `go-project/` - Simple Go project

## Writing New Tests

### Adding an Integration Test

1. Create script in `tests/integration/`:
```bash
#!/usr/bin/env bash
set -euo pipefail

# Source test helpers
source "$(dirname "$0")/../lib/test-helpers.sh"

# Your test function
test_my_command() {
    increment_test
    log_info "Test: My command"
    # Test logic here
    log_success "Test passed"
}

# Run tests
main() {
    test_my_command
    print_test_summary
}

main "$@"
```

2. Add Makefile target in `Makefile`:
```makefile
test-my-command: ## Run my-command tests
	@bash tests/integration/test-my-command.sh
```

### Adding a Promptfoo Test

1. Create YAML file in `tests/prompts/test-suites/`:
```yaml
description: 'Test my command'

providers:
  - openai:gpt-4o-mini

tests:
  - vars:
      command: wiz-my-command
      slug: test-slug
    assert:
      - type: contains
        value: expected-output
```

2. Add to `tests/prompts/promptfoo.yaml` or run directly:
```bash
cd tests/prompts
npx promptfoo@latest eval test-suites/my-command.yaml
```

## Requirements

- **Node.js** (v18+) - For Promptfoo
- **Bash** (v4+) - For integration scripts
- **Make** - For running tests
- **jq** (optional) - For JSON validation

## CI/CD

Tests run automatically in GitHub Actions (`.github/workflows/integration-tests.yml`).

To run locally:
```bash
# Run all tests
make test-integration

# Run specific test
make test-prd
```

## Troubleshooting

### Promptfoo Tests Fail

- Check API key is set: `echo $OPENAI_API_KEY`
- Verify Node.js is installed: `node --version`
- Check Promptfoo config: `cat tests/prompts/promptfoo.yaml`

### Integration Tests Fail

- Check bash version: `bash --version`
- Verify test scripts are executable: `ls -la tests/integration/`
- Check test helpers: `cat tests/lib/test-helpers.sh`

### Make Targets Not Found

- Check Makefile: `grep test- Makefile`
- Verify you're in project root: `pwd`

## Next Steps

1. **Configure API Keys**: Set up OpenAI API key for Promptfoo tests
2. **Run Tests**: Execute `make test-integration` to verify everything works
3. **Add More Tests**: Expand test coverage as needed
4. **Review Results**: Check test outputs and improve as necessary

## Documentation

- [Full Test Documentation](README.md)
- [Implementation Status](IMPLEMENTATION_STATUS.md)
- [Testing Plan](../../TESTING_PLAN.md)

