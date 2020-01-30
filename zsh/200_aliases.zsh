###################################
# custom aliase
###################################

# brewの時、envを使わない
alias brew="PATH=/usr/local/bin:/usr/local/sbin:/usr/bin:/bin:/usr/sbin:/sbin brew"

# 年月日別メモファイル作成
alias memo='vim ~/memo/$(date "+%Y/%m/%d.md")'

# gcalcliのtoday-tomorrowを呼び出し
alias gcal='gcalcli agenda now tomorrow'

# tmux3分割
alias ide="~/.tmux/bin/ide"
