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

rust だけは例外で [rustup](https://rustup.rs/) が管理する。mise の `core:rust` は rustup が
存在すると `~/.cargo/bin` へのシンボリックリンクを張るだけでバージョンを固定できないため。
切り替えは `rustup default <version>` を使う。

## Homebrew
[Brewfile](Brewfile) で GUI アプリとシステム寄りのツールを管理する。言語ランタイムや
バージョンを固定したい CLI は mise 側に置く（役割分担は Brewfile の冒頭コメントを参照）。

```bash
brew bundle                                          # Brewfile に従って導入
brew bundle dump --force --formula --cask --tap      # 実態と乖離したら再生成
```

再生成時は種別を絞ること。フラグを付けないと go / cargo / uv / npm のグローバル
パッケージまで書き出され、ローカルの絶対パスを含む行が混ざる。

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
