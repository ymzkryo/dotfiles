function aws_prof() {
  local profile="${AWS_PROFILE:=default}"
  echo "\ue7ad:${profile}"
}
alias awsp=aws_profile_update

function aws_profile_update() {

   PROFILES=$(aws configure list-profiles)
   PROFILES_ARRAY=($(echo $PROFILES))
   SELECTED_PROFILE=$(echo $PROFILES | peco)

   [[ -n ${PROFILES_ARRAY[(re)${SELECTED_PROFILE}]} ]] && export AWS_PROFILE=${SELECTED_PROFILE}; echo 'Updated profile' || echo ''

}
