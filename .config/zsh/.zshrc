# mise init（asdf からの移行完了。ツールのバージョンは ~/.config/mise/config.toml と
# 各プロジェクトの mise.toml で管理する）
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
