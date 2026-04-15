# Auto switch AWS profile based on directory
function auto_switch_aws_profile() {
    local current_dir="$(pwd)"

    # Define directory-to-profile mappings
    local -A aws_dir_profiles
    aws_dir_profiles=(
        "$HOME/PROJECTS/info-box" "info-box"
        "$HOME/PROJECTS/outarc" "outarc"
        "$HOME/PROJECTS/ksd" "ksd"
    )

    # Also check parent directory patterns (e.g., outarc/*, ksd/*)
    local -A aws_parent_profiles
    aws_parent_profiles=(
        "$HOME/PROJECTS/outarc" "outarc"
        "$HOME/PROJECTS/ksd" "ksd"
    )

    # Check direct mappings first
    local matched_profile=""
    for dir_path profile in ${(kv)aws_dir_profiles}; do
        if [[ "$current_dir" == "$dir_path"* ]]; then
            matched_profile="$profile"
            break
        fi
    done

    # Check parent directory mappings (match subdirs but not the parent itself)
    if [[ -z "$matched_profile" ]]; then
        for dir_path profile in ${(kv)aws_parent_profiles}; do
            if [[ "$current_dir" == "$dir_path/"* ]]; then
                matched_profile="$profile"
                break
            fi
        done
    fi

    # Set or unset AWS_PROFILE
    if [[ -n "$matched_profile" ]]; then
        if [[ "$AWS_PROFILE" != "$matched_profile" ]]; then
            export AWS_PROFILE="$matched_profile"
            echo "AWS profile switched to: $matched_profile"
        fi
    else
        # Optionally unset AWS_PROFILE when leaving the directory
        if [[ -n "$AWS_PROFILE" ]]; then
            # Check if we've left all registered directories
            local in_any_dir=0
            for dir_path in ${(k)aws_dir_profiles}; do
                if [[ "$current_dir" == "$dir_path"* ]]; then
                    in_any_dir=1
                    break
                fi
            done

            if [[ $in_any_dir -eq 0 ]]; then
                unset AWS_PROFILE
                echo "AWS profile unset"
            fi
        fi
    fi
}

# Add to chpwd hook (called when directory changes)
autoload -U add-zsh-hook
add-zsh-hook chpwd auto_switch_aws_profile

# Run on shell start
auto_switch_aws_profile
