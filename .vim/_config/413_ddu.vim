"ddu settings.

call ddu#custom#patch_global({
    \   'ui': 'ff',
    \   'sources': [{'name':'file','params':{}},{'name':'mr'},{'name':'register'},{'name':'buffer'}],
    \   'sourceOptions': {
    \     '_': {
    \       'matchers': ['matcher_substring'],
    \     },
    \   },
    \   'kindOptions': {
    \     'file': {
    \       'defaultAction': 'open',
    \     },
    \   },
    \ })

"ddu-key-setting
autocmd FileType ddu-ff call s:ddu_my_settings()
function! s:ddu_my_settings() abort
  nnoremap <buffer><silent> <CR>
        \ <Cmd>call ddu#ui#ff#do_action('itemAction')<CR>
  nnoremap <buffer><silent> <Space>
        \ <Cmd>call ddu#ui#ff#do_action('toggleSelectItem')<CR>
  nnoremap <buffer><silent> i
        \ <Cmd>call ddu#ui#ff#do_action('openFilterWindow')<CR>
  nnoremap <buffer><silent> q
        \ <Cmd>call ddu#ui#ff#do_action('quit')<CR>
endfunction

autocmd FileType ddu-ff-filter call s:ddu_filter_my_settings()
function! s:ddu_filter_my_settings() abort
  nnoremap <buffer> <CR>
  \ <Cmd>call ddu#ui#ff#do_action('itemAction')<CR>
  nnoremap <buffer><silent> q
  \ <Cmd>call ddu#ui#ff#do_action('quit')<CR>
  inoremap <buffer> <CR>
  \ <Cmd>call ddu#ui#ff#do_action('itemAction')<CR>
  inoremap <buffer> <C-j>
  \ <Cmd>call ddu#ui#ff#execute("call cursor(line('.')+1,0)")<CR>
  inoremap <buffer> <C-k>
  \ <Cmd>call ddu#ui#ff#execute("call cursor(line('.')-1,0)")<CR>
endfunction

"ddu keymapping.
nnoremap <SID>[ug] <Nop>
nmap ,u <SID>[ug]

nnoremap <silent> <SID>[ug]m :<C-u>Ddu mr<CR>
nnoremap <silent> <SID>[ug]b :<C-u>Ddu buffer<CR>
nnoremap <silent> <SID>[ug]r :<C-u>Ddu register<CR>
nnoremap <silent> <SID>[ug]n :<C-u>Ddu file -source-param-new -volatile<CR>
nnoremap <silent> <SID>[ug]f :<C-u>Ddu file<CR>
