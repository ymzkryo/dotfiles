# alias awsp=aws_profile_update
# 
# function aws_profile_update() {
# 
#    PROFILES=$(aws configure list-profiles)
#    PROFILES_ARRAY=($(echo $PROFILES))
#    SELECTED_PROFILE=$(echo $PROFILES | peco)
# 
#    [[ -n ${PROFILES_ARRAY[(re)${SELECTED_PROFILE}]} ]] && export AWS_PROFILE=${SELECTED_PROFILE}; echo 'Updated profile' || echo ''
# }

# function awsp() {
#   if [ $# -ge 1 ]; then
#     export AWS_PROFILE="$1"
#     echo "Set AWS_PROFILE=$AWS_PROFILE."
#   else
#     source _awsp
#   fi
#   if [ "$AWS_PROFILE" != "" ]; then
#     export AWS_DEFAULT_PROFILE=$AWS_PROFILE
#   else
#     unset AWS_DEFAULT_PROFILE
#   fi
# }

function aws_prof() {
  local profile="${AWS_PROFILE:=default}"
  echo "\ue7ad:${profile}"
}
