"バックスペースでなんでも消せるようにする
set backspace=indent,eol,start
set infercase           " 補完時に大文字小文字を区別しない
set virtualedit=all     " カーソルを文字が存在しない部分でも動けるようにする
set hidden              " バッファを閉じる代わりに隠す（Undo履歴を残すため）
set switchbuf=useopen   " 新しく開く代わりにすでに開いてあるバッファを開く
set showmatch           " 対応する括弧などをハイライト表示する
set matchtime=3         " 対応括弧のハイライト表示を3秒にする
set wrap                " 長いテキストの折り返し
set textwidth=0         " 自動的に改行が入るのを無効化
set colorcolumn=100      " その代わり100文字目にラインを入れる
"対応括弧に'<'と'>'のペアを追加
set matchpairs& matchpairs+=<:>

let g:lsp_diagnostics_echo_cursor = 1
