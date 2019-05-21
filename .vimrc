syntax on
set encoding=utf-8
set fileencoding=utf-8
set fileformat=unix
set background=dark
colorscheme solarized
set number
set nowritebackup
set nobackup
set noswapfile
set tabstop=4
set shiftwidth=4
set softtabstop=4
set expandtab
set autoindent
set smartindent
filetype plugin indent on
augroup fileTypeIndent
	autocmd!
	autocmd BufRead,BufNewFile *.py setfiletype python
	autocmd BufRead,BufNewFile *.rb setfiletype ruby
	autocmd BufRead,BufNewFile *.php setfiletype php
	autocmd BufRead,BufNewFile *.html setfiletype html
	autocmd BufRead,BufNewFile *.css setfiletype css
	autocmd BufRead,BufNewFile *.go setfiletype go
	autocmd BufRead,BufNewFile *.java setfiletype java
	autocmd BufRead,BufNewFile *.js setfiletype javascript
    autocmd BufRead,BufNewFile *.vue setfiletype vue
augroup END

" 入力モード中に素早くjjと入力した場合はESCとみなす
inoremap jj <Esc>
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
set colorcolumn=80      " その代わり100文字目にラインを入れる
"対応括弧に'<'と'>'のペアを追加
set matchpairs& matchpairs+=<:>

" ノーマルモード時だけ ; と : を入れ替える
noremap ; :
nnoremap : ;
"分割ウィンドウ時に移動を行う設定"
noremap <C-H> <C-W>h
noremap <C-J> <C-W>j
noremap <C-K> <C-W>k
noremap <C-L> <C-W>l

"隠しファイルを表示する"
let NERDTreeShowHidden = 1
" NERDTreeの起動
nnoremap <silent><C-e> :NERDTreeToggle<CR>

"dein Scripts-----------------------------
if &compatible
  set nocompatible               " Be iMproved
endif

" Required:
set runtimepath+=~/.vim/dein/repos/github.com/Shougo/dein.vim

" Required:
if dein#load_state('~/.vim/dein')
  call dein#begin('~/.vim/dein')

  " Let dein manage dein
  " Required:
  call dein#add('~/.vim/dein/repos/github.com/Shougo/dein.vim')

  " Add or remove your plugins here like this:
  "call dein#add('Shougo/neosnippet.vim')
  "call dein#add('Shougo/neosnippet-snippets')
  call dein#add('scrooloose/nerdtree')
  call dein#add('nathanaelkane/vim-indent-guides')
  call dein#add('itchyny/lightline.vim')
  call dein#add('posva/vim-vue')

  " Required:
  call dein#end()
  call dein#save_state()
endif

" Required:
filetype plugin indent on
syntax enable

" If you want to install not installed plugins on startup.
if dein#check_install()
  call dein#install()
endif

"End dein Scripts-------------------------

"引数なしでvimを開いたらNERDTreeを起動、
"引数ありならNERDTreeは起動せず、引数で渡されたファイルを開く。
autocmd vimenter * if !argc() | NERDTree | endif

"他のバッファをすべて閉じた時にNERDTreeが開いていたらNERDTreeも一緒に閉じる。
autocmd bufenter * if (winnr("$") == 1 && exists("b:NERDTree") &&b:NERDTree.isTabTree()) | q | endif

"vimを立ち上げたときに、自動的にvim-indent-guidesをオンにする
let g:indent_guides_enable_on_vim_startup = 1

let g:lightline = {
    \ 'colorscheme': 'solarized'
      \ }
augroup vimrc-auto-mkdir  " {{{
    autocmd!
    autocmd BufWritePre * call s:auto_mkdir(expand('<afile>:p:h'), v:cmdbang)
    function! s:auto_mkdir(dir, force)  " {{{
        if !isdirectory(a:dir) && (a:force ||
                    \    input(printf('"%s" does not exist. Create? [y/N]', a:dir)) =~? '^y\%[es]$')
            call mkdir(iconv(a:dir, &encoding, &termencoding), 'p')
        endif
    endfunction  " }}}
augroup END  " }}}

