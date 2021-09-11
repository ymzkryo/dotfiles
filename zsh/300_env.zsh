###################################
# *env PATH setting
###################################

# jenv
export PATH="$HOME/.jenv/bin:$PATH"
# eval "$(jenv init -)"

# openjdk11
export PATH="/opt/homebrew/opt/openjdk@11/bin:$PATH"

# go
export GOENV_DISABLE_GOPATH=1
export GOPATH=$HOME/go
export PATH=$PATH:$GOPATH/bin

# ARM Homebrew
export PATH="/opt/homebrew/bin:$PATH"

# anyenv
export PATH="$HOME/.anyenv/bin:$PATH"
eval "$(anyenv init -)"

export PATH="/opt/homebrew/opt/ncurses/bin:$PATH"

export LDFLAGS="-L/opt/homebrew/opt/ncurses/lib"
export CPPFLAGS="-I/opt/homebrew/opt/ncurses/include"

export PKG_CONFIG_PATH="/opt/homebrew/opt/ncurses/lib/pkgconfig"

export PYTHONPATH='/Users/ymzkryo/.anyenv/envs/pyenv/versions/3.9.1/lib/python3.9/site-packages'
