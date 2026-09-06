# jman - man ページを日本語に翻訳して読む
#
#   jman git-rebase
#   jman 3 printf
#   jman -a signal
#
# 概念的には `man "$@" | col -bx | ja | less -R`。
#
# GROFF_NO_SGR=1 を付けるのは、パイプ時に ANSI エスケープではなく
# オーバーストライク(文字+BS+文字)で出させるため。それを col -bx が取り除くので、
# 端末制御文字が翻訳側へ流れない。
#
# 【注意】man ページ全体を翻訳するので入力が大きい。git-rebase(1) で約 64KB あり、
#         その分だけ待ち時間とクラウドへの送信量が増える。一部だけ読みたいときは
#           man git-rebase | col -bx | sed -n '/^INTERACTIVE/,/^SPLITTING/p' | ja | less -R
#         のように自分でパイプを組むほうが速い。
#
# 【注意】man の内容はクラウドへ送信される。詳細は dotfiles の README を参照。
jman() {
  emulate -L zsh
  setopt local_options pipe_fail

  if (( $# == 0 )); then
    print -ru2 -- 'jman: 使い方: jman <man と同じ引数...>   例: jman git-rebase'
    return 64
  fi

  # man を先に走らせて成否を確定させる。失敗時は less を開かずに抜ける。
  # man 自身のエラー( No manual entry for ... )は stderr のまま端末へ出す。
  local page
  page=$(GROFF_NO_SGR=1 command man "$@" | col -bx)
  local man_status=$?
  if (( man_status != 0 )); then
    return $man_status
  fi
  if [[ -z $page ]]; then
    print -ru2 -- "jman: man の出力が空でした: $*"
    return 1
  fi

  print -ru2 -- "jman: 翻訳中 (${#page} 文字)..."

  # 翻訳が失敗したら pager を開かずに ja の終了コードを返す。
  local translated
  translated=$(print -r -- "$page" | ja) || return $?

  print -r -- "$translated" | less -R
}
