let g:ctrlp_match_func = {'match': 'ctrlp_matchfuzzy#matcher'}

" マッチウインドウの設定. 「下部に表示, 大きさ20行で固定, 検索結果100件」
let g:ctrlp_match_window = 'order:ttb,min:20,max:20,results:100'
" .(ドット)から始まるファイルも検索対象にする
let g:ctrlp_show_hidden = 1
"ファイル検索のみ使用
let g:ctrlp_types = ['fil']
