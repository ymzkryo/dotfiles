# Starship prompt initialization
eval "$(starship init zsh)"

# Optional: Load starship completions (if needed)
zinit ice as"command" from "gh-r" \
    tclone"./starship init zsh > init.zsh; ./starship completions zsh > _starship" \
    atpull"%atclone" src"init.zsh"
zinit light starship/starship

