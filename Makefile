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
MARKDOWN_FILES := $(shell find . -name '*.md' -not -path './.git/*' -not -path './node_modules/*')
TEST_FILE := test-install.bats

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

lint-markdown: ## Lint markdown files with markdownlint
	@echo "$(BLUE)Linting markdown files...$(NC)"
	@if command -v markdownlint >/dev/null 2>&1; then \
		markdownlint $(MARKDOWN_FILES) || exit 1; \
		echo "$(GREEN)✓ Markdown linting passed$(NC)"; \
	elif command -v npm >/dev/null 2>&1; then \
		if [ -f "node_modules/.bin/markdownlint-cli" ]; then \
			./node_modules/.bin/markdownlint-cli $(MARKDOWN_FILES) || exit 1; \
			echo "$(GREEN)✓ Markdown linting passed$(NC)"; \
		else \
			echo "$(YELLOW)⚠ markdownlint not found. Install with:$(NC)"; \
			echo "  npm install -g markdownlint-cli"; \
			echo "  or run: make install-tools"; \
			exit 1; \
		fi; \
	else \
		echo "$(YELLOW)⚠ markdownlint not installed. Install with:$(NC)"; \
		echo "  npm install -g markdownlint-cli"; \
		echo "  or run: make install-tools"; \
		exit 1; \
	fi

test: ## Run tests with bats-core
	@echo "$(BLUE)Running tests...$(NC)"
	@if command -v bats >/dev/null 2>&1; then \
		bats $(TEST_FILE) || exit 1; \
		echo "$(GREEN)✓ Tests passed$(NC)"; \
	else \
		echo "$(YELLOW)⚠ bats-core not installed. Install with:$(NC)"; \
		echo "  macOS: brew install bats-core"; \
		echo "  Linux: sudo apt-get install bats"; \
		exit 1; \
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
		echo "Installing markdownlint-cli..."; \
		npm install -g markdownlint-cli || true; \
		echo "$(GREEN)✓ Tools installed$(NC)"; \
	else \
		echo "$(YELLOW)⚠ Homebrew not found. Please install tools manually:$(NC)"; \
		echo "  shellcheck: https://github.com/koalaman/shellcheck"; \
		echo "  bats-core: https://github.com/bats-core/bats-core"; \
		echo "  markdownlint-cli: npm install -g markdownlint-cli"; \
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
	@printf "markdownlint: "; \
	if command -v markdownlint >/dev/null 2>&1 || command -v npm >/dev/null 2>&1; then \
		echo "$(GREEN)✓ installed$(NC)"; \
	else \
		echo "$(YELLOW)✗ not installed$(NC)"; \
	fi

