# WezTerm + tmux 横断ジャンプ
#
# 全 tmux セッション/ウィンドウを fzf で検索し、
#   1. 対象セッションを掴んでいる tmux クライアントの tty を調べる
#   2. その tty を持つ WezTerm ペインへフォーカスを移す (wezterm cli activate-pane)
#   3. そのクライアントを対象のセッション:ウィンドウへ切り替える
# という順で「別タブの別セッション」まで一気にジャンプする。

# tty から WezTerm の pane_id を引く。見つからなければ空文字を返す。
__wezterm_pane_id_for_tty() {
  local tty=$1
  [[ -n $tty ]] || return 1
  command -v wezterm >/dev/null 2>&1 || return 1
  command -v jq >/dev/null 2>&1 || return 1

  local json
  # WEZTERM_UNIX_SOCKET は tmux 経由だと古い値を引き継ぐことがあるので、
  # 失敗したら環境変数を外して再試行する。--no-auto-start で余計な mux は起こさない。
  json=$(wezterm cli --no-auto-start list --format json 2>/dev/null) \
    || json=$(env -u WEZTERM_UNIX_SOCKET wezterm cli --no-auto-start list --format json 2>/dev/null) \
    || return 1

  print -r -- "$json" | jq -r --arg tty "$tty" '
    [.[] | select(.tty_name == $tty) | .pane_id] | first // empty
  '
}

__wezterm_activate_pane() {
  local pane_id=$1
  [[ -n $pane_id ]] || return 1
  wezterm cli --no-auto-start activate-pane --pane-id "$pane_id" 2>/dev/null \
    || env -u WEZTERM_UNIX_SOCKET wezterm cli --no-auto-start activate-pane --pane-id "$pane_id" 2>/dev/null
}

fzf-jump-tmux-window() {
  emulate -L zsh

  if ! command -v fzf >/dev/null 2>&1; then
    print -u2 "fzf が見つかりません: brew install fzf"
    return 1
  fi
  if ! tmux has-session 2>/dev/null; then
    print -u2 "起動中の tmux セッションがありません"
    return 1
  fi

  # 1列目を "session:window" に固定しておき、そこだけをパースする
  # （tmux はセッション名に ':' を許可しないので先頭トークンで一意に切り出せる）
  local selected
  selected=$(
    tmux list-windows -a -F \
      $'#{session_name}:#{window_index}\t#{window_name}\t[#{pane_current_command}]\t#{b:pane_current_path}\t#{?window_active,<active>,}' \
    | column -t -s $'\t' \
    | fzf --height=60% --layout=reverse --border --ansi \
          --prompt='tmux window> ' \
          --header='Enter: ジャンプ / Ctrl-C: キャンセル' \
          --preview='tmux capture-pane -p -e -t "="{1}' \
          --preview-window='right:55%:wrap'
  ) || return 0
  [[ -n $selected ]] || return 0

  local key=${selected%%[[:space:]]*}   # 例: dotfiles:2
  local sess=${key%%:*} idx=${key##*:}
  [[ -n $sess && -n $idx ]] || return 1
  local target="=${sess}:${idx}"        # '=' は完全一致指定（数字だけの名前でも誤爆しない）

  # 対象セッションを既に掴んでいるクライアント（= 別の WezTerm タブ）を探す
  local client_tty
  client_tty=$(tmux list-clients -t "=$sess" -F '#{client_tty}' 2>/dev/null | head -1)

  if [[ -n $client_tty ]]; then
    __wezterm_activate_pane "$(__wezterm_pane_id_for_tty "$client_tty")"
    # そのタブのクライアントを目的のウィンドウへ（同一セッションなら select-window 相当）
    tmux switch-client -c "$client_tty" -t "$target" 2>/dev/null \
      || tmux select-window -t "$target"
  elif [[ -n $TMUX ]]; then
    # どこにもアタッチされていないセッション → 今のクライアントを切り替える
    tmux switch-client -t "$target"
  else
    # tmux の外（素の zsh）から呼ばれた場合はそのままアタッチする
    tmux attach-session -t "=$sess" \; select-window -t "$target"
  fi
}

# Ctrl-] でジャンプ（tmux の prefix は C-b なので衝突しない）
fzf-jump-tmux-window-widget() {
  fzf-jump-tmux-window
  zle reset-prompt
}
zle -N fzf-jump-tmux-window-widget
bindkey '^]' fzf-jump-tmux-window-widget          # emacs / insert mode
bindkey -M vicmd '^]' fzf-jump-tmux-window-widget # vi コマンドモード
