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

# wezterm cli のラッパー。WEZTERM_UNIX_SOCKET は tmux 経由だと古い値を引き継ぐ
# ことがあるので、失敗したら環境変数を外して再試行する。
# --no-auto-start は、接続に失敗したときに余計な mux サーバを起こさないため。
__wezterm_cli() {
  command -v wezterm >/dev/null 2>&1 || return 1
  wezterm cli --no-auto-start "$@" 2>/dev/null \
    || env -u WEZTERM_UNIX_SOCKET wezterm cli --no-auto-start "$@" 2>/dev/null
}

# tty から WezTerm の pane_id / window_id を引く。見つからなければ空文字を返す。
__wezterm_field_for_tty() {
  local tty=$1 field=${2:-pane_id}
  [[ -n $tty ]] || return 1
  command -v jq >/dev/null 2>&1 || return 1

  local json
  json=$(__wezterm_cli list --format json) || return 1
  print -r -- "$json" | jq -r --arg tty "$tty" --arg f "$field" '
    [.[] | select(.tty_name == $tty) | .[$f]] | first // empty
  '
}

__wezterm_pane_id_for_tty() { __wezterm_field_for_tty "$1" pane_id }

__wezterm_activate_pane() {
  local pane_id=$1
  [[ -n $pane_id ]] || return 1
  __wezterm_cli activate-pane --pane-id "$pane_id" >/dev/null
}

