# Wiz Planner for Cursor

This directory contains the Wiz Planner plugin converted from Claude Code to Cursor format.

## Structure

- `.cursor/commands/` - Slash commands for Cursor
- `.cursor/agents/` - Specialized agents (with embedded skills)
- `.cursor/hooks/` - Cursor hooks configuration

## Key Differences from Claude Code

1. **Skills Embedded**: Quality gates and other skills are embedded directly in agent definitions rather than separate files
2. **Scripts Inlined**: Bash scripts referenced by commands are inlined within the command files
3. **No Plugin Root**: References to `${PLUGIN_ROOT}` removed, paths use `.cursor/` relative structure
4. **Hooks Format**: Hooks use Cursor's format (may differ from Claude Code)

## Usage

Commands are available via `/` in Cursor chat. Agents are invoked by commands when needed.

## Commands

- `/wiz-help` - Show help for Wiz Planner commands
- `/wiz-prd` - Generate Product Requirements Document
- `/wiz-phases` - Break PRD into implementation phases
- `/wiz-milestones` - Generate detailed milestones
- `/wiz-next` - Execute next milestone
- `/wiz-status` - Show project progress
- `/wiz-resume` - Resume interrupted work
- `/wiz-auto` - Auto-execute milestones
- `/wiz-review-phase` - Review completed phase
- `/wiz-review-milestone` - Review completed milestone
- `/wiz-validate-all` - Validate entire codebase

## Agents

- `wiz-planner` - Strategic planning and research
- `wiz-reviewer` - Quality assurance (with embedded NFR checker)
- `wiz-milestone-analyst` - Milestone analysis
- `wiz-go-specialist` - Go expertise (with embedded quality gates)
- `wiz-typescript-specialist` - TypeScript expertise (with embedded quality gates)
- `wiz-python-specialist` - Python expertise (with embedded quality gates)
- `wiz-csharp-specialist` - C# expertise (with embedded quality gates)
- `wiz-java-specialist` - Java expertise (with embedded quality gates)
- `wiz-docker-specialist` - Docker expertise

## Conversion Notes

- All commands maintain their original functionality
- Scripts are inlined where referenced
- Agent invocations updated to Cursor format
- Path references updated to `.cursor/` structure

See `MIGRATION.md` for detailed conversion notes.

