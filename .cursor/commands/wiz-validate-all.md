______________________________________________________________________

## description: "Run codebase-wide quality validation (auxiliary command)"

# Validate Entire Codebase

**Note**: This is an auxiliary command for codebase-wide validation. It is not part of the typical milestone-based workflow.

## Command Overview

This command runs quality gates across the entire codebase:

- Detects all programming languages used
- Runs language-specific quality checks (lint, test, format, etc.)
- Aggregates results across all languages
- Generates comprehensive validation report

Use this command to:

- Perform periodic quality audits
- Validate codebase before major releases
- Check overall code health
- Identify widespread issues

## Embedded Utility Functions

### Logging Functions

```bash
# Check if terminal supports colors
_wiz_supports_color() {
    [[ -t 2 ]] && command -v tput >/dev/null 2>&1 && [[ $(tput colors 2>/dev/null || echo 0) -ge 8 ]]
}

# Color codes - only set if not already set
if [[ -z "${WIZ_COLOR_RESET+x}" ]]; then
    if _wiz_supports_color; then
        WIZ_COLOR_RESET="\033[0m"
        WIZ_COLOR_RED="\033[31m"
        WIZ_COLOR_YELLOW="\033[33m"
        WIZ_COLOR_BLUE="\033[34m"
        WIZ_COLOR_GRAY="\033[90m"
    else
        WIZ_COLOR_RESET=""
        WIZ_COLOR_RED=""
        WIZ_COLOR_YELLOW=""
        WIZ_COLOR_BLUE=""
        WIZ_COLOR_GRAY=""
    fi
    readonly WIZ_COLOR_RESET WIZ_COLOR_RED WIZ_COLOR_YELLOW WIZ_COLOR_BLUE WIZ_COLOR_GRAY 2>/dev/null || true
fi

# Get timestamp for logging
_wiz_timestamp() {
    date '+%Y-%m-%d %H:%M:%S'
}

# wiz_log_info - Log informational message
wiz_log_info() {
    local message="$*"
    echo -e "${WIZ_COLOR_BLUE}[$(_wiz_timestamp)] INFO:${WIZ_COLOR_RESET} $message" >&2
}

# wiz_log_warn - Log warning message
wiz_log_warn() {
    local message="$*"
    echo -e "${WIZ_COLOR_YELLOW}[$(_wiz_timestamp)] WARN:${WIZ_COLOR_RESET} $message" >&2
}

# wiz_log_error - Log error message
wiz_log_error() {
    local message="$*"
    echo -e "${WIZ_COLOR_RED}[$(_wiz_timestamp)] ERROR:${WIZ_COLOR_RESET} $message" >&2
}

# wiz_log_debug - Log debug message (only if WIZ_DEBUG is set)
wiz_log_debug() {
    if [[ "${WIZ_DEBUG:-}" == "1" ]] || [[ "${WIZ_DEBUG:-}" == "true" ]]; then
        local message="$*"
        echo -e "${WIZ_COLOR_GRAY}[$(_wiz_timestamp)] DEBUG:${WIZ_COLOR_RESET} $message" >&2
    fi
}
```

### File I/O Functions

```bash
# wiz_ensure_dir - Ensure directory exists, create if needed
wiz_ensure_dir() {
    local dir_path="$1"

    if [[ -d "$dir_path" ]]; then
        if [[ ! -w "$dir_path" ]]; then
            echo "ERROR: Directory not writable: $dir_path" >&2
            return 1
        fi
        return 0
    fi

    if ! mkdir -p "$dir_path" 2>/dev/null; then
        echo "ERROR: Failed to create directory: $dir_path" >&2
        return 1
    fi

    return 0
}
```

## Execution Steps

### Step 1: Detect Languages in Repository

