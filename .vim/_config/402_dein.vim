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
  " call dein#add('Shougo/neosnippet.vim')
  " call dein#add('Shougo/neosnippet-snippets')
  if !has('nvim')
    call dein#add('rhysd/vim-healthcheck')
  endif
  call dein#add('aklt/plantuml-syntax')
  call dein#add('prabirshrestha/async.vim')
  call dein#add('prabirshrestha/asyncomplete.vim')
  call dein#add('prabirshrestha/asyncomplete-lsp.vim')
  call dein#add('prabirshrestha/vim-lsp')
  call dein#add('mattn/vim-lsp-settings')
  call dein#add('mattn/vim-sonictemplate')
  call dein#add('jiangmiao/auto-pairs')
  call dein#add('tyru/open-browser.vim')
  " filer
  " call dein#add('preservim/nerdtree')
  " call dein#add('Shougo/defx.nvim')
  " if !has('nvim')
  "   call dein#add('roxma/nvim-yarp')
  "   call dein#add('roxma/vim-hug-neovim-rpc')
  " endif

  call dein#add('Shougo/ddu.vim')
  call dein#add('vim-denops/denops.vim')
  call dein#add('Shougo/ddu-ui-ff')
  call dein#add('Shougo/ddu-source-file')
  call dein#add('Shougo/ddu-source-register')
  call dein#add('kuuote/ddu-source-mr')
  call dein#add('lambdalisue/mr.vim')
  call dein#add('shun/ddu-source-buffer')
  call dein#add('Shougo/ddu-filter-matcher_substring')
  call dein#add('Shougo/ddu-commands.vim')
  call dein#add('Shougo/ddu-kind-file')


  call dein#add('kristijanhusak/defx-git')
  call dein#add('kristijanhusak/defx-icons')
  call dein#add('ryanoasis/vim-devicons')
  " markdown
  call dein#add('godlygeek/tabular')
  call dein#add('plasticboy/vim-markdown')
  call dein#add('previm/previm')
  " prisma
  call dein#add('pantharshit00/vim-prisma')
  " airline
  call dein#add('vim-airline/vim-airline')
  call dein#add('vim-airline/vim-airline-themes')
  " twitter
  call dein#add('twitvim/twitvim')
  " terraform
  call dein#add('hashivim/vim-terraform')
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
