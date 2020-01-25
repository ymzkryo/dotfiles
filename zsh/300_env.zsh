# pyenv SETTING
export PYENV_ROOT=/usr/local/var/pyenv
eval "$(pyenv init -)"

# goenv SETTING
export GOENV_ROOT="$HOME/.goenv"
export PATH="$GOENV_ROOT/bin:$PATH"
eval "$(goenv init -)"
export PATH="$GOROOT/bin:$PATH"
export PATH="$PATH:$GOPATH/bin"

# rbenv SETTING
if which rbenv > /dev/null; then eval "$(rbenv init -)"; fi
export PATH=$HOME/.rbenv/bin:$PATH
eval "$(rbenv init -)"

# nodebrew SETTING
export PATH=$HOME/.nodebrew/current/bin:$PATH