# 新しい WezTerm タブを開き、その中で tmux セッション（= 会社・プロジェクト単位の
# タブ）を起こして目的のディレクトリのウィンドウを開く。
# 既に同名セッションがあれば new-session -A がアタッチするだけになる。
__wezterm_new_tab_session() {
  emulate -L zsh
  local session=$1 dir=$2 winname=$3

  local -a spawn_args=( spawn --cwd "$dir" )
  # WEZTERM_PANE は tmux 経由だと古い値のことがあるので、今のクライアントの
  # tty から window_id を引いて、確実に今の WezTerm ウィンドウにタブを足す。
  local wid
  wid=$(__wezterm_field_for_tty "$(tmux display-message -p '#{client_tty}' 2>/dev/null)" window_id)
  [[ -n $wid ]] && spawn_args+=( --window-id "$wid" )
  spawn_args+=( -- tmux new-session -A -s "$session" -c "$dir" -n "$winname" )

  __wezterm_cli "${spawn_args[@]}" >/dev/null
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

  # まだウィンドウで開いていないリポジトリ・作業ディレクトリを候補に足す
  if (( $+functions[__ghq_list_cached] )); then
    local d tag
    for d in ${(f)"$(__ghq_list_cached)"}; do
      [[ -n $d && -z ${opened[$d]} ]] || continue
      [[ -e $d/.git ]] && tag='[未オープン]' || tag='[dir]'   # git 管理でないものは区別する
      lines+=( $'+\t'"${d:h:t}/${d:t}"$'\t'"$tag"$'\t'"$d" )
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
          --preview="if [ {1} = '+' ]; then p=\$(printf %s {-1} | sed 's|^~|$HOME|'); git -C \"\$p\" log --oneline --decorate -15 2>/dev/null || ls -la \"\$p\"; else tmux capture-pane -p -e -t '='{1}; fi" \
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

    # 同じ会社ラベルのウィンドウを開いているセッション（= タブ）を探す
    local sess=$(__tmux_session_for_repo "$dest")

    if [[ -z $sess ]]; then
      # そのラベルのタブがまだ無い → 新しい WezTerm タブを開いて tmux を起こす
      local label=$(__projects_label "$dest")
      local tabname=${TMUX_TAB_LABEL[$label]:-$label}
      print "[$label] タブがないので新しい WezTerm タブを開きます（セッション: $tabname）"
      if ! __wezterm_new_tab_session "$tabname" "$dest" "${dest:t}"; then
        # WezTerm が使えない環境ではセッションだけ作って移動する
        print -u2 "  wezterm cli が使えないため、セッションだけ作って移動します"
        tmux new-session -d -s "$tabname" -c "$dest" -n "${dest:t}" || return 1
        __tmux_goto "$tabname"
      fi
      return
    fi

    local created
    created=$(tmux new-window -d -P -F '#{session_name}:#{window_index}' \
                -t "=${sess}:" -n "${dest:t}" -c "$dest") || return 1
    __tmux_goto "${created%%:*}" "${created##*:}"
    return
  fi

  local sess=${key%%:*} idx=${key##*:}
  [[ -n $sess && -n $idx ]] || return 1
  __tmux_goto "$sess" "$idx"
}

# パスから会社・プロジェクトのラベルを取る。~/PROJECTS 配下の第1階層。
#   ~/PROJECTS/outarc/nss_rag  → outarc
#   ~/PROJECTS/lukas           → lukas（PROJECTS 直下のプロジェクトはそれ自体がラベル）
#   ~/dotfiles                 → 非 0 で返す（ラベル無し）
__projects_label() {
  emulate -L zsh
  local p=$1
  [[ $p == $HOME/PROJECTS/* ]] || return 1
  local rel=${p#$HOME/PROJECTS/}
  [[ -n ${rel%%/*} ]] || return 1
  print -r -- "${rel%%/*}"
}

# リポジトリを新しいウィンドウで開くとき、どのセッションに作るかを決める。
#
# ~/PROJECTS/<会社ラベル>/... の会社ラベル単位でセッションが分かれている運用なので、
# 同じラベルのウィンドウを既に開いているセッションがあればそこに合流させる。
#   1. 今いるセッションが既にそのラベルを持っていれば、今のセッション（移動しない）
#   2. 候補が1つならそこ
#   3. 複数あるなら、そのラベルのウィンドウを最後に使ったセッション
# ラベルが取れない（ホーム直下や PROJECTS 直下）、どこにも無い場合は今のセッション。
#
# 「最後に使った」の判定には #{window_activity} を使う。#{session_activity} は
# デタッチ中のセッションで出力があっても更新されないことを実測で確認したため。
__tmux_session_for_repo() {
  emulate -L zsh
  local dest=$1
  local current=$(tmux display-message -p '#{session_name}')

  local label
  label=$(__projects_label "$dest") || { print -r -- "$current"; return }

  # そのラベル配下を開いているウィンドウを "最終アクティブ時刻<TAB>セッション名" で集める
  local -a rows
  rows=( ${(f)"$(tmux list-windows -a -F $'#{window_activity}\t#{session_name}\t#{pane_current_path}' 2>/dev/null \
                 | awk -F'\t' -v base="$HOME/PROJECTS/$label" '$3 == base || index($3, base "/") == 1 { print $1 "\t" $2 }')"} )
  rows=( ${rows:#} )
  # ラベルはあるがどのタブでも開いていない → 空を返す（呼び出し側が新しいタブを作る）
  (( $#rows )) || return 0

  local -a candidates
  candidates=( ${(u)${rows##*$'\t'}} )
  (( ${candidates[(I)$current]} )) && { print -r -- "$current"; return }

  local chosen=${${(On)rows}[1]##*$'\t'}    # 数値降順で先頭 = 最後に使ったもの
  if (( $#candidates > 1 )); then
    print -u2 "[$label] 候補が複数あります (${candidates[*]}) → 最後に使った $chosen に作成します"
  else
    print -u2 "[$label] セッション $chosen に作成します"
  fi
  print -r -- "$chosen"
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

# 新しくタブ（= セッション）を作るときの名前。会社ラベルをそのまま使うが、
# 別名にしたいものだけここに書く。既存セッションのリネームはしない。
typeset -gA TMUX_TAB_LABEL=(
  [snail]=個人開発
)

# Ctrl-] に集約（tmux の prefix は C-b なので衝突しない）
fzf-jump-window-widget() {
  fzf-jump-window
  zle reset-prompt
}
zle -N fzf-jump-window-widget
bindkey '^]' fzf-jump-window-widget          # emacs / insert mode
bindkey -M vicmd '^]' fzf-jump-window-widget # vi コマンドモード
