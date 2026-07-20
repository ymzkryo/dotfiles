# WezTerm + tmux 横断ジャンプ（Ctrl-] に集約）
#
# 「今開いている tmux ウィンドウ」と「まだ開いていない ghq のリポジトリ」を
# 1つの fzf 一覧にまとめて出し、
#   - 開いているものを選べば   → そのウィンドウへジャンプ
#   - 開いていないものを選べば → 今のセッションに新しいウィンドウを作って開く
# どちらも同じ操作で済ませる。
#
# ジャンプは
#   1. 対象セッションを掴んでいる tmux クライアントの tty を調べる
#   2. その tty を持つ WezTerm ペインへフォーカスを移す (wezterm cli activate-pane)
#   3. そのクライアントを対象のセッション:ウィンドウへ切り替える
# という順で行うので、別の WezTerm タブにあっても一気に移動できる。
#
# リポジトリ一覧は 800_ghq.zsh の __ghq_list_cached から取る（無ければ tmux 分のみ）。

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

fzf-jump-window() {
  emulate -L zsh

  if ! command -v fzf >/dev/null 2>&1; then
    print -u2 "fzf が見つかりません: brew install fzf"
    return 1
  fi

  # 1列目を "session:window"（既存ウィンドウ）か "+"（未オープンのリポジトリ）に
  # 固定し、最終列を必ずパスにしておく。先頭と末尾のトークンだけ見れば判別できる。
  # tmux はセッション名に ':' を許可しないので先頭トークンは一意に切り出せる。
  local -a lines
  local l

  local wins
  # 空フィールドがあると column -t が列を詰めてしまうので、列は常に埋める
  wins=$(tmux list-windows -a -F \
           $'#{session_name}:#{window_index}\t#{?window_active,*,}#{window_name}\t[#{pane_current_command}]\t#{pane_current_path}' \
         2>/dev/null)

  typeset -A opened
  for l in ${(f)wins}; do
    [[ -n $l ]] || continue
    lines+=( "$l" )
    opened[${l##*$'\t'}]=1
  done

  # まだウィンドウで開いていないリポジトリを候補に足す
  if (( $+functions[__ghq_list_cached] )); then
    local d
    for d in ${(f)"$(__ghq_list_cached)"}; do
      [[ -n $d && -z ${opened[$d]} ]] || continue
      lines+=( $'+\t'"${d:h:t}/${d:t}"$'\t[未オープン]\t'"$d" )
    done
  fi

  if (( ! $#lines )); then
    print -u2 "候補がありません（tmux も ghq のキャッシュも空です）"
    return 1
  fi

  local selected
  selected=$(
    print -l -- "${lines[@]}" \
    | sed "s|$HOME|~|g" \
    | column -t -s $'\t' \
    | fzf --height=60% --layout=reverse --border --ansi \
          --prompt='jump> ' \
          --header='Enter: 移動（+ は新しいウィンドウで開く） / Ctrl-C: キャンセル' \
          --preview="if [ {1} = '+' ]; then git -C \$(printf %s {-1} | sed 's|^~|$HOME|') log --oneline --decorate -15 2>/dev/null; else tmux capture-pane -p -e -t '='{1}; fi" \
          --preview-window='right:55%:wrap'
  ) || return 0
  [[ -n $selected ]] || return 0

  local key=${selected%%[[:space:]]*}    # "0:2" または "+"
  local path_field=${selected##*[[:space:]]}

  if [[ $key == '+' ]]; then
    local dest=${path_field/#\~/$HOME}
    if [[ ! -d $dest ]]; then
      print -u2 "見つかりません: $path_field（ghq-cache-refresh を実行してください）"
      return 1
    fi
    if [[ -z $TMUX ]]; then
      cd -- "$dest"        # tmux の外なら cd にフォールバック
      return
    fi
    tmux new-window -n "${dest:t}" -c "$dest"
    return
  fi

  local sess=${key%%:*} idx=${key##*:}
  [[ -n $sess && -n $idx ]] || return 1
  __tmux_goto "$sess" "$idx"
}

# 指定したセッション（と任意でウィンドウ）へ移動する。
# 別の WezTerm タブでアタッチ済みならそのタブごと移動し、未アタッチなら
# 今のクライアントを切り替える。tmux の外から呼ばれた場合はアタッチする。
# 800_ghq.zsh からも使う。
__tmux_goto() {
  emulate -L zsh
  local sess=$1 idx=$2
  [[ -n $sess ]] || return 1

  # '=' は完全一致指定（数字だけのセッション名でもインデックスと誤解されない）
  local target="=${sess}"
  [[ -n $idx ]] && target="=${sess}:${idx}"

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
  elif [[ -n $idx ]]; then
    # tmux の外（素の zsh）から呼ばれた場合はそのままアタッチする
    tmux attach-session -t "=$sess" \; select-window -t "$target"
  else
    tmux attach-session -t "=$sess"
  fi
}

# Ctrl-] に集約（tmux の prefix は C-b なので衝突しない）
fzf-jump-window-widget() {
  fzf-jump-window
  zle reset-prompt
}
zle -N fzf-jump-window-widget
bindkey '^]' fzf-jump-window-widget          # emacs / insert mode
bindkey -M vicmd '^]' fzf-jump-window-widget # vi コマンドモード
