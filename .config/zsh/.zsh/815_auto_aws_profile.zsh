# ~/PROJECTS 配下のディレクトリに応じて AWS_PROFILE を切り替える
#
# 対応表は private リポジトリの 050_work_profiles.zsh が WORK_AWS_PROFILES として定義する。
# 未定義（private を持たないマシン）の場合は何もしない。
function auto_switch_aws_profile() {
    (( ${+WORK_AWS_PROFILES} )) || return

    local matched_profile=""
    local label
    # ~/PROJECTS/<ラベル> の第1階層を取り出して対応表を引く
    if [[ "$PWD" == "$HOME/PROJECTS/"* ]]; then
        label="${${PWD#$HOME/PROJECTS/}%%/*}"
        matched_profile="${WORK_AWS_PROFILES[$label]}"
    fi

    if [[ -n "$matched_profile" ]]; then
        if [[ "$AWS_PROFILE" != "$matched_profile" ]]; then
            export AWS_PROFILE="$matched_profile"
            echo "AWS profile switched to: $matched_profile"
        fi
    elif [[ -n "$AWS_PROFILE" ]]; then
        unset AWS_PROFILE
        echo "AWS profile unset"
    fi
}

# Add to chpwd hook (called when directory changes)
autoload -U add-zsh-hook
add-zsh-hook chpwd auto_switch_aws_profile

# Run on shell start
auto_switch_aws_profile
