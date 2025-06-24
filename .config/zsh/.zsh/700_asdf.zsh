# Load asdf version manager
export PATH="$HOME/.asdf/shims:$PATH"
. ~/.asdf/asdf.sh
fpath=(${ASDF_DIR}/completions $fpath)
