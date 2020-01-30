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
    autocmd BufNewFile,BufRead *.twig set filetype=htmljinja
augroup END

