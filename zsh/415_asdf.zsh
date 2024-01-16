fpath=(${ASDF_DIR}/completions $fpath)
autoload -Uz compinit && compinit

. ~/.asdf/plugins/golang/set-env.zsh