```bash
#!/usr/bin/env bash
set -euo pipefail

echo ""
echo "🔍 Codebase Validation"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Scanning repository for code files..."
echo ""

# Detect languages by file extensions
declare -A LANGUAGE_FILES
declare -A LANGUAGE_COUNTS

# Go files
if GO_FILES=$(find . -name "*.go" -not -path "*/vendor/*" -not -path "*/.git/*" 2>/dev/null); then
    GO_COUNT=$(echo "$GO_FILES" | grep -c '\.go$' || echo "0")
    if [[ $GO_COUNT -gt 0 ]]; then
        LANGUAGE_FILES["go"]="$GO_FILES"
        LANGUAGE_COUNTS["go"]=$GO_COUNT
    fi
fi

# TypeScript/JavaScript files
if TS_FILES=$(find . \( -name "*.ts" -o -name "*.tsx" -o -name "*.js" -o -name "*.jsx" \) -not -path "*/node_modules/*" -not -path "*/.git/*" 2>/dev/null); then
    TS_COUNT=$(echo "$TS_FILES" | grep -cE '\.(ts|tsx|js|jsx)$' || echo "0")
    if [[ $TS_COUNT -gt 0 ]]; then
        LANGUAGE_FILES["typescript"]="$TS_FILES"
        LANGUAGE_COUNTS["typescript"]=$TS_COUNT
    fi
fi

# Python files
if PY_FILES=$(find . -name "*.py" -not -path "*/.git/*" -not -path "*/venv/*" -not -path "*/__pycache__/*" 2>/dev/null); then
    PY_COUNT=$(echo "$PY_FILES" | grep -c '\.py$' || echo "0")
    if [[ $PY_COUNT -gt 0 ]]; then
        LANGUAGE_FILES["python"]="$PY_FILES"
        LANGUAGE_COUNTS["python"]=$PY_COUNT
    fi
fi

# C# files
if CS_FILES=$(find . -name "*.cs" -not -path "*/.git/*" -not -path "*/bin/*" -not -path "*/obj/*" 2>/dev/null); then
    CS_COUNT=$(echo "$CS_FILES" | grep -c '\.cs$' || echo "0")
    if [[ $CS_COUNT -gt 0 ]]; then
        LANGUAGE_FILES["csharp"]="$CS_FILES"
        LANGUAGE_COUNTS["csharp"]=$CS_COUNT
    fi
fi

# Java files
if JAVA_FILES=$(find . -name "*.java" -not -path "*/.git/*" -not -path "*/target/*" 2>/dev/null); then
    JAVA_COUNT=$(echo "$JAVA_FILES" | grep -c '\.java$' || echo "0")
    if [[ $JAVA_COUNT -gt 0 ]]; then
        LANGUAGE_FILES["java"]="$JAVA_FILES"
        LANGUAGE_COUNTS["java"]=$JAVA_COUNT
    fi
fi

# Check if any code files found
if [[ ${#LANGUAGE_FILES[@]} -eq 0 ]]; then
    echo "❌ No code files found"
    echo ""
    echo "Supported languages:"
    echo "  - Go (.go)"
    echo "  - TypeScript/JavaScript (.ts, .tsx, .js, .jsx)"
    echo "  - Python (.py)"
    echo "  - C# (.cs)"
    echo "  - Java (.java)"
    echo ""
    exit 0
fi

# Display detected languages
echo "Detected Languages:"
echo ""
for lang in "${!LANGUAGE_COUNTS[@]}"; do
    count="${LANGUAGE_COUNTS[$lang]}"
    printf "  %-15s %5d files\n" "$lang" "$count"
done
echo ""
```

### Step 2: Run Quality Gates for Each Language

