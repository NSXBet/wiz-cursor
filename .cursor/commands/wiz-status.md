______________________________________________________________________

## description: Display project progress and milestone statistics

# Project Status Dashboard

You are displaying project progress and milestone statistics using the Wiz Planner workflow.

## Command Overview

This command provides a comprehensive view of project progress including:

- Current PRD information
- Phase completion percentages
- Milestone statistics (TODO, IN_PROGRESS, COMPLETE)
- Time estimates
- Current and next milestones

## ⚠️ IMPORTANT: Use Simple Commands

This command has complex bash scripts. Execute each step as SINGLE atomic bash commands, not multi-line scripts.

For multi-line logic, use the Read tool to examine files, then process the data yourself.

## Embedded Utility Functions

### State Management Functions

```bash
# Get state file path
_wiz_get_state_file() {
    echo ".wiz/state.json"
}

# Initialize state file if it doesn't exist
_wiz_init_state() {
    local state_file
    state_file="$(_wiz_get_state_file)"
    local state_dir
    state_dir="$(dirname "$state_file")"

    if [[ ! -d "$state_dir" ]]; then
        mkdir -p "$state_dir" || return 1
    fi

    if [[ ! -f "$state_file" ]]; then
        echo '{}' | jq . > "$state_file"
    fi

    return 0
}

# wiz_get_current_prd - Get current PRD slug from state
wiz_get_current_prd() {
    _wiz_init_state || return 1

    local state_file
    state_file="$(_wiz_get_state_file)"

    local prd_slug
    prd_slug=$(jq -r '.current_prd // ""' "$state_file" 2>/dev/null) || {
        echo "ERROR: Failed to read current PRD from state" >&2
        return 1
    }

    echo "$prd_slug"
    return 0
}

# wiz_get_current_milestone - Get current milestone ID from state
wiz_get_current_milestone() {
    _wiz_init_state || return 1

    local state_file
    state_file="$(_wiz_get_state_file)"

    local milestone_id
    milestone_id=$(jq -r '.current_milestone // ""' "$state_file" 2>/dev/null) || {
        echo "ERROR: Failed to read current milestone from state" >&2
        return 1
    }

    echo "$milestone_id"
    return 0
}
```

## Execution Steps

### Step 1: Check for Active PRD

**Use simple bash commands**:

First, try to get PRD from state:

```bash
SLUG=$(wiz_get_current_prd 2>/dev/null || echo "")
```

If empty, fall back to legacy file:

```bash
if [[ -z "$SLUG" ]]; then
    SLUG=$(cat .wiz/.current-prd 2>/dev/null || echo "")
fi
```

If output is empty or "NO_PRD":

- Display message: "No active PRD found"
- Show setup instructions
- Exit

**Get PRD title**:

```bash
grep -m 1 "^# " .wiz/$SLUG/prd.md | sed 's/^# //'
```

Save as `PRD_TITLE`.

### Step 2: Count Milestones by Status

**Get phase files**:

```bash
ls -1 .wiz/$SLUG/phases/phase*.md
```

**For each phase file**, run these **SEPARATE** commands:

**Count TODO milestones**:

```bash
grep -c '🚧 TODO' .wiz/$SLUG/phases/phase1.md || echo 0
```

**Count IN PROGRESS milestones**:

```bash
grep -c '🏗️ IN PROGRESS' .wiz/$SLUG/phases/phase1.md || echo 0
```

**Count COMPLETE milestones**:

```bash
grep -c '✅ COMPLETE' .wiz/$SLUG/phases/phase1.md || echo 0
```

**Get phase title**:

```bash
grep -m 1 "^# " .wiz/$SLUG/phases/phase1.md | sed 's/^# //'
```

Store the counts for each phase, then sum them up yourself to get totals.

### Step 3: Calculate Statistics

Using the totals from Step 2, calculate yourself:

**Completion percentage**:

```
COMPLETION_PERCENT = (TOTAL_COMPLETE * 100) / TOTAL_MILESTONES
```

**Time remaining estimate**:

```
TIME_REMAINING_HOURS = TOTAL_TODO + (TOTAL_IN_PROGRESS / 2)
```

If > 24 hours, convert to days (assuming 8-hour workdays).

### Step 4: Find Current and Next Milestones

**Check for current milestone**:

First try state:

```bash
CURRENT_MILESTONE_ID=$(wiz_get_current_milestone 2>/dev/null || echo "")
```

If empty, check legacy file:

