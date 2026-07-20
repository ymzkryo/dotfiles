# ghq + fzf でリポジトリを横断移動
#
# ghq.root は ~/PROJECTS（.gitconfig で設定）。ツリーは ~/PROJECTS/<会社ラベル>/<repo>
# のフラット構造で統一し、host セグメントは使わない（理由は後述の repo-get 参照）。
# ghq は「一覧を作るインデックス」として使い、clone には使わない。
# 既存の ~/PROJECTS/<org>/<repo> 形式も ghq list が拾ってくれるので移行は不要。
# 加えて ~/dotfiles や ~/vim のようなホーム直下のリポジトリも候補に混ぜる。
#
# ghq list は 40〜50 リポジトリで 2 秒以上かかるため、結果をキャッシュして
# 10 分より古ければバックグラウンドで裏更新する（体感は常に即時）。

typeset -g GHQ_CACHE_FILE="${XDG_CACHE_HOME:-$HOME/.cache}/ghq/list"

# git 管理ではない作業ディレクトリを候補に入れるときの除外設定。
# （~/PROJECTS/outarc/nss_rag のように .git が無いが日常的に開くものがあるため）
typeset -ga GHQ_DIR_EXCLUDE_GROUP=( _data )                 # このラベル配下は丸ごと除外
typeset -ga GHQ_DIR_EXCLUDE_NAME=( node_modules _data tmp temp )

