# ~/PROJECTS 配下のディレクトリに応じて Claude Code のアカウント
# （CLAUDE_CONFIG_DIR）を切り替える
#
# 対応表は private リポジトリの 050_work_profiles.zsh が WORK_CLAUDE_PROFILES として定義する。
# 対応表に無いディレクトリではデフォルト（~/.claude）に戻す。
function auto_switch_claude_profile() {
    (( ${+WORK_CLAUDE_PROFILES} )) || return

    local matched_config=""
    local label
    # ~/PROJECTS/<ラベル> の第1階層を取り出して対応表を引く
    if [[ "$PWD" == "$HOME/PROJECTS/"* ]]; then
        label="${${PWD#$HOME/PROJECTS/}%%/*}"
        matched_config="${WORK_CLAUDE_PROFILES[$label]}"
    fi

    # 環境変数は claude 起動時に評価されるため、実行中のセッションには影響しない
    if [[ -n "$matched_config" ]]; then
        if [[ "$CLAUDE_CONFIG_DIR" != "$matched_config" ]]; then
            export CLAUDE_CONFIG_DIR="$matched_config"
            echo "Claude account switched to: ${${matched_config:t}#.claude-}"
        fi
    elif [[ -n "$CLAUDE_CONFIG_DIR" ]]; then
        unset CLAUDE_CONFIG_DIR
        echo "Claude account switched to: default"
    fi
}

# Add to chpwd hook (called when directory changes)
autoload -U add-zsh-hook
add-zsh-hook chpwd auto_switch_claude_profile

# Run on shell start
auto_switch_claude_profile
