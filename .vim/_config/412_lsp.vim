let g:lsp_settings = {
\   'pyls-all': {
\     'workspace_config': {
\       'pyls': {
\         'configurationSources': ['flake8']
\       }
\     }
\   },
\}

" terraform
if executable('terraform-lsp')
  au User lsp_setup call lsp#register_server({
    \ 'name': 'terraform-lsp',
    \ 'cmd': {server_info->['terraform-lsp']},
    \ 'whitelist': ['terraform','tf'],
    \ })
endif

" python
if executable('pylsp-all')
    au User lsp_setup call lsp#register_server({
        \ 'name': 'pylsp',
        \ 'cmd': {server_info->['pylsp']},
        \ 'allowlist': ['python'],
        \ 'initialization_options': {
        \     'pylsp': {
        \         'plugins': {
        \             'jedi_definition': {'enabled': v:true},
        \             'flake8': {
        \                 'enabled': v:true,
        \                 'ignore': ['E501'],
        \             }
        \         }
        \     }
        \ },
        \ })
endif
