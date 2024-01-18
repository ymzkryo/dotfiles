fpath=(${ASDF_DIR}/completions $fpath)
autoload -Uz compinit && compinit

# golang
. ~/.asdf/plugins/golang/set-env.zsh

# rust
export RUST_WITHOUT=rust-docs
source $HOME/.asdf/installs/rust/1.75.0/env
