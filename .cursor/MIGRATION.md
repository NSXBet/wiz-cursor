# Migration Notes: Claude Code Plugin to Cursor

This document details the conversion of Wiz Planner from Claude Code plugin format to Cursor commands and agents.

## Conversion Summary

- **Source**: `../wiz-claude-code/` (Claude Code plugin structure)
- **Target**: `.cursor/` (Cursor commands and agents)
- **Date**: Conversion in progress

## Format Changes

### Commands

**Claude Code Format:**
```yaml
---
description: Command description
argument-hint: "<arg1> [arg2]"
---

# Command Content
...
```

**Cursor Format:**
- Same markdown structure
- YAML frontmatter preserved (may need adaptation)
- Scripts inlined (no `source` statements)
- Agent invocations updated

### Agents

**Claude Code Format:**
```yaml
---
name: "agent-name"
description: "Agent description"
tools: Read, Write, Edit
model: "sonnet"
---

# Agent Content
...
```

**Cursor Format:**
- Same markdown structure
- YAML frontmatter preserved
- Skills embedded directly in agent content
- Tool references verified

### Skills

**Claude Code Format:**
- Separate files in `skills/*/SKILL.md`
- Referenced by agents/commands

**Cursor Format:**
- **Embedded** directly in agent definitions
- Quality gates → Language specialists
- NFR checker → Reviewer agent
- Narrative commits → Commands (next.md, auto.md)

### Scripts

**Claude Code Format:**
- Separate files in `scripts/utils/*.sh`
- Referenced via `source "$SCRIPT_DIR/../scripts/utils/*.sh"`

**Cursor Format:**
- **Inlined** directly in commands where used
- Functions extracted and placed inline
- Path references updated

### Hooks

**Claude Code Format:**
- `hooks/hooks.json` with JSON structure
- Hook scripts referenced

**Cursor Format:**
- Cursor-specific hook format (to be determined)
- Scripts inlined or adapted

## Conversion Checklist

### Agents (9 total)
- [x] wiz-go-specialist (with embedded quality-gates-go)
- [ ] wiz-typescript-specialist (with embedded quality-gates-typescript)
- [ ] wiz-python-specialist (with embedded quality-gates-python)
- [ ] wiz-csharp-specialist (with embedded quality-gates-csharp)
- [ ] wiz-java-specialist (with embedded quality-gates-java)
- [ ] wiz-docker-specialist
- [ ] wiz-planner
- [ ] wiz-reviewer (with embedded nfr-checker)
- [ ] wiz-milestone-analyst

### Commands (13 total)
- [ ] wiz-help
- [ ] wiz-next
- [ ] wiz-prd
- [ ] wiz-phases
- [ ] wiz-milestones
- [ ] wiz-status
- [ ] wiz-resume
- [ ] wiz-auto
- [ ] wiz-review-phase
- [ ] wiz-review-milestone
- [ ] wiz-validate-all
- [ ] wiz-status-simple
- [ ] (skip test-subagent-filewriting.md)

### Hooks
- [ ] Convert hooks.json to Cursor format
- [ ] Adapt hook scripts

## Key Adaptations

1. **Agent Invocation**: Claude Code uses `subagent_type: "wiz:agent-name"` → Cursor format TBD
2. **Paths**: `${PLUGIN_ROOT}` → `.cursor/` relative paths
3. **Scripts**: `source` statements → Inlined functions
4. **Skills**: Separate files → Embedded sections in agents

## Known Issues

- Cursor's exact agent invocation format needs verification
- Hook format may differ significantly
- Some scripts may be very large when inlined

## Testing

After conversion, test:
- [ ] All commands appear in Cursor (`/` menu)
- [ ] Commands execute correctly
- [ ] Agents are invoked properly
- [ ] Scripts work when inlined
- [ ] Hooks trigger appropriately