```bash
# Initialize results tracking
declare -A LANGUAGE_RESULTS
declare -A LANGUAGE_ERRORS
declare -A LANGUAGE_WARNINGS

echo "Running quality checks..."
echo ""

# Go quality gates
if [[ -n "${LANGUAGE_FILES[go]:-}" ]]; then
    echo "▶️  Go"

    # Run gofmt
    if command -v gofmt &> /dev/null; then
        GOFMT_OUTPUT=$(gofmt -l . 2>&1 | grep -v vendor || true)
        if [[ -n "$GOFMT_OUTPUT" ]]; then
            GOFMT_COUNT=$(echo "$GOFMT_OUTPUT" | wc -l)
            echo "  ⚠️  gofmt: $GOFMT_COUNT files need formatting"
            LANGUAGE_WARNINGS["go"]=$((${LANGUAGE_WARNINGS["go"]:-0} + GOFMT_COUNT))
        else
            echo "  ✅ gofmt: all files formatted"
        fi
    fi

    # Run go vet
    if command -v go &> /dev/null; then
        if go vet ./... 2>&1 | grep -v vendor > /tmp/govet.out; then
            echo "  ✅ go vet: no issues"
        else
            VET_COUNT=$(wc -l < /tmp/govet.out || echo "0")
            echo "  ⚠️  go vet: $VET_COUNT issues found"
            LANGUAGE_WARNINGS["go"]=$((${LANGUAGE_WARNINGS["go"]:-0} + VET_COUNT))
        fi
    fi

    # Run tests
    if command -v go &> /dev/null; then
        if go test ./... > /tmp/gotest.out 2>&1; then
            echo "  ✅ tests: all passing"
        else
            echo "  ❌ tests: failures detected"
            LANGUAGE_ERRORS["go"]=$((${LANGUAGE_ERRORS["go"]:-0} + 1))
        fi
    fi

    echo ""
fi

# TypeScript/JavaScript quality gates
if [[ -n "${LANGUAGE_FILES[typescript]:-}" ]]; then
    echo "▶️  TypeScript/JavaScript"

    # Check for eslint
    if command -v eslint &> /dev/null; then
        if eslint . --ext .ts,.tsx,.js,.jsx 2>&1 > /tmp/eslint.out; then
            echo "  ✅ eslint: no issues"
        else
            ESLINT_COUNT=$(grep -c "problem" /tmp/eslint.out || echo "0")
            echo "  ⚠️  eslint: $ESLINT_COUNT issues"
            LANGUAGE_WARNINGS["typescript"]=$((${LANGUAGE_WARNINGS["typescript"]:-0} + ESLINT_COUNT))
        fi
    fi

    # Check for tests (jest, vitest, etc.)
    if [[ -f "package.json" ]]; then
        if grep -q "\"test\":" package.json; then
            if npm test > /tmp/npmtest.out 2>&1; then
                echo "  ✅ tests: all passing"
            else
                echo "  ❌ tests: failures detected"
                LANGUAGE_ERRORS["typescript"]=$((${LANGUAGE_ERRORS["typescript"]:-0} + 1))
            fi
        fi
    fi

    echo ""
fi

# Python quality gates
if [[ -n "${LANGUAGE_FILES[python]:-}" ]]; then
    echo "▶️  Python"

    # Run black check
    if command -v black &> /dev/null; then
        if black --check . 2>&1 > /tmp/black.out; then
            echo "  ✅ black: all files formatted"
        else
            BLACK_COUNT=$(grep -c "would reformat" /tmp/black.out || echo "0")
            echo "  ⚠️  black: $BLACK_COUNT files need formatting"
            LANGUAGE_WARNINGS["python"]=$((${LANGUAGE_WARNINGS["python"]:-0} + BLACK_COUNT))
        fi
    fi

    # Run flake8
    if command -v flake8 &> /dev/null; then
        if flake8 . 2>&1 > /tmp/flake8.out; then
            echo "  ✅ flake8: no issues"
        else
            FLAKE8_COUNT=$(wc -l < /tmp/flake8.out || echo "0")
            echo "  ⚠️  flake8: $FLAKE8_COUNT issues"
            LANGUAGE_WARNINGS["python"]=$((${LANGUAGE_WARNINGS["python"]:-0} + FLAKE8_COUNT))
        fi
    fi

    # Run pytest
    if command -v pytest &> /dev/null; then
        if pytest > /tmp/pytest.out 2>&1; then
            echo "  ✅ tests: all passing"
        else
            echo "  ❌ tests: failures detected"
            LANGUAGE_ERRORS["python"]=$((${LANGUAGE_ERRORS["python"]:-0} + 1))
        fi
    fi

    echo ""
fi

# C# quality gates
if [[ -n "${LANGUAGE_FILES[csharp]:-}" ]]; then
    echo "▶️  C#"

    # Run dotnet format
    if command -v dotnet &> /dev/null; then
        if dotnet format --verify-no-changes > /tmp/dotnetformat.out 2>&1; then
            echo "  ✅ format: all files formatted"
        else
            echo "  ⚠️  format: formatting issues found"
            LANGUAGE_WARNINGS["csharp"]=$((${LANGUAGE_WARNINGS["csharp"]:-0} + 1))
        fi

        # Run tests
        if dotnet test > /tmp/dotnettest.out 2>&1; then
            echo "  ✅ tests: all passing"
        else
            echo "  ❌ tests: failures detected"
            LANGUAGE_ERRORS["csharp"]=$((${LANGUAGE_ERRORS["csharp"]:-0} + 1))
        fi
    fi

    echo ""
fi

# Java quality gates
if [[ -n "${LANGUAGE_FILES[java]:-}" ]]; then
    echo "▶️  Java"

    # Run checkstyle if configured
    if [[ -f "checkstyle.xml" ]] && command -v checkstyle &> /dev/null; then
        if checkstyle -c checkstyle.xml . > /tmp/checkstyle.out 2>&1; then
            echo "  ✅ checkstyle: no issues"
        else
            CHECKSTYLE_COUNT=$(grep -c "error" /tmp/checkstyle.out || echo "0")
            echo "  ⚠️  checkstyle: $CHECKSTYLE_COUNT issues"
            LANGUAGE_WARNINGS["java"]=$((${LANGUAGE_WARNINGS["java"]:-0} + CHECKSTYLE_COUNT))
        fi
    fi

    # Run tests (Maven or Gradle)
    if [[ -f "pom.xml" ]] && command -v mvn &> /dev/null; then
        if mvn test > /tmp/mvntest.out 2>&1; then
            echo "  ✅ tests: all passing"
        else
            echo "  ❌ tests: failures detected"
            LANGUAGE_ERRORS["java"]=$((${LANGUAGE_ERRORS["java"]:-0} + 1))
        fi
    elif [[ -f "build.gradle" ]] && command -v gradle &> /dev/null; then
        if gradle test > /tmp/gradletest.out 2>&1; then
            echo "  ✅ tests: all passing"
        else
            echo "  ❌ tests: failures detected"
            LANGUAGE_ERRORS["java"]=$((${LANGUAGE_ERRORS["java"]:-0} + 1))
        fi
    fi

    echo ""
fi
```

