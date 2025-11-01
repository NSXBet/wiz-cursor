# Wiz Help Command

Show help for Wiz Planner commands.

## Arguments

- `[command-name]` (optional): Name of command to show help for (without `/` prefix)

## Usage

Show quick help summary:
```
/wiz-help
```

Show help for specific command:
```
/wiz-help wiz-next
/wiz-help wiz-prd
/wiz-help wiz-status
```

## Implementation

This command provides help information by extracting documentation from command files. It can show:
- Quick help summary for all commands
- Detailed help for a specific command

### Quick Help

When no command is specified, shows a summary of all available commands grouped by category.

### Command-Specific Help

When a command name is provided, extracts and displays:
- Description from YAML frontmatter
- Usage information with argument hints
- Examples from the command documentation
- Common options if available
- Troubleshooting tips

## Help Text Generation

### Extracting Frontmatter

```bash
# Extract YAML frontmatter from command file
extract_frontmatter() {
    local command_file="$1"
    
    if [[ ! -f "$command_file" ]]; then
        echo "❌ Error: Command file not found: $command_file" >&2
        return 1
    fi
    
    # Extract content between first two --- markers
    awk '/^---$/ {flag++; next} flag == 1' "$command_file"
}

# Get specific field from frontmatter
get_frontmatter_field() {
    local command_file="$1"
    local field_name="$2"
    
    local frontmatter
    frontmatter=$(extract_frontmatter "$command_file")
    
    # Parse YAML field (simple key: value format)
    echo "$frontmatter" | grep "^${field_name}:" | sed "s/^${field_name}: *//" | sed 's/"//g' || true
}

# Get command description
get_command_description() {
    local command_file="$1"
    get_frontmatter_field "$command_file" "description"
}

# Get argument hint
get_command_argument_hint() {
    local command_file="$1"
    get_frontmatter_field "$command_file" "argument-hint"
}
```

### Extracting Examples

```bash
# Extract example usage from command file
extract_examples() {
    local command_file="$1"
    
    # Look for markdown code blocks containing /wiz- commands
    # or lines that start with /wiz- outside code blocks
    grep -E '^\s*/wiz-|```.*\n/wiz-' "$command_file" | \
        sed 's/^[[:space:]]*//' | \
        grep '^/wiz-' || echo ""
}
```

### Generating Help Text

```bash
# Generate formatted help text for a command
generate_help_text() {
    local command_name="$1"
    local command_file="$2"
    
    if [[ ! -f "$command_file" ]]; then
        echo "❌ Error: Command not found: $command_name"
        echo ""
        list_available_commands
        return 1
    fi
    
    local description
    local arg_hint
    local examples
    
    description=$(get_command_description "$command_file")
    arg_hint=$(get_command_argument_hint "$command_file")
    examples=$(extract_examples "$command_file")
    
    # Header
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  /$command_name"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    
    # Description
    if [[ -n "$description" ]]; then
        echo "📝 Description:"
        echo "   $description"
        echo ""
    fi
    
    # Usage
    echo "📖 Usage:"
    if [[ -n "$arg_hint" ]]; then
        echo "   /$command_name $arg_hint"
    else
        echo "   /$command_name"
    fi
    echo ""
    
    # Examples
    if [[ -n "$examples" ]]; then
        echo "💡 Examples:"
        echo "$examples" | while IFS= read -r example; do
            if [[ -n "$example" ]]; then
                echo "   $example"
            fi
        done
        echo ""
    fi
    
    # Common options (if any flags are supported)
    if grep -q "\-\-" "$command_file" 2>/dev/null; then
        echo "⚙️  Common Options:"
        grep -E "^\s*-\-[a-z-]+.*:" "$command_file" | head -5 | while IFS= read -r option; do
            echo "   $option"
        done || true
        echo ""
    fi
    
    # Troubleshooting
    echo "🔧 Troubleshooting:"
    echo "   • Check command documentation: .cursor/commands/$command_name.md"
    echo "   • View workflow guide: .cursor/README.md"
    echo "   • Run /wiz-status to check project state"
    echo ""
    
    # Footer
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  For complete documentation, see: .cursor/README.md"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    
    return 0
}
```

### Listing Available Commands

```bash
# List all available wiz- commands
list_available_commands() {
    local commands_dir="${1:-.cursor/commands}"
    
    echo ""
    echo "Available Wiz Planner commands:"
    echo ""
    
    for cmd_file in "$commands_dir"/wiz-*.md; do
        if [[ -f "$cmd_file" ]]; then
            local cmd_name
            cmd_name=$(basename "$cmd_file" .md)
            local desc
            desc=$(get_command_description "$cmd_file")
            
            printf "  %-25s %s\n" "/$cmd_name" "$desc"
        fi
    done
    
    echo ""
    echo "Run '/wiz-help <command>' for detailed usage."
    echo ""
}
```

### Quick Help Summary

```bash
# Show quick help summary
show_quick_help() {
    echo ""
    echo "╔══════════════════════════════════════════════════════════════════════╗"
    echo "║                    Wiz Planner Quick Help                            ║"
    echo "╚══════════════════════════════════════════════════════════════════════╝"
    echo ""
    echo "🚀 Getting Started:"
    echo "   /wiz-prd <slug> \"<idea>\"      Create Product Requirements Document"
    echo "   /wiz-phases <slug>             Generate implementation phases"
    echo "   /wiz-milestones <slug>         Generate detailed milestones"
    echo "   /wiz-next                      Execute next milestone"
    echo ""
    echo "📊 Progress Tracking:"
    echo "   /wiz-status                    Show progress dashboard"
    echo "   /wiz-resume                    Resume interrupted work"
    echo ""
    echo "✅ Review & Validation:"
    echo "   /wiz-review-phase <slug> <n>   Review completed phase"
    echo "   /wiz-review-milestone <slug> <id>  Audit specific milestone"
    echo "   /wiz-validate-all              Run codebase validation"
    echo ""
    echo "📚 Documentation:"
    echo "   .cursor/README.md             Overview and usage guide"
    echo "   .cursor/MIGRATION.md          Migration notes"
    echo ""
    echo "💡 Tips:"
    echo "   • Run commands in order: PRD → Phases → Milestones → Next"
    echo "   • Use /wiz-status frequently to track progress"
    echo "   • Review phases when all milestones complete"
    echo ""
    echo "For detailed help on any command, run: /wiz-help <command-name>"
    echo ""
}
```

## Main Command Logic

```bash
#!/usr/bin/env bash
set -euo pipefail

