#!/usr/bin/env bash
# Extracted milestone functions for testing
# These functions are extracted from .cursor/commands/wiz-next.md

# wiz_extract_milestone_status - Extract status from milestone line
wiz_extract_milestone_status() {
    local line="$1"

    if echo "$line" | grep -q '🚧 TODO'; then
        echo "todo"
    elif echo "$line" | grep -q '🏗️ IN PROGRESS'; then
        echo "in_progress"
    elif echo "$line" | grep -q '✅ COMPLETE'; then
        echo "complete"
    else
        echo "unknown"
    fi

    return 0
}

# wiz_find_next_milestone - Find the next milestone after the last completed one
# Returns milestone ID (simplified version for testing)
wiz_find_next_milestone() {
    local slug="$1"
    local phases_dir=".wiz/$slug/phases"

    if [[ ! -d "$phases_dir" ]]; then
        echo ""
        return 1
    fi

    # Find last completed milestone
    local last_milestone_id=""
    
    # Scan all phase files in order
    for phase_file in "$phases_dir"/phase*.md; do
        if [[ ! -f "$phase_file" ]]; then
            continue
        fi
        
        # Find all COMPLETE milestones in this phase
        while IFS= read -r line; do
            if echo "$line" | grep -qE '^### P[0-9]+M[0-9]+'; then
                local milestone_id=$(echo "$line" | grep -oE 'P[0-9]+M[0-9]+')
                local status_line=$(grep -A 5 "^### $milestone_id" "$phase_file" | grep -E "Status|🚧|🏗️|✅" | head -1)
                
                if echo "$status_line" | grep -q '✅ COMPLETE'; then
                    last_milestone_id="$milestone_id"
                fi
            fi
        done < "$phase_file"
    done
    
    # If no completed milestones, start with P01M01
    if [[ -z "$last_milestone_id" ]]; then
        local phase1_file="$phases_dir/phase1.md"
        if [[ -f "$phase1_file" ]] && grep -q "^### P01M01" "$phase1_file"; then
            # Check if P01M01 is TODO
            local status_line=$(grep -A 5 "^### P01M01" "$phase1_file" | grep -E "Status|🚧|🏗️|✅" | head -1)
            if echo "$status_line" | grep -q '🚧 TODO'; then
                echo "P01M01"
                return 0
            fi
        fi
        last_milestone_id="P00M00"
    fi
    
    # Extract phase and milestone numbers
    local last_phase=$(echo "$last_milestone_id" | sed -E 's/^P0*([0-9]+)M[0-9]+$/\1/')
    local last_milestone=$(echo "$last_milestone_id" | sed -E 's/^P[0-9]+M0*([0-9]+)$/\1/')
    
    # Try next milestone in same phase
    local next_milestone_num=$((last_milestone + 1))
    local next_milestone_id=$(printf "P%02dM%02d" "$last_phase" "$next_milestone_num")
    local phase_file="$phases_dir/phase${last_phase}.md"
    
    if [[ -f "$phase_file" ]] && grep -q "^### $next_milestone_id" "$phase_file"; then
        # Check if TODO
        local status_line=$(grep -A 5 "^### $next_milestone_id" "$phase_file" | grep -E "Status|🚧|🏗️|✅" | head -1)
        if echo "$status_line" | grep -q '🚧 TODO'; then
            echo "$next_milestone_id"
            return 0
        fi
    fi
    
    # Try first milestone of next phase
    local next_phase_num=$((last_phase + 1))
    local next_phase_milestone_id=$(printf "P%02dM01" "$next_phase_num")
    local next_phase_file="$phases_dir/phase${next_phase_num}.md"
    
    if [[ -f "$next_phase_file" ]] && grep -q "^### $next_phase_milestone_id" "$next_phase_file"; then
        local status_line=$(grep -A 5 "^### $next_phase_milestone_id" "$next_phase_file" | grep -E "Status|🚧|🏗️|✅" | head -1)
        if echo "$status_line" | grep -q '🚧 TODO'; then
            echo "$next_phase_milestone_id"
            return 0
        fi
    fi
    
    # No next milestone found
    echo ""
    return 1
}

