###################################
# sachaos/toggl function
###################################

function toggl-start-todoist () {
    local selected_item_id=`todoist --project-namespace --namespace list | peco | cut -d ' ' -f 1`
    if [ ! -n "$selected_item_id" ]; then
        return 0
    fi
    local selected_item_content=`todoist --csv show ${selected_item_id} | grep Content | cut -d',' -f2- | sed s/\"//g`
    if [ -n "$selected_item_content" ]; then
        BUFFER="toggl start \"${selected_item_content}\""
        CURSOR=$#BUFFER
        zle accept-line
    fi
}
zle -N toggl-start-todoist
bindkey '^xts' toggl-start-todoist

function toggl_current() {
  local tgc=$(toggl --cache --csv current)
  local tgc_time=$(echo $tgc | grep Duration | cut -d ',' -f 2)
  local tgc_dsc=$(echo $tgc | grep Description | cut -d ',' -f 2 | cut -c 1-20)
  local short_tgc_dsc=$(if [ $(echo $tgc_dsc | wc -m) -lt 20 ]; then echo $tgc_dsc; else echo "${tgc_dsc}.."; fi)
  if [ ! -n "$tgc_time" ]; then
      echo "\ufa1d:NoTimeEntry"
  else
      echo "\uf608:[$tgc_time $short_tgc_dsc]"
  fi
}
