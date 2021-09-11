###################################
# custom aliase
###################################

# brewの時、envを使わない
#alias brew="PATH=/usr/local/bin:/usr/local/sbin:/usr/bin:/bin:/usr/sbin:/sbin brew"

alias awsp=aws_profile_update

# 年月日別メモファイル作成
alias memo='vim ~/memo/$(date "+%Y/%m/%d.md")'

# gcalcliのtoday-tomorrowを呼び出し
alias gcal='gcalcli agenda now tomorrow'

# tmux3分割
alias ide="~/.tmux/bin/ide"

# AirPodsPros接続
alias airp="BluetoothConnector --connect e4-76-84-3a-6a-7e --notify"

# AirPodsPro接続解除
alias airpd="BluetoothConnector --disconnect e4-76-84-3a-6a-7e --notify"

# AirPorsPro接続確認
alias airpc="BluetoothConnector --status e4-76-84-3a-6a-7e --notify"

# awsp
alias awsp="source _awsp"

# todoistで今日のタスク取得
alias ttoday="todoist --color list --filter '(overdue | today)'"

# 天気
alias wttr='() { curl -H "Accept-Language: ${LANG%_*}" ja.wttr.in/"${1:-Kyoto}" }'
