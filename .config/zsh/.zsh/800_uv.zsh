# uv shell completion
if command -v uv &> /dev/null; then
    eval "$(uv generate-shell-completion zsh)"
fi

# uv tool bin path
export PATH="$HOME/.local/bin:$PATH"
