# peco
function peco-select-history() {
    local tac
    if which tac > /dev/null; then
        tac="tac"
    else
        tac="tail -r"
    fi
    BUFFER=$(\history -n 1 | \
        eval $tac | \
        peco --query "$LBUFFER")
    CURSOR=$#BUFFER
    zle clear-screen
}
zle -N peco-select-history
bindkey '^p' peco-select-history

function peco-git-grep-vim() {
    P=$(git grep -n $1 | peco | awk -F: '{print $1}')
    if [ ${#P} -ne 0 ]; then
        $EDITOR $P;
    fi
}
