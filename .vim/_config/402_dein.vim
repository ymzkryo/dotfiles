"dein Scripts-----------------------------
if &compatible
  set nocompatible               " Be iMproved
endif

" Required:
set runtimepath+=~/.vim/.cache/dein/repos/github.com/Shougo/dein.vim

" Required:
if dein#load_state('~/.vim/.cache/dein')
  call dein#begin('~/.vim/.cache/dein')

  " Let dein manage dein
  " Required:
  call dein#add('~/.vim/.cache/dein/repos/github.com/Shougo/dein.vim')

  " Add or remove your plugins here like this:
  " vim-lsp
  call dein#add('prabirshrestha/vim-lsp')
  call dein#add('mattn/vim-lsp-settings')
  call dein#add('prabirshrestha/async.vim')
  call dein#add('prabirshrestha/asyncomplete.vim')
  call dein#add('prabirshrestha/asyncomplete-lsp.vim')
  " template
  call dein#add('mattn/vim-sonictemplate')
  " auto input
  call dein#add('jiangmiao/auto-pairs')
  " filer
  call dein#add('mattn/vim-molder')
  call dein#add('mattn/vim-molder-operations')
  call dein#add('mattn/ctrlp-matchfuzzy')
  " markdown
  call dein#add('previm/previm')
  call dein#add('tyru/open-browser.vim')
  " airline
  call dein#add('vim-airline/vim-airline')
  call dein#add('vim-airline/vim-airline-themes')
  call dein#add('ryanoasis/vim-devicons')
  call dein#add('tpope/vim-fugitive')
  " syntax
  call dein#add('hashivim/vim-terraform')
  call dein#add('aklt/plantuml-syntax')
  " git
  call dein#add('airblade/vim-gitgutter')
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

call map(dein#check_clean(), "delete(v:val, 'rf')")
"End dein Scripts-------------------------
