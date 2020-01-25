# brewの時、envを使わない
alias brew="PATH=/usr/local/bin:/usr/local/sbin:/usr/bin:/bin:/usr/sbin:/sbin brew"

# 年月日別メモファイル作成
alias memo='vim ~/memo/$(date "+%Y/%m/%d.md")'

# gcalcliのtoday-tomorrowを呼び出し
alias gcal='gcalcli agenda now tomorrow'

# ymzk.yamachan@gmai.com
alias homemail="neomutt -F ~/personal.rc"

# yamazaki@dahaland.com
alias workmail="neomutt -F ~/work.rc"