# Parse arguments
COMMAND_NAME="${1:-}"

if [[ -z "$COMMAND_NAME" ]]; then
    # No command specified - show quick help
    show_quick_help
else
    # Remove leading slash if present
    COMMAND_NAME="${COMMAND_NAME#/}"
    
    # Add wiz- prefix if not present
    if [[ ! "$COMMAND_NAME" =~ ^wiz- ]]; then
        COMMAND_NAME="wiz-$COMMAND_NAME"
    fi
    
    # Find command file
    COMMAND_FILE=".cursor/commands/$COMMAND_NAME.md"
    
    if [[ ! -f "$COMMAND_FILE" ]]; then
        echo "❌ Error: Command not found: $COMMAND_NAME"
        echo ""
        list_available_commands ".cursor/commands"
        exit 1
    fi
    
    # Generate and display help
    generate_help_text "$COMMAND_NAME" "$COMMAND_FILE"
fi

exit 0
```

## Examples

### Show quick help
```
/wiz-help
```

Output:
```
╔══════════════════════════════════════════════════════════════════════╗
║                    Wiz Planner Quick Help                            ║
╚══════════════════════════════════════════════════════════════════════╝

🚀 Getting Started:
   /wiz-prd <slug> "<idea>"      Create Product Requirements Document
   /wiz-phases <slug>             Generate implementation phases
   ...
```

### Show command-specific help
```
/wiz-help wiz-next
```

Output:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  /wiz-next
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📝 Description:
   Find and execute the next TODO milestone

📖 Usage:
   /wiz-next [slug] [count]

💡 Examples:
   /wiz-next
   /wiz-next my-project
...
```

## Features

- Extracts description and usage from YAML frontmatter
- Shows examples from command documentation
- Lists common options if available
- Provides troubleshooting tips
- Links to complete documentation
- Falls back to command list if command not found

## Help Text Structure

Help is generated from command file frontmatter:

```yaml
---
description: Brief description of what command does
argument-hint: "<required-arg> [optional-arg]"
---
```

The help system extracts:
1. **Description** from `description` field
2. **Arguments** from `argument-hint` field
3. **Examples** by scanning for `/wiz-` commands in file
4. **Options** by scanning for `--flag` patterns

## See Also

- `.cursor/README.md` - Overview and usage guide
- `.cursor/MIGRATION.md` - Migration notes
- Individual command files in `.cursor/commands/` directory

