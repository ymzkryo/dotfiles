# asdf init
if [ -f "$HOME/.asdf/asdf.sh" ]; then
  . $HOME/.asdf/asdf.sh
fi

# mise init（asdf の後に読み込み、PATH 上で mise を優先させる。移行完了後に上の asdf ブロックを削除する）
if command -v mise >/dev/null 2>&1; then
  eval "$(mise activate zsh)"
fi


for config_file in ~/.zsh/*.zsh; do
    source $config_file
done

# pnpm
export PNPM_HOME="/Users/ymzkryo/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end