### Step 3: Generate Validation Report

```bash
# Calculate totals
TOTAL_ERRORS=0
TOTAL_WARNINGS=0

for lang in "${!LANGUAGE_ERRORS[@]}"; do
    TOTAL_ERRORS=$((TOTAL_ERRORS + LANGUAGE_ERRORS[$lang]))
done

for lang in "${!LANGUAGE_WARNINGS[@]}"; do
    TOTAL_WARNINGS=$((TOTAL_WARNINGS + LANGUAGE_WARNINGS[$lang]))
done

# Ensure .wiz directory exists
wiz_ensure_dir ".wiz"

# Generate report
REPORT_FILE=".wiz/validation-report.md"

cat > "$REPORT_FILE" <<EOF
# Codebase Validation Report

**Date**: $(date -u +"%Y-%m-%dT%H:%M:%SZ")
**Tool**: Wiz Planner - /wiz:validate-all

## Summary

**Languages Detected**: ${#LANGUAGE_FILES[@]}
**Total Errors**: $TOTAL_ERRORS
**Total Warnings**: $TOTAL_WARNINGS

EOF

# Add per-language sections
for lang in "${!LANGUAGE_FILES[@]}"; do
    count="${LANGUAGE_COUNTS[$lang]}"
    errors="${LANGUAGE_ERRORS[$lang]:-0}"
    warnings="${LANGUAGE_WARNINGS[$lang]:-0}"

    cat >> "$REPORT_FILE" <<EOF
## $lang

**Files**: $count
**Errors**: $errors
**Warnings**: $warnings

EOF
done

cat >> "$REPORT_FILE" <<EOF

## Recommendations

EOF

# Add recommendations based on findings
if [[ $TOTAL_ERRORS -gt 0 ]]; then
    cat >> "$REPORT_FILE" <<EOF
### Critical Issues

- Fix failing tests before proceeding
- Address build errors

EOF
fi

if [[ $TOTAL_WARNINGS -gt 0 ]]; then
    cat >> "$REPORT_FILE" <<EOF
### Warnings

- Address formatting issues
- Fix linting warnings
- Improve code quality

EOF
fi

cat >> "$REPORT_FILE" <<EOF

## Next Steps

1. Review detailed output in temporary files:
   - /tmp/govet.out, /tmp/gotest.out (Go)
   - /tmp/eslint.out, /tmp/npmtest.out (TypeScript)
   - /tmp/flake8.out, /tmp/pytest.out (Python)
   - /tmp/dotnettest.out (C#)
   - /tmp/mvntest.out or /tmp/gradletest.out (Java)

2. Fix errors before warnings
3. Run quality gates locally before committing
4. Consider adding pre-commit hooks

---

Generated by Wiz Planner
EOF

wiz_log_info "Validation report saved to $REPORT_FILE"
```

