" ja 連携 - 選択範囲またはファイル全体を日本語へ翻訳する
"
" 非破壊(通常こちらを使う):
"   :Ja              ファイル全体を翻訳して別ウィンドウに表示
"   :'<,'>Ja         選択範囲を翻訳して別ウィンドウに表示
"   :%Ja             :Ja と同じ
"   <leader>ja       ノーマル: ファイル全体 / ビジュアル: 選択範囲
"
" 破壊的(キーバインドは割り当てない。範囲の既定もカーソル行だけ):
"   :'<,'>JaReplace  選択範囲を翻訳結果で置き換える
"   :%JaReplace      ファイル全体を置き換える
"
" 非破壊側は getline() で読むだけでバッファへ書き込まないので、
" 元バッファの modified 状態も undo 履歴も変化しない。
"
" 結果ウィンドウは buftype=nofile の使い捨てバッファ。q で閉じる。
" 読みやすさのために色を付けたいときは結果ウィンドウで :setf markdown など。
"
" 翻訳中は Vim が固まる(system() が同期実行のため)。man ページ規模だと数十秒かかる。
"
" 【注意】翻訳対象はクラウドへ送信される。dotfiles の README の
"         「ja / jman のセキュリティとプライバシー」を参照。

if exists('g:loaded_ja')
  finish
endif
let g:loaded_ja = 1

" バックエンドを差し替えたいとき用(例: let g:ja_command = 'JA_MODEL=... ja')
let g:ja_command = get(g:, 'ja_command', 'ja')

let s:ja_seq = 0

" 行のリストを翻訳する。
" 返り値: {'status': 終了コード, 'lines': 翻訳結果の行, 'error': stderr の内容}
function! s:ja_run(lines) abort
  " ja は成功時 stderr に何も出さないが、バックエンドが警告を出す可能性があるので
  " stdout と混ざらないよう stderr は別ファイルへ逃がす。
  let l:errfile = tempname()
  let l:input = join(a:lines, "\n") . "\n"

  echo 'ja: 翻訳中...'
  redraw

  let l:out = system(g:ja_command . ' 2> ' . shellescape(l:errfile), l:input)
  let l:status = v:shell_error
  let l:err = filereadable(l:errfile) ? join(readfile(l:errfile), "\n") : ''
  call delete(l:errfile)

  let l:lines = split(l:out, "\n", 1)
  " system() の出力末尾の改行が空行として残るので落とす
  if len(l:lines) > 1 && l:lines[-1] ==# ''
    call remove(l:lines, -1)
  endif

  return {'status': l:status, 'lines': l:lines, 'error': l:err}
endfunction

function! s:ja_error(res) abort
  redraw
  echohl ErrorMsg
  echomsg 'ja: 翻訳に失敗しました (exit ' . a:res.status . ')'
  for l:line in split(a:res.error, "\n")
    echomsg 'ja: ' . l:line
  endfor
  echohl NONE
endfunction

" 翻訳結果を使い捨てバッファへ表示する(元バッファには触れない)
function! s:ja_show(lines) abort
  let s:ja_seq += 1
  botright new
  setlocal buftype=nofile bufhidden=wipe noswapfile nobuflisted nomodeline
  silent execute 'keepalt file ' . fnameescape('[ja ' . s:ja_seq . ']')
  call setline(1, a:lines)
  setlocal nomodified nomodifiable
  nnoremap <silent> <buffer> q <C-w>c
  normal! gg
endfunction

function! s:ja_view(line1, line2) abort
  let l:res = s:ja_run(getline(a:line1, a:line2))
  if l:res.status != 0
    call s:ja_error(l:res)
    return
  endif
  if empty(l:res.lines) || (len(l:res.lines) == 1 && l:res.lines[0] ==# '')
    redraw
    echomsg 'ja: 翻訳結果が空でした'
    return
  endif
  call s:ja_show(l:res.lines)
endfunction

function! s:ja_replace(line1, line2) abort
  if !&modifiable
    echohl ErrorMsg | echomsg 'ja: このバッファは変更できません' | echohl NONE
    return
  endif

  let l:res = s:ja_run(getline(a:line1, a:line2))
  if l:res.status != 0
    call s:ja_error(l:res)
    return
  endif
  if empty(l:res.lines) || (len(l:res.lines) == 1 && l:res.lines[0] ==# '')
    redraw
    echohl ErrorMsg | echomsg 'ja: 翻訳結果が空だったので置換しませんでした' | echohl NONE
    return
  endif

  let l:view = winsaveview()
  silent execute a:line1 . ',' . a:line2 . 'delete _'
  " 削除と挿入で undo が 2 段になるのを防ぐ
  try
    undojoin
  catch /^Vim\%((\a\+)\)\=:E790:/
  endtry
  call append(a:line1 - 1, l:res.lines)
  call winrestview(l:view)
  redraw
  echomsg 'ja: ' . len(l:res.lines) . ' 行に置換しました'
endfunction

command! -range=% -bar Ja        call s:ja_view(<line1>, <line2>)
command! -range   -bar JaReplace call s:ja_replace(<line1>, <line2>)

nnoremap <silent> <leader>ja :<C-u>%Ja<CR>
xnoremap <silent> <leader>ja :Ja<CR>
