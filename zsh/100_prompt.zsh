###################################
# prompt
###################################

#########################
# POWERLEVEL9K_MODE
#########################
POWERLEVEL9K_MODE='nerdfont-complete'

#########################
# POWERLEVEL9K_GENERAL
#########################
POWERLEVEL9K_SHORTEN_DIR_LENGTH=2
POWERLEVEL9K_SHOW_CHANGESET=true
POWERLEVEL9K_PROMPT_ADD_NEWLINE=true
POWERLEVEL9K_PROMPT_ON_NEWLINE=true
POWERLEVEL9K_RPROMPT_ON_NEWLINE=true

#########################
# POWERLEVEL9K_ICON
#########################
POWERLEVEL9K_HOME_ICON="\uf7db"
POWERLEVEL9K_FOLDER_ICON="\ue5ff"
POWERLEVEL9K_ETC_ICON=" \ue5fc"
POWERLEVEL9K_HOST_ICON="\uF109"
POWERLEVEL9K_SSH_ICON="\uF489"
POWERLEVEL9K_VCS_UNTRACKED_ICON='?'

#########################
# POWERLEVEL9K_PREFIX
#########################
POWERLEVEL9K_MULTILINE_LAST_PROMPT_PREFIX="%F{014}\u2570%F{cyan}\uF460%F{073}\uF460%F{109}\uF460%f "
POWERLEVEL9K_MULTILINE_FIRST_PROMPT_PREFIX=""

#########################
# POWERLEVEL9K_LEFT_PROMPT
#########################
POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(os_icon battery dir vcs pyenv)

#########################
# POWERLEVEL9K_RIGHT_PROMPT
#########################
#POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=(status time dir_writable ip)
POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=(status time)

#########################
# POWERLEVEL9K_COLOR
#########################
POWERLEVEL9K_VCS_MODIFIED_BACKGROUND='yellow'
POWERLEVEL9K_VCS_UNTRACKED_BACKGROUND='yellow'

POWERLEVEL9K_VCS_GIT_HOOKS=(vcs-detect-changes git-untracked git-aheadbehind git-remotebranch git-tagname)
POWERLEVEL9K_TIME_FORMAT="%D{\uf455 %Y-%m-%d \uf017 %H:%M:%S}"

#########################
# POWERLEVEL9K_BATTERY
#########################
POWERLEVEL9K_BATTERY_CHARGING='yellow'
POWERLEVEL9K_BATTERY_CHARGED='green'
POWERLEVEL9K_BATTERY_DISCONNECTED='$DEFAULT_COLOR'
POWERLEVEL9K_BATTERY_LOW_THRESHOLD='10'
POWERLEVEL9K_BATTERY_LOW_COLOR='red'
POWERLEVEL9K_BATTERY_ICON='\uf1e6 '
