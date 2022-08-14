###################################
# zsh function
###################################
source ~/.zsh/401_peco.zsh
source ~/.zsh/411_todoist.zsh
source ~/.zsh/412_toggl.zsh
source ~/.zsh/413_awsp.zsh
source ~/.zsh/414_github.zsh

function peco-git-grep {
    P=$(git grep -n $1 | peco | awk -F: '{print $1}')
    if [ ${#P} -ne 0 ]; then
        $EDITOR $P;
    fi
}

