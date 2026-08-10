fixbridge() {
  local dev=bridge100
  local ip
  ip=$(ifconfig "$dev" 2>/dev/null | awk '/inet /{print $2; exit}')
  [ -z "$ip" ] && { echo "$dev に inet なし（Parallels未起動？）"; return 1; }
  local net="${ip%.*}.0/24"
  sudo route -n delete -net "$net" 2>/dev/null
  sudo route -n add -net "$net" -interface "$dev"
  route -n get "${ip%.*}.3" | grep -E 'interface|flags'
}
