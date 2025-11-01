______________________________________________________________________

## description: Display project progress (simplified version)

# Project Status (Simplified)

Display project progress using simple atomic bash commands.

## Step 1: Check for Active PRD

```bash
# Try state.json first
SLUG=$(jq -r '.current_prd // ""' .wiz/state.json 2>/dev/null || echo "")

# Fall back to legacy file
if [[ -z "$SLUG" ]]; then
    if [[ -f ".wiz/.current-prd" ]]; then
        SLUG=$(cat .wiz/.current-prd)
    else
        echo "No active PRD"
        exit 0
    fi
fi
```

Save the output as `SLUG`.

## Step 2: Get Phase Files

```bash
ls -1 .wiz/$SLUG/phases/phase*.md 2>/dev/null || echo "No phases found"
```

## Step 3: Count Milestones Per Phase

For each phase file, run:

```bash
echo "=== Phase N ===" && \
grep -c '🚧 TODO' .wiz/$SLUG/phases/phaseN.md 2>/dev/null || echo "0" && \
grep -c '🏗️ IN PROGRESS' .wiz/$SLUG/phases/phaseN.md 2>/dev/null || echo "0" && \
grep -c '✅ COMPLETE' .wiz/$SLUG/phases/phaseN.md 2>/dev/null || echo "0"
```

## Step 4: Display Summary

Format and display the milestone counts in a readable format.
