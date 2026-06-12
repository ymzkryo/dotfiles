# asdf init
if [ -f "$HOME/.asdf/asdf.sh" ]; then
  . $HOME/.asdf/asdf.sh
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
