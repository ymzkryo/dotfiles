" Himalaya 実行ファイルと設定パスを明示
let g:himalaya_executable   = '/Users/ymzkryo/himalaya/target/release/himalaya'
let g:himalaya_config_path  = '~/.config/himalaya/config.toml'
set encoding=utf-8
set fileencodings=utf-8

" multiple accounts 対応
function! SwitchHimalaya(account)
  " himalaya-vim は `himalaya <subcommand>` を組み立てるので、
  " `--account` は `g:himalaya_args` に入れる必要がある！
  let g:himalaya_args = ['--account', a:account]
  echo "Switched to account: " . a:account
endfunction

command! -nargs=1 HimalayaUse call SwitchHimalaya(<f-args>)
