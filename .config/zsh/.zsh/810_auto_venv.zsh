# Auto activate/deactivate Python virtual environment
function auto_activate_venv() {
    # Check if .venv directory exists in current directory
    if [[ -d ".venv" ]]; then
        # Only activate if not already activated or different venv
        if [[ "$VIRTUAL_ENV" != "$(pwd)/.venv" ]]; then
            # Deactivate current venv if any
            if [[ -n "$VIRTUAL_ENV" ]]; then
                deactivate
            fi
            source .venv/bin/activate
        fi
    else
        # Deactivate if we're in a venv and moved out of the project
        if [[ -n "$VIRTUAL_ENV" ]]; then
            # Get the project directory (parent of .venv)
            local venv_project_dir="${VIRTUAL_ENV:h}"
            # Check if current directory is outside the venv's project
            if [[ "$(pwd)" != "$venv_project_dir"* ]]; then
                deactivate
            fi
        fi
    fi
}

# Add to chpwd hook (called when directory changes)
autoload -U add-zsh-hook
add-zsh-hook chpwd auto_activate_venv

# Run on shell start
auto_activate_venv
