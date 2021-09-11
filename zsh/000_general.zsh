###################################
# zsh general setting
###################################

autoload -Uz promptinit
promptinit
prompt powerlevel10k

# キーバインド
bindkey -v
# エディタ
export EDITOR=/usr/local/bin/vim
# SSH接続先で日本語を使えるようにする
export LC_CTYPE=en_US.UTF-8
export LC_ALL=en_US.UTF-8
# 色を使用できるようにする
autoload -Uz colors
colors
# ビープを鳴らさない
setopt nobeep
## ^Dでログアウトしない。
setopt ignoreeof
## 色を使う
setopt prompt_subst
## 入力しているコマンド名が間違っている場合にもしかして：を出す。
setopt correct
## 補完機能の強化
autoload -U compinit
compinit

# 選択中の候補を塗り潰す
autoload -Uz compinit
compinit
zstyle ':completion:*' menu select
# 補完で小文字でも大文字にマッチさせる
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'
