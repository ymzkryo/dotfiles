###################################
# *env PATH setting
###################################

# jenv
# export PATH="$HOME/.jenv/bin:$PATH"
# eval "$(jenv init -)"

# openjdk11
export PATH="/opt/homebrew/opt/openjdk@11/bin:$PATH"

# go
export GOENV_DISABLE_GOPATH=1
export GOPATH=$HOME/go
export PATH=$PATH:$GOPATH/bin

# ARM Homebrew
export PATH="/opt/homebrew/bin:$PATH"
export PATH="/opt/homebrew/sbin:$PATH"

# anyenv
export PATH="$HOME/.anyenv/bin:$PATH"
eval "$(anyenv init -)"

# pyenv-virtualenv
eval "$(pyenv virtualenv-init -)"

# chatgpt-api
# 外部ファイルから読み込むように変更
export CHATGPT_API_KEY=~/.config/chatgpt-api/api_key
