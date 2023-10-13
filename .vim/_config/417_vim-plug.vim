" vim-plug settings
" ==================
call plug#begin()
  " lsp
  Plug 'prabirshrestha/vim-lsp'
  Plug 'mattn/vim-lsp-settings'
  Plug 'prabirshrestha/async.vim'
  Plug 'prabirshrestha/asyncomplete.vim'
  Plug 'prabirshrestha/asyncomplete-lsp.vim'
  " template
  Plug 'mattn/vim-sonictemplate'
  " auto input
  Plug 'jiangmiao/auto-pairs'
  " filer
  Plug 'mattn/vim-molder'
  Plug 'mattn/vim-molder-operations'
  Plug 'mattn/ctrlp-matchfuzzy'
  " markdown
  Plug 'previm/previm'
  Plug 'tyru/open-browser.vim'
  Plug 'plasticboy/vim-markdown'
  " airline
  Plug 'vim-airline/vim-airline'
  Plug 'vim-airline/vim-airline-themes'
  Plug 'ryanoasis/vim-devicons'
  Plug 'tpope/vim-fugitive'
  " syntax
  Plug 'hashivim/vim-terraform'
  Plug 'aklt/plantuml-syntax'
  " git
  Plug 'airblade/vim-gitgutter'
  " copilot
  Plug 'github/copilot.vim'
  " chatgpt
  Plug 'mattn/vim-chatgpt'
call plug#end()
