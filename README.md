dotfiles
========

Usage:
------

### Update submodule

```bash
git submodule update --remote private
git add private
git commit -m "Update: private submodule"
```

Requirements:
-------------

## Version manager
[mise](https://mise.jdx.dev/)

ツールのバージョンは以下で管理する。

- グローバル: `.config/mise/config.toml`
- プロジェクト個別: 各リポジトリの `mise.toml`

```bash
mise install          # 設定に従ってツールを導入
mise ls               # 導入済みのバージョンを確認
mise use -g node@24   # グローバルのバージョンを変更
```

## Terminal
[wezterm](https://wezfurlong.org/wezterm/index.html)
[tmux](https://github.com/tmux/tmux)

## Editor
[Vim](https://github.com/vim/vim)

## zsh + zinit
[zinit](https://github.com/zdharma-continuum/zinit)

## starship
[starship](https://starship.rs)

## Todist
[chaosteil/doist](https://github.com/chaosteil/doist)

## toggl
[watercooler-labs/toggl-cli](https://github.com/watercooler-labs/toggl-cli)

## memo
[mattn/memo](https://github.com/mattn/memo)

## others
[powerline-extra-symbols ](https://github.com/ryanoasis/powerline-extra-symbols)
[nerd-fonts](https://www.nerdfonts.com/cheat-sheet)


Screenshots:
------------
![screenshot](screenshot/2025-01-14_dotfiles.png)

Install:
--------

TBD

Author:
-------

ymzkryo
