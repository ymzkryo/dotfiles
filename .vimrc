runtime! _config/*.vim

syntax on
set encoding=utf-8
set fileencoding=utf-8
set fileformat=unix
set background=dark
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
set clipboard+=unnamed

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