### Step 4: Display Summary

```bash
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Validation Summary"
echo ""
printf "Languages:  %d\n" "${#LANGUAGE_FILES[@]}"
printf "Errors:     %d\n" "$TOTAL_ERRORS"
printf "Warnings:   %d\n" "$TOTAL_WARNINGS"
echo ""

if [[ $TOTAL_ERRORS -eq 0 && $TOTAL_WARNINGS -eq 0 ]]; then
    echo "✅ Codebase validation passed!"
elif [[ $TOTAL_ERRORS -eq 0 ]]; then
    echo "⚠️  Codebase validation passed with warnings"
else
    echo "❌ Codebase validation failed"
fi

echo ""
echo "Detailed report: $REPORT_FILE"
echo ""
```

## Example Output

```
🔍 Codebase Validation
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Scanning repository for code files...

Detected Languages:

  go               45 files
  typescript       120 files
  python           32 files

Running quality checks...

▶️  Go
  ✅ gofmt: all files formatted
  ⚠️  go vet: 3 issues found
  ✅ tests: all passing

▶️  TypeScript/JavaScript
  ⚠️  eslint: 12 issues
  ✅ tests: all passing

▶️  Python
  ✅ black: all files formatted
  ⚠️  flake8: 5 issues
  ✅ tests: all passing

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Validation Summary

Languages:  3
Errors:     0
Warnings:   20

⚠️  Codebase validation passed with warnings

Detailed report: .wiz/validation-report.md
```

## Error Handling

- **No code files found**: Display supported languages and exit gracefully
- **Missing tools**: Skip language checks if tools not installed
- **Test failures**: Track errors but continue with other languages
- **Permission errors**: Log errors and continue

## Notes

- This is an auxiliary command, not part of milestone workflow
- Requires language-specific tools to be installed (gofmt, eslint, pytest, etc.)
- Tool availability is checked before running
- Missing tools are skipped gracefully
- Report saved to `.wiz/validation-report.md`
- Temporary output files saved to `/tmp/` for detailed review
- Can be run at any time for code health check
- Useful before releases or major milestones
- Integrates with quality gate skills (Phase 4)
