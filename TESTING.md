# Testing the Install Script

The install script uses [bats-core](https://github.com/bats-core/bats-core), a popular Bash testing framework, for comprehensive unit testing.

## Prerequisites

Install bats-core:

```bash
# macOS (using Homebrew)
brew install bats-core

# Linux (using apt)
sudo apt-get install bats

# Or install from source
git clone https://github.com/bats-core/bats-core.git
cd bats-core
sudo ./install.sh /usr/local
```

## Running Tests

```bash
# Using Makefile (recommended)
make test              # Run all tests
make test-verbose      # Run with verbose output
make lint              # Run all linters
make lint-bash         # Lint bash scripts
make lint-markdown     # Lint markdown files

# Or run directly
./run-tests.sh

# Or run directly with bats
bats test-install.bats

# Run with verbose output
bats --verbose test-install.bats

# Run specific test
bats --filter "extract_github_info" test-install.bats
```

## Installing Tools

```bash
# Check what tools are installed
make check-tools

# Install all tools (macOS with Homebrew)
make install-tools
```

## Test Coverage

The test suite covers all core functions:

- ✅ **extract_github_info**: Parses GitHub URLs (HTTPS and SSH)
- ✅ **build_tarball_urls**: Generates correct tarball URLs for tags and branches
- ✅ **determine_version**: Handles version detection and fallback logic
- ✅ **check_wiz_installed**: Detects existing Wiz installations
- ✅ **copy_cursor_files**: Copies files correctly
- ✅ **parse_args**: Parses command-line arguments

## Adding New Tests

Bats tests use a simple syntax. Add a new test in `test-install.bats`:

```bash
@test "my_function description" {
    run my_function "arg1" "arg2"
    [ "$status" -eq 0 ]
    [ "$output" = "expected output" ]
}
```

Common bats assertions:

- `[ "$status" -eq 0 ]` - Check exit code
- `[ "$output" = "text" ]` - Check exact output
- `[[ "$output" == *"text"* ]]` - Check output contains text
- `[ -f "$file" ]` - Check file exists
- `[ -d "$dir" ]` - Check directory exists

## Script Structure

The `install.sh` file is structured as:

1. **Configuration**: Default values and colors
1. **Utility Functions**: `info()`, `success()`, `warning()`, `error()`
1. **Core Functions**: Modular functions for each operation
1. **Main Function**: Orchestrates the installation flow
1. **Execution Guard**: Only runs `main()` when executed directly

When sourced (for testing), all functions are available but `main()` is not executed.

## Running the Installer

The installer works exactly as before:

```bash
# Install latest release
curl -fsSL https://raw.githubusercontent.com/NSXBet/wiz-cursor/refs/heads/main/install.sh | bash

# Install specific version
curl -fsSL https://raw.githubusercontent.com/NSXBet/wiz-cursor/refs/heads/main/install.sh | bash -- --version 0.1.2

# Install from HEAD
curl -fsSL https://raw.githubusercontent.com/NSXBet/wiz-cursor/refs/heads/main/install.sh | bash -- --version HEAD
```

## Benefits of bats-core

- ✅ **Industry standard**: Widely used and maintained
- ✅ **TAP compliant**: Works with CI/CD systems
- ✅ **Rich assertions**: Built-in test helpers
- ✅ **Parallel execution**: Fast test runs
- ✅ **No custom code**: Uses proven framework
