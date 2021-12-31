###################################
# custom aliase
###################################

# brewの時、envを使わない
#alias brew="PATH=/usr/local/bin:/usr/local/sbin:/usr/bin:/bin:/usr/sbin:/sbin brew"


# tmux3分割
alias ide="~/.tmux/bin/ide"

# awsp
alias awsp="source _awsp"
alias awsp=aws_profile_update

# 天気
alias wttr='() { curl -H "Accept-Language: ${LANG%_*}" ja.wttr.in/"${1:-Kyoto}" }'
