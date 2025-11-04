#!/usr/bin/env bash
# Extracted Wiz functions for testing
# These functions are extracted from .cursor/commands/*.md files

# wiz_load_context_metadata - Load metadata (frontmatter) from all local context files
wiz_load_context_metadata() {
    local context_dir=".wiz/context"
    local metadata_json="[]"
    
    if [[ ! -d "$context_dir" ]]; then
        echo "$metadata_json"
        return 0
    fi
    
    local temp_file
    temp_file=$(mktemp)
    
    # Find all markdown files in context directory (including subdirectories)
    while IFS= read -r -d '' file; do
        # Get relative path from context_dir
        local rel_path="${file#$context_dir/}"
        
        # Extract frontmatter
        if [[ -f "$file" ]]; then
            # Check if file has frontmatter
            if head -n 1 "$file" | grep -q "^---"; then
                # Extract frontmatter block
                local frontmatter=""
                local in_frontmatter=false
                local line_num=0
                
                while IFS= read -r line; do
                    ((line_num++))
                    if [[ $line_num -eq 1 ]] && [[ "$line" == "---" ]]; then
                        in_frontmatter=true
                        continue
                    fi
                    
                    if [[ $in_frontmatter == true ]]; then
                        if [[ "$line" == "---" ]]; then
                            break
                        fi
                        frontmatter+="$line"$'\n'
                    fi
                done < "$file"
                
                # Parse YAML to JSON (basic parsing)
                if [[ -n "$frontmatter" ]]; then
                    # Convert YAML-like structure to JSON (simplified)
                    local description=""
                    local tags="[]"
                    local languages="[]"
                    local applies_to="[]"
                    
                    # Extract description
                    if echo "$frontmatter" | grep -q "description:"; then
                        description=$(echo "$frontmatter" | grep "description:" | sed 's/description:[[:space:]]*//' | sed 's/^"//' | sed 's/"$//')
                    fi
                    
                    # Build JSON object
                    local json_obj="{\"path\":\"$rel_path\",\"description\":\"$description\",\"tags\":$tags,\"languages\":$languages,\"applies_to\":$applies_to}"
                    
                    # Add to array (simplified - would need proper JSON merging)
                    if [[ "$metadata_json" == "[]" ]]; then
                        metadata_json="[$json_obj]"
                    else
                        metadata_json="${metadata_json%,}]"
                        metadata_json="$metadata_json,$json_obj]"
                    fi
                fi
            fi
        fi
    done < <(find "$context_dir" -name "*.md" -type f -print0 2>/dev/null)
    
    rm -f "$temp_file"
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