```bash
if [[ -z "$CURRENT_MILESTONE_ID" ]]; then
    if [[ -f ".wiz/.current-milestone.json" ]]; then
        CURRENT_MILESTONE_ID=$(jq -r '.milestone_id // ""' .wiz/.current-milestone.json 2>/dev/null || echo "")
    fi
fi
```

If milestone ID exists, find it in phase files:

```bash
# Search all phase files for the milestone
for phase_file in .wiz/$SLUG/phases/phase*.md; do
    if grep -q "^### ${CURRENT_MILESTONE_ID}:" "$phase_file"; then
        # Extract milestone title
        grep "^### ${CURRENT_MILESTONE_ID}:" "$phase_file" | sed "s/^### ${CURRENT_MILESTONE_ID}: //"
        break
    fi
done
```

**Find next TODO milestone**:

Use Grep tool to search all phase files for the pattern:

```
**Status:** 🚧 TODO
```

Find the first occurrence (lowest phase number, then lowest milestone number).

Extract the milestone ID and title from that section.

### Step 5: Display Status Dashboard

Format and display the information collected in Steps 1-4.

Use this structure (output text directly, don't use bash echo):

```
📊 Project Status: {PRD_TITLE}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

PRD: {SLUG}
Location: .wiz/{SLUG}/prd.md

Overall Progress
────────────────
Completion: {COMPLETION_PERCENT}% [{progress bar}]

Milestone Statistics
────────────────────
✅ Complete:     {TOTAL_COMPLETE}
🏗️  In Progress:  {TOTAL_IN_PROGRESS}
🚧 TODO:         {TOTAL_TODO}
━━━━━━━━━━━━━━━━━━━━━
   Total:        {TOTAL_MILESTONES}

Time Remaining: {TIME_ESTIMATE}

Phase Breakdown
───────────────
{For each phase:}
Phase {N}: {PHASE_NAME}
  Progress: {PERCENT}% ({COMPLETE}/{TOTAL}) | ✅ {COMPLETE} | 🏗️ {IN_PROG} | 🚧 {TODO}

{If current milestone exists:}
Current Milestone
─────────────────
🏗️  {MILESTONE_ID}: {TITLE}
Started: {STARTED_AT}

Run /wiz:resume to continue

{If next milestone exists:}
Next Milestone
──────────────
🚧 {MILESTONE_ID}: {TITLE}

Run /wiz:next to begin

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

**Progress bar**: Create a 50-character bar using █ for filled and ░ for empty based on completion percentage.

## Output Example

```
📊 Project Status: Authentication System

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

PRD: auth-system
Location: .wiz/auth-system/prd.md
Status: In Progress

Overall Progress
────────────────
Completion:  45% [██████████████████████░░░░░░░░░░░░░░░░░░░░░░░░░░]

Milestone Statistics
────────────────────
✅ Complete:       18
🏗️  In Progress:    1
🚧 TODO:           21
━━━━━━━━━━━━━━━━━━━━━
   Total:          40

Time Remaining: 3d (~21h)

Phase Breakdown
───────────────
Phase 1: Foundation & Setup
  Progress:  80% (8/10) | ✅ 8 | 🏗️ 0 | 🚧 2

Phase 2: Core Authentication
  Progress:  50% (10/20) | ✅ 10 | 🏗️ 1 | 🚧 9

Phase 3: Advanced Features
  Progress:   0% (0/10) | ✅ 0 | 🏗️ 0 | 🚧 10

Current Milestone
─────────────────
🏗️  P02M11: Implement JWT token validation
Started: 2025-01-19T10:30:00Z

Run /wiz:resume to continue

Next Milestone
──────────────
🚧 P02M12: Add token refresh mechanism

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## Error Handling

- **No active PRD**: Show helpful message with setup instructions
- **PRD file missing**: Warn about stale state
- **No phases directory**: Show message to run `/wiz:phases`
- **No milestones found**: Show message to run `/wiz:milestones`

## Performance

- Status calculation: \<1 second
- Scales to hundreds of milestones efficiently
- Uses grep for fast counting

## Notes

- Progress bar uses Unicode block characters (█░)
- Emoji indicators for visual clarity (✅🏗️🚧)
- Time estimate assumes 1h per milestone (configurable)
- Phase breakdown shows detailed statistics per phase
- Current milestone displayed if in progress
- Next milestone helps user know what to do
- Command requires no arguments (uses state or `.wiz/.current-prd`)
