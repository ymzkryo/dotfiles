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

# プロンプト
# VCSの情報を取得するzsh関数
autoload -Uz vcs_info
autoload -Uz colors # black red green yellow blue magenta cyan white
colors

# PROMPT変数内で変数参照
setopt prompt_subst

zstyle ':vcs_info:git:*' check-for-changes true #formats 設定項目で %c,%u が使用可
zstyle ':vcs_info:git:*' stagedstr "%F{green}!" #commit されていないファイルがある
zstyle ':vcs_info:git:*' unstagedstr "%F{magenta}+" #add されていないファイルがある
zstyle ':vcs_info:*' formats "%F{yellow}%c%u(%b)%f" #通常
zstyle ':vcs_info:*' actionformats '[%b|%a]' #rebase 途中,merge コンフリクト等 formats 外の表示

# %b ブランチ情報
# %a アクション名(mergeなど)
# %c changes
# %u uncommit

# プロンプト表示直前に vcs_info 呼び出し
precmd () { vcs_info }

# プロンプト（左）
PROMPT='%{$fg[red]%}[%~]%{$reset_color%}'
PROMPT=$PROMPT'${vcs_info_msg_0_} %{${fg[red]}%}%}$%{${reset_color}%} '
# プロンプト（右）
RPROMPT='%{${fg[cyan]}%}[%*]%{${reset_color}%}'

# alias
# brewの時、envを使わない
alias brew="PATH=/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin brew"
# 年月日別メモファイル作成
alias memo='vim ~/memo/$(date "+%Y/%m/%d.md")'

# gcalcliのtoday-tomorrowを呼び出し
alias gcal='gcalcli agenda now tomorrow'

# 自作todoistのコマンド省略
alias todoist='./main.py'

# pyenv SETTING
export PYENV_ROOT=/usr/local/var/pyenv
eval "$(pyenv init -)"

# goenv SETTING
export GOENV_ROOT=$HOME/.goenv
export PATH=$GOENV_ROOT/bin:$PATH
eval "$(goenv init -)"

export GOPATH=$HOME/go
PATH=$PATH:$GOPATH/bin

# rbenv SETTING
if which rbenv > /dev/null; then eval "$(rbenv init -)"; fi
export PATH=$HOME/.rbenv/bin:$PATH
eval "$(rbenv init -)"
