function github_current_user() {
  local user_name=`git config user.name`
  echo "\ue709:${user_name}"
}

function gitmain() {
    git config --global user.name "ymzkryo"
    git config --global user.email "ymzk.yamachan@gmail.com"
    source ~/.zshrc
}

function gitambl() {
    git config --global user.name "ryo-yamazaki-p"
    git config --global user.email "ryo.yamazaki.ba@ambl.co.jp"
    source ~/.zshrc
}
