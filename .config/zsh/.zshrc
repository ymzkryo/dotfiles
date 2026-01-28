# asdf init
if [ -f "$HOME/.asdf/asdf.sh" ]; then
  . $HOME/.asdf/asdf.sh
fi


for config_file in ~/.zsh/*.zsh; do
    source $config_file
done

alias claude="~/.local/bin/claude"