# 候補一覧を作り直してキャッシュに書く
__ghq_build_list() {
  emulate -L zsh
  command -v ghq >/dev/null 2>&1 || return 1

  local dir=${GHQ_CACHE_FILE:h}
  [[ -d $dir ]] || mkdir -p -- "$dir" || return 1

  local tmp="${GHQ_CACHE_FILE}.$$"
  {
    ghq list -p
    print -l -- $HOME/*/.git(N:h)   # ホーム直下のリポジトリ（dotfiles, vim, ...）
    __projects_plain_dirs           # git 管理ではない作業ディレクトリ
  } | awk 'NF && !seen[$0]++' > "$tmp" && command mv -f "$tmp" "$GHQ_CACHE_FILE"
}

# ~/PROJECTS/<ラベル>/<ディレクトリ> のうち git 管理でないものを列挙する。
# ドットディレクトリ（.claude など）は zsh のグロブが最初から拾わない。
__projects_plain_dirs() {
  emulate -L zsh
  local d group
  for d in $HOME/PROJECTS/*/*(N/); do
    [[ -e $d/.git ]] && continue                       # git リポジトリは ghq list 側で出る
    group=${${d:h}:t}
    (( ${GHQ_DIR_EXCLUDE_GROUP[(I)$group]} )) && continue
    (( ${GHQ_DIR_EXCLUDE_NAME[(I)${d:t}]} )) && continue
    [[ -e ${d:h}/.git ]] && continue                   # 親自体がリポジトリ = ただの下位ディレクトリ
    print -r -- "$d"
  done
}

# キャッシュを標準出力へ。無ければ同期生成、古ければ裏で更新。
__ghq_list_cached() {
  emulate -L zsh
  if [[ ! -s $GHQ_CACHE_FILE ]]; then
    __ghq_build_list || return 1
  else
    local -a fresh=( ${GHQ_CACHE_FILE}(Nms-10) )   # 10 分以内に更新済みか
    (( $#fresh )) || ( __ghq_build_list &> /dev/null & )
  fi
  command cat -- "$GHQ_CACHE_FILE"
}

# 手動でキャッシュを作り直す（ghq get 直後など）
ghq-cache-refresh() {
  __ghq_build_list && print "ghq キャッシュを更新しました: $(wc -l < $GHQ_CACHE_FILE | tr -d ' ') 件"
}

# fzf でリポジトリを1つ選んで絶対パスを返す。選ばなければ非 0。
__ghq_select() {
  emulate -L zsh

  if ! command -v fzf >/dev/null 2>&1; then
    print -u2 "fzf が見つかりません: brew install fzf"
    return 1
  fi
  if ! command -v ghq >/dev/null 2>&1; then
    print -u2 "ghq が見つかりません: brew install ghq"
    return 1
  fi

  local header=${1:-'Enter: 選択 / Ctrl-C: キャンセル'}
  local selected
  selected=$(
    __ghq_list_cached \
    | sed "s|^$HOME|~|" \
    | fzf --height=60% --layout=reverse --border \
          --prompt='repo> ' \
          --header="$header" \
          --preview="git -C \$(printf %s {} | sed 's|^~|$HOME|') log --oneline --decorate -15 2>/dev/null || ls -la \$(printf %s {} | sed 's|^~|$HOME|')" \
          --preview-window='right:55%'
  ) || return 1
  [[ -n $selected ]] || return 1

  local dest=${selected/#\~/$HOME}
  if [[ ! -d $dest ]]; then
    # キャッシュが古い（移動・削除済み）
    print -u2 "見つかりません: ${dest/#$HOME/~}（ghq-cache-refresh を実行してください）"
    return 1
  fi
  print -r -- "$dest"
}

# ウィンドウへのジャンプは 700_tmux_jump.zsh の fzf-jump-window（Ctrl-]）に集約した。
# このファイルは候補の供給元（__ghq_list_cached）と clone（repo-get）を担当する。

# 移動せずに cd だけしたいとき用（キーバインドは無し）
fzf-ghq-cd() {
  emulate -L zsh
  local dest
  dest=$(__ghq_select 'Enter: cd / Ctrl-C: キャンセル') || return 0
  cd -- "$dest"
}

# ---------------------------------------------------------------------------
# 新規取得は ghq get ではなく repo-get を使う
#
# ghq get は必ず <root>/<host>/<owner>/<repo> に置く（host を外すオプションは無い）。
# だがここのツリーは ~/PROJECTS/<会社ラベル>/<repo> であり、会社ラベルは GitHub の
# owner 名と一致しない（sumasuma-app → info-box, KDDIsmartdrone-dev → ksd など）。
# URL からは決して導けない情報なので、対応表を持って clone 先を決める。

# GitHub の owner → ~/PROJECTS 配下のディレクトリ名
typeset -gA REPO_GROUP=(
  [apple-world]=appleworld
  [Yamazaki-R-apw]=appleworld
  [sumasuma-app]=info-box
  [KDDIsmartdrone-dev]=ksd
  [mirailabs-co-jp]=mirailabs
  [SoftRoid-Inc]=softroid
  [outarc-inc]=outarc
  [GLIIIM]=gliiim
  [Azure-Samples]=galirage
  [galirage]=galirage
  [ymzkryo]=snail
  [katatsumuri-work]=katatsumuri-work
)

# ディレクトリ名 → clone に使う SSH ホスト（~/.ssh/config のアカウント別エイリアス）
typeset -gA REPO_SSH_HOST=(
  [appleworld]=github.com.appleworld
  [info-box]=github.com.infobox
  [mirailabs]=github.com.mirailabs
)

# repo-get <owner>/<repo> [配置先ディレクトリ名]
#   例) repo-get apple-world/apple-core   → ~/PROJECTS/appleworld/apple-core
#       repo-get ymzkryo/foo dmm          → ~/PROJECTS/dmm/foo
repo-get() {
  emulate -L zsh

  local spec=$1
  if [[ -z $spec ]]; then
    print -u2 "usage: repo-get <owner>/<repo> [group]"
    return 1
  fi

  # URL / host 付き / owner/repo のいずれも受け付けて owner と repo に分解する
  local trimmed=${spec%.git}
  trimmed=${trimmed##*(git@|https://|http://|ssh://git@)}
  trimmed=${trimmed/:/\/}
  local -a parts=( ${(s:/:)trimmed} )
  if (( $#parts < 2 )); then
    print -u2 "owner/repo の形で指定してください: $spec"
    return 1
  fi
  local repo=${parts[-1]} owner=${parts[-2]}

  local group=${2:-${REPO_GROUP[$owner]:-$owner}}
  local host=${REPO_SSH_HOST[$group]:-github.com}
  local dest="$HOME/PROJECTS/$group/$repo"

  if [[ -d $dest ]]; then
    print "既にあります: ${dest/#$HOME/~}"
    cd -- "$dest"
    return 0
  fi

  print "clone: git@${host}:${owner}/${repo}.git → ${dest/#$HOME/~}"
  command git clone "git@${host}:${owner}/${repo}.git" "$dest" || return $?

  __ghq_build_list
  cd -- "$dest"
}

# キーバインドは Ctrl-] のみ（700_tmux_jump.zsh で定義）。
# Ctrl-G は元の list-expand に戻したので、ここでは何も割り当てない。
