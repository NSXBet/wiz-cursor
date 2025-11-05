#!/usr/bin/env bash
# Extracted Wiz functions for testing
# These functions are extracted from .cursor/commands/*.md files

# wiz_load_context_metadata - Load metadata (frontmatter) from all local context files
wiz_load_context_metadata() {
    local context_dir=".wiz/context"
    local metadata_json="[]"
    
    if [[ ! -d "$context_dir" ]]; then
        echo "[]"
        return 0
    fi
    
    # Find all .md files and extract frontmatter
    while IFS= read -r -d '' file; do
        if [[ -f "$file" ]] && [[ -r "$file" ]]; then
            local rel_path="${file#$context_dir/}"
            
            # Extract frontmatter (between --- and ---)
            local frontmatter=$(awk '/^---$/{count++; if(count==1) next; if(count==2) exit} {if(count==1) print}' "$file" 2>/dev/null)
            
            if [[ -n "$frontmatter" ]]; then
                # Parse frontmatter into JSON
                local description=$(echo "$frontmatter" | grep -E "^description:" | sed 's/^description:[[:space:]]*//' | sed 's/^"//;s/"$//' || echo "")
                
                # Parse tags (optional)
                local tags=$(echo "$frontmatter" | grep -E "^tags:" | sed 's/^tags:[[:space:]]*//' | sed "s/^\[//;s/\]$//" | tr ',' '\n' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | sed 's/^"//;s/"$//' | jq -R . 2>/dev/null | jq -s . 2>/dev/null || echo "[]")
                
                # Parse languages (optional, empty means applies to all)
                local languages=$(echo "$frontmatter" | grep -E "^languages:" | sed 's/^languages:[[:space:]]*//' | sed "s/^\[//;s/\]$//" | tr ',' '\n' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | sed 's/^"//;s/"$//' | jq -R . 2>/dev/null | jq -s . 2>/dev/null || echo "[]")
                
                # Parse applies_to (optional, empty means applies to everything)
                local applies_to=$(echo "$frontmatter" | grep -E "^applies_to:" | sed 's/^applies_to:[[:space:]]*//' | sed "s/^\[//;s/\]$//" | tr ',' '\n' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | sed 's/^"//;s/"$//' | jq -R . 2>/dev/null | jq -s . 2>/dev/null || echo "[]")
                
                # Build JSON entry (only if description exists)
                if [[ -n "$description" ]]; then
                    local entry=$(jq -n \
                        --arg path "$rel_path" \
                        --arg desc "$description" \
                        --argjson tags "$tags" \
                        --argjson langs "$languages" \
                        --argjson applies "$applies_to" \
                        '{
                            path: $path,
                            description: $desc,
                            tags: $tags,
                            languages: $langs,
                            applies_to: $applies
                        }' 2>/dev/null)
                    
                    if [[ -n "$entry" ]]; then
                        metadata_json=$(echo "$metadata_json" | jq --argjson entry "$entry" '. += [$entry]' 2>/dev/null || echo "$metadata_json")
                    fi
                fi
            fi
        fi
    done < <(find "$context_dir" -name "*.md" -type f -print0 2>/dev/null)
    
    echo "$metadata_json"
}

# wiz_load_context_file - Load full content of a specific context file (without frontmatter)
wiz_load_context_file() {
    local file_path="$1"
    local context_dir=".wiz/context"
    local full_path="$context_dir/$file_path"
    
    if [[ ! -f "$full_path" ]]; then
        echo "Error: Context file not found: $file_path" >&2
        return 1
    fi
    
    # Skip frontmatter and return content
    local skip_frontmatter=false
    local line_num=0
    local content=""
    
    while IFS= read -r line; do
        ((line_num++))
        if [[ $line_num -eq 1 ]] && [[ "$line" == "---" ]]; then
            skip_frontmatter=true
            continue
        fi
        
        if [[ $skip_frontmatter == true ]]; then
            if [[ "$line" == "---" ]]; then
                skip_frontmatter=false
                continue
            fi
        else
            if [[ -n "$content" ]] || [[ -n "$line" ]]; then
                content+="$line"$'\n'
            fi
        fi
    done < "$full_path"
    
    echo -n "$content"
}

