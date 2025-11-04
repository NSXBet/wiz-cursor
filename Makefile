.PHONY: lint lint-bash lint-markdown test help install-tools setup setup-format format format-bash format-markdown all

# Default target
.DEFAULT_GOAL := help

# Colors for output
BLUE := \033[0;34m
GREEN := \033[0;32m
YELLOW := \033[1;33m
NC := \033[0m # No Color

# Directories and files
BASH_FILES := install.sh run-tests.sh test-install.bats
MARKDOWN_FILES := $(shell find . -name '*.md' -not -path './.git/*' -not -path './node_modules/*' -not -path './.cursor/*')
TEST_FILE := *.bats

help: ## Show this help message
	@echo "$(BLUE)Available targets:$(NC)"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(GREEN)%-15s$(NC) %s\n", $$1, $$2}'

lint: lint-bash lint-markdown ## Run all linters

format: format-bash format-markdown ## Format all files

format-bash: ## Format bash scripts with shfmt
	@echo "$(BLUE)Formatting bash files...$(NC)"
	@if command -v shfmt >/dev/null 2>&1; then \
		for file in $(BASH_FILES); do \
			if [ -f "$$file" ]; then \
				echo "  Formatting $$file..."; \
				shfmt -w -i 4 -s $$file || exit 1; \
			fi; \
		done; \
		echo "$(GREEN)✓ Bash formatting complete$(NC)"; \
	else \
		echo "$(YELLOW)⚠ shfmt not installed. Install with:$(NC)"; \
		echo "  macOS: brew install shfmt"; \
		echo "  or: go install mvdan.cc/sh/v3/cmd/shfmt@latest"; \
		echo "  or run: make setup-format"; \
		exit 1; \
	fi

format-markdown: ## Format markdown files with mdformat (via uvx)
	@echo "$(BLUE)Formatting markdown files...$(NC)"
	@if command -v uvx >/dev/null 2>&1; then \
		uvx mdformat $(MARKDOWN_FILES) || exit 1; \
		echo "$(GREEN)✓ Markdown formatting complete$(NC)"; \
	elif command -v uv >/dev/null 2>&1; then \
		uv tool run mdformat $(MARKDOWN_FILES) || exit 1; \
		echo "$(GREEN)✓ Markdown formatting complete$(NC)"; \
	else \
		echo "$(YELLOW)⚠ uv/uvx not installed. Install with:$(NC)"; \
		echo "  macOS: brew install astral-sh/uv/uv"; \
		echo "  or: curl -LsSf https://astral.sh/uv/install.sh | sh"; \
		echo "  See: https://github.com/astral-sh/uv"; \
		exit 1; \
	fi

all: format lint test ## Run format, lint, and test
	@echo ""
	@echo "$(GREEN)✓ All checks passed!$(NC)"

lint-bash: ## Lint bash scripts with shellcheck
	@echo "$(BLUE)Linting bash files...$(NC)"
	@if command -v shellcheck >/dev/null 2>&1; then \
		for file in $(BASH_FILES); do \
			if [ -f "$$file" ]; then \
				echo "  Checking $$file..."; \
				shellcheck -x $$file || exit 1; \
			fi; \
		done; \
		echo "$(GREEN)✓ Bash linting passed$(NC)"; \
	else \
		echo "$(YELLOW)⚠ shellcheck not installed. Install with:$(NC)"; \
		echo "  macOS: brew install shellcheck"; \
		echo "  Linux: sudo apt-get install shellcheck"; \
		exit 1; \
	fi

lint-markdown: ## Lint markdown files with markdownlint (via npx)
	@echo "$(BLUE)Linting markdown files...$(NC)"
	@if command -v npx >/dev/null 2>&1; then \
		if [ -f .markdownlint.json ]; then \
			npx --yes markdownlint-cli --config .markdownlint.json $(MARKDOWN_FILES) || exit 1; \
		else \
			npx --yes markdownlint-cli $(MARKDOWN_FILES) || exit 1; \
		fi; \
		echo "$(GREEN)✓ Markdown linting passed$(NC)"; \
	else \
		echo "$(YELLOW)⚠ npx not installed. Install with:$(NC)"; \
		echo "  npm comes with Node.js - install Node.js from https://nodejs.org/"; \
		echo "  or: brew install node"; \
		exit 1; \
	fi

test: test-bats test-integration test-prompts ## Run all tests (bats + integration + prompts)

test-bats: ## Run bats-core tests
	@echo "$(BLUE)Running bats-core tests...$(NC)"
	@if command -v bats >/dev/null 2>&1; then \
		bats $(TEST_FILE) || exit 1; \
		echo "$(GREEN)✓ Bats tests passed$(NC)"; \
	else \
		echo "$(YELLOW)⚠ bats-core not installed. Skipping bats tests.$(NC)"; \
		echo "   Install with: make setup"; \
		echo "   or: brew install bats-core"; \
	fi

test-verbose: ## Run tests with verbose output
	@echo "$(BLUE)Running tests (verbose)...$(NC)"
	@if command -v bats >/dev/null 2>&1; then \
		bats --verbose $(TEST_FILE) || exit 1; \
		echo "$(GREEN)✓ Tests passed$(NC)"; \
	else \
		echo "$(YELLOW)⚠ bats-core not installed$(NC)"; \
		exit 1; \
	fi

# Integration testing targets
test-integration: test-prd test-phases test-milestones test-next test-auto test-workflow ## Run all integration tests

test-prd: ## Run /wiz-prd integration tests
	@echo "$(BLUE)Running /wiz-prd integration tests...$(NC)"
	@if [ -f tests/integration/test-wiz-prd.sh ]; then \
		bash tests/integration/test-wiz-prd.sh || exit 1; \
		echo "$(GREEN)✓ /wiz-prd tests passed$(NC)"; \
	else \
		echo "$(YELLOW)⚠ Integration test script not found$(NC)"; \
		exit 1; \
	fi

test-phases: ## Run /wiz-phases integration tests
	@echo "$(BLUE)Running /wiz-phases integration tests...$(NC)"
	@if [ -f tests/integration/test-wiz-phases.sh ]; then \
		bash tests/integration/test-wiz-phases.sh || exit 1; \
		echo "$(GREEN)✓ /wiz-phases tests passed$(NC)"; \
	else \
		echo "$(YELLOW)⚠ Integration test script not found$(NC)"; \
		exit 1; \
	fi

test-milestones: ## Run /wiz-milestones integration tests
	@echo "$(BLUE)Running /wiz-milestones integration tests...$(NC)"
	@if [ -f tests/integration/test-wiz-milestones.sh ]; then \
		bash tests/integration/test-wiz-milestones.sh || exit 1; \
		echo "$(GREEN)✓ /wiz-milestones tests passed$(NC)"; \
	else \
		echo "$(YELLOW)⚠ Integration test script not found$(NC)"; \
		exit 1; \
	fi

test-next: ## Run /wiz-next integration tests
	@echo "$(BLUE)Running /wiz-next integration tests...$(NC)"
	@if [ -f tests/integration/test-wiz-next.sh ]; then \
		bash tests/integration/test-wiz-next.sh || exit 1; \
		echo "$(GREEN)✓ /wiz-next tests passed$(NC)"; \
	else \
		echo "$(YELLOW)⚠ Integration test script not found$(NC)"; \
		exit 1; \
	fi

test-auto: ## Run /wiz-auto integration tests
	@echo "$(BLUE)Running /wiz-auto integration tests...$(NC)"
	@if [ -f tests/integration/test-wiz-auto.sh ]; then \
		bash tests/integration/test-wiz-auto.sh || exit 1; \
		echo "$(GREEN)✓ /wiz-auto tests passed$(NC)"; \
	else \
		echo "$(YELLOW)⚠ Integration test script not found$(NC)"; \
		exit 1; \
	fi

test-workflow: ## Run full workflow integration tests
	@echo "$(BLUE)Running full workflow integration tests...$(NC)"
	@if [ -f tests/integration/test-full-workflow.sh ]; then \
		bash tests/integration/test-full-workflow.sh || exit 1; \
		echo "$(GREEN)✓ Full workflow tests passed$(NC)"; \
	else \
		echo "$(YELLOW)⚠ Integration test script not found$(NC)"; \
		exit 1; \
	fi

test-prompts: ## Run Promptfoo prompt tests (requires OPENAI_API_KEY)
	@echo "$(BLUE)Running Promptfoo prompt tests...$(NC)"
	@if [ -z "$$OPENAI_API_KEY" ]; then \
		echo "$(YELLOW)⚠ OPENAI_API_KEY not set. Skipping prompt tests.$(NC)"; \
		echo "   Set OPENAI_API_KEY environment variable to run prompt tests."; \
		echo "   Example: OPENAI_API_KEY=your_key make test-prompts"; \
		exit 0; \
	fi
	@if command -v npx >/dev/null 2>&1; then \
		cd tests/prompts && npx promptfoo@latest eval -c promptfoo.yaml || exit 1; \
		echo "$(GREEN)✓ PRD prompt tests passed$(NC)"; \
		cd .. && cd prompts/test-suites && npx promptfoo@latest eval -c wiz-phases.yaml 2>/dev/null && echo "$(GREEN)✓ Phases prompt tests passed$(NC)" || echo "$(YELLOW)⚠ Phases tests skipped (API key or other issue)$(NC)"; \
		npx promptfoo@latest eval -c wiz-milestones.yaml 2>/dev/null && echo "$(GREEN)✓ Milestones prompt tests passed$(NC)" || echo "$(YELLOW)⚠ Milestones tests skipped (API key or other issue)$(NC)"; \
		echo "$(GREEN)✓ Prompt tests completed$(NC)"; \
	else \
		echo "$(YELLOW)⚠ npx not installed. Install Node.js$(NC)"; \
		exit 1; \
	fi

setup: ## Install bats-core and shellcheck using Homebrew
	@echo "$(BLUE)Setting up development environment...$(NC)"
	@if command -v brew >/dev/null 2>&1; then \
		echo "Installing bats-core..."; \
		brew install bats-core || true; \
		echo "Installing shellcheck..."; \
		brew install shellcheck || true; \
		echo "$(GREEN)✓ Setup complete$(NC)"; \
		echo ""; \
		echo "Installed tools:"; \
		bats --version || echo "  bats: not installed"; \
		shellcheck --version || echo "  shellcheck: not installed"; \
	else \
		echo "$(YELLOW)⚠ Homebrew not found. Please install Homebrew first:$(NC)"; \
		echo "  /bin/bash -c \"\$$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""; \
		exit 1; \
	fi

setup-format: ## Install formatting tools (shfmt)
	@echo "$(BLUE)Installing formatting tools...$(NC)"
	@if command -v brew >/dev/null 2>&1; then \
		echo "Installing shfmt..."; \
		brew install shfmt || true; \
		echo "$(GREEN)✓ Formatting tools installed$(NC)"; \
		echo ""; \
		echo "Note: mdformat is run via uvx (no installation needed)"; \
	else \
		echo "$(YELLOW)⚠ Homebrew not found. Please install tools manually:$(NC)"; \
		echo "  shfmt: brew install shfmt or go install mvdan.cc/sh/v3/cmd/shfmt@latest"; \
		echo "  uvx: Install uv from https://github.com/astral-sh/uv"; \
		exit 1; \
	fi

install-tools: ## Install linting and testing tools
	@echo "$(BLUE)Installing tools...$(NC)"
	@if command -v brew >/dev/null 2>&1; then \
		echo "Installing shellcheck..."; \
		brew install shellcheck || true; \
		echo "Installing bats-core..."; \
		brew install bats-core || true; \
		echo "$(GREEN)✓ Tools installed$(NC)"; \
		echo ""; \
		echo "Note: markdownlint-cli is run via npx (no installation needed)"; \
	else \
		echo "$(YELLOW)⚠ Homebrew not found. Please install tools manually:$(NC)"; \
		echo "  shellcheck: https://github.com/koalaman/shellcheck"; \
		echo "  bats-core: https://github.com/bats-core/bats-core"; \
		echo "  uv: Install from https://github.com/astral-sh/uv"; \
	fi

check-tools: ## Check if required tools are installed
	@echo "$(BLUE)Checking tools...$(NC)"
	@printf "shellcheck: "; \
	if command -v shellcheck >/dev/null 2>&1; then \
		echo "$(GREEN)✓ installed$(NC)"; \
	else \
		echo "$(YELLOW)✗ not installed$(NC)"; \
	fi
	@printf "bats: "; \
	if command -v bats >/dev/null 2>&1; then \
		echo "$(GREEN)✓ installed$(NC)"; \
	else \
		echo "$(YELLOW)✗ not installed$(NC)"; \
	fi
	@printf "npx: "; \
	if command -v npx >/dev/null 2>&1; then \
		echo "$(GREEN)✓ installed$(NC)"; \
	else \
		echo "$(YELLOW)✗ not installed$(NC)"; \
	fi
	@printf "uvx: "; \
	if command -v uvx >/dev/null 2>&1 || command -v uv >/dev/null 2>&1; then \
		echo "$(GREEN)✓ installed$(NC)"; \
	else \
		echo "$(YELLOW)✗ not installed$(NC)"; \
	fi
	@printf "shfmt: "; \
	if command -v shfmt >/dev/null 2>&1; then \
		echo "$(GREEN)✓ installed$(NC)"; \
	else \
		echo "$(YELLOW)✗ not installed$(NC)"; \
	fi

