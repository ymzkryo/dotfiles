#!/bin/bash

set -e

DOTFILES_DIR=$(cd "$(dirname "$0")" && pwd)
TARGET_DIR="$HOME"

# デフォルト設定
CONFIG_METHOD="individual"  # デフォルトは個別リンク

# コマンドライン引数の解析
while [[ $# -gt 0 ]]; do
  case $1 in
    --help|-h)
      show_usage
      exit 0
      ;;
    --config-method=*)
      CONFIG_METHOD="${1#*=}"
      shift
      ;;
    --config-method)
      CONFIG_METHOD="$2"
      shift 2
      ;;
    *)
      shift
      ;;
  esac
done

# 設定値の検証
if [[ "$CONFIG_METHOD" != "individual" && "$CONFIG_METHOD" != "whole" ]]; then
  log_error "無効なCONFIG_METHOD: $CONFIG_METHOD"
  log_info "有効な値: 'individual' または 'whole'"
  show_usage
  exit 1
fi

# OSの検出
OS="unknown"
if [[ "$OSTYPE" == "darwin"* ]]; then
  OS="macos"
elif [[ -f /etc/arch-release ]]; then
  OS="arch"
elif [[ -f /etc/debian_version ]]; then
  OS="debian"
elif [[ -f /etc/redhat-release ]]; then
  OS="redhat"
elif [[ "$(uname -r)" == *Microsoft* || "$(uname -r)" == *microsoft* ]]; then
  OS="wsl"
elif [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" ]]; then
  OS="windows"
fi

# テキストカラー設定
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# ログ出力関数
log_info() {
  echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
  echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warn() {
  echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
  echo -e "${RED}[ERROR]${NC} $1"
}

# パッケージマネージャーのインストール確認と設定
setup_package_manager() {
  case "$OS" in
    macos)
      log_info "macOS用のパッケージマネージャー(Homebrew)の設定中..."
      if ! command -v brew &>/dev/null; then
        log_warn "Homebrewがインストールされていません。インストールします..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        
        # Homebrewのパスを追加
        if [[ -f ~/.zshrc ]]; then
          echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zshrc
          eval "$(/opt/homebrew/bin/brew shellenv)"
        fi
        
        log_success "Homebrewのインストールが完了しました"
      else
        log_success "Homebrewは既にインストールされています"
      fi
      ;;
      
    arch)
      log_info "Arch Linux用のパッケージマネージャー(pacman)の確認中..."
      if ! command -v pacman &>/dev/null; then
        log_error "pacmanが見つかりません。Arch Linuxのシステム自体に問題がある可能性があります。"
        exit 1
      else
        log_success "pacmanは既にインストールされています"
        log_info "システムを更新中..."
        sudo pacman -Syu --noconfirm
      fi
      ;;

    debian|wsl)
      log_info "Debian/Ubuntu/WSLのパッケージマネージャーの確認中..."
      if ! command -v apt-get &>/dev/null; then
        log_error "apt-getが見つかりません。システム自体に問題がある可能性があります。"
        exit 1
      else
        log_success "apt-getは既にインストールされています"
        log_info "システムを更新中..."
        sudo apt-get update && sudo apt-get upgrade -y
      fi
      ;;

    windows)
      log_info "Windows用のパッケージマネージャー(Scoop)の確認中..."
      if ! command -v scoop &>/dev/null; then
        log_warn "Scoopがインストールされていません。インストールします..."
        powershell.exe -Command "Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Force"
        powershell.exe -Command "iwr -useb get.scoop.sh | iex"
        log_info "Scoopをインストールしました。バックグラウンドに切り替わるため、インストール完了後に再度スクリプトを実行してください。"
        exit 0
      else
        log_success "Scoopは既にインストールされています"
        
        # Gitが必要
        if ! command -v git &>/dev/null; then
          log_info "Gitをインストールします..."
          scoop install git
        fi
      fi
      ;;
      
    *)
      log_warn "未サポートのOS($OS)です。基本的な設定のみ行います。"
      ;;
  esac
}

# 必要なパッケージのインストール
install_packages() {
  case "$OS" in
    macos)
      log_info "Brewfileからパッケージをインストール中..."
      cd "$DOTFILES_DIR"
      brew bundle
      log_success "Brewパッケージのインストールが完了しました"
      ;;
      
    arch)
      log_info "Arch Linux用パッケージをインストール中..."
      sudo pacman -S --needed --noconfirm \
        zsh tmux vim git curl wget \
        python python-pip \
        base-devel jq tree graphviz \
        newsboat plantuml
        
      # yayがインストールされていなければインストール
      if ! command -v yay &>/dev/null; then
        log_info "AURヘルパー(yay)をインストール中..."
        git clone https://aur.archlinux.org/yay.git /tmp/yay
        cd /tmp/yay
        makepkg -si --noconfirm
        cd -
        rm -rf /tmp/yay
        log_success "yayのインストールが完了しました"
      fi
      
      # AURパッケージのインストール
      log_info "AURパッケージをインストール中..."
      yay -S --needed --noconfirm \
        asdf-vm starship
        
      log_success "Archパッケージのインストールが完了しました"
      ;;

    debian|wsl)
      log_info "Debian/Ubuntu/WSL用パッケージをインストール中..."
      sudo apt-get install -y \
        zsh tmux vim git curl wget \
        python3 python3-pip \
        build-essential jq tree graphviz \
        newsboat
      
      # Starshipのインストール
      log_info "Starshipをインストール中..."
      curl -sS https://starship.rs/install.sh | sh -s -- -y
      
      # asdfのインストール
      if [ ! -d "$HOME/.asdf" ]; then
        log_info "asdfをインストール中..."
        git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch v0.11.3
      fi
      
      log_success "Debian/Ubuntuパッケージのインストールが完了しました"
      ;;

    windows)
      log_info "Windows用パッケージをインストール中(Scoop)..."
      scoop bucket add extras
      scoop bucket add nerd-fonts
      
      scoop install \
        zsh git curl wget \
        python vim neovim \
        jq grep tree \
        starship
      
      # WSLのセットアップ推奨
      log_warn "WSLをセットアップすることをお勧めします。WSLでこのスクリプトを実行することでより良い環境が構築できます。"
      log_info "WSLのインストール方法: powershell.exe -Command \"wsl --install\""
      
      log_success "Windowsパッケージのインストールが完了しました"
      ;;
      
    *)
      log_warn "未サポートのOSのため、パッケージのインストールをスキップします。必要なパッケージは手動でインストールしてください。"
      ;;
  esac
}

# シンボリックリンクを作成する関数
create_symlink() {
  local src="$1"
  local dst="$2"
  
  # ソースが存在するかチェック
  if [ ! -e "$src" ]; then
    log_warn "ソースが存在しません: $src"
    return
  fi
  
  if [ -e "$dst" ]; then
    if [ -L "$dst" ]; then
      log_warn "シンボリックリンクが既に存在します: $dst"
      return
    else
      log_warn "既存のファイルを検出: $dst"
      mv "$dst" "${dst}.backup"
      log_info "既存のファイルをバックアップしました: ${dst}.backup"
    fi
  fi
  
  # 親ディレクトリを確認し、存在しなければ作成
  mkdir -p "$(dirname "$dst")"
  
  ln -sf "$src" "$dst"
  log_success "シンボリックリンクを作成しました: $dst -> $src"
}

# Windowsの場合のシンボリックリンク作成（msys環境やcygwin環境用）
create_windows_symlink() {
  local src="$1"
  local dst="$2"
  
  # ソースが存在するかチェック
  if [ ! -e "$src" ]; then
    log_warn "ソースが存在しません: $src"
    return
  fi
  
  if [ -e "$dst" ]; then
    log_warn "既存のファイルを検出: $dst"
    mv "$dst" "${dst}.backup"
    log_info "既存のファイルをバックアップしました: ${dst}.backup"
  fi
  
  # 親ディレクトリを確認し、存在しなければ作成
  mkdir -p "$(dirname "$dst")"
  
  # Windowsコマンドを使用してシンボリックリンクを作成
  if [ -d "$src" ]; then
    cmd.exe /c "mklink /D \"$(cygpath -w "$dst")\" \"$(cygpath -w "$src")\"" > /dev/null
  else
    cmd.exe /c "mklink \"$(cygpath -w "$dst")\" \"$(cygpath -w "$src")\"" > /dev/null
  fi
  
  log_success "Windowsシンボリックリンクを作成しました: $dst -> $src"
}

# 設定ファイルのシンボリックリンクを作成
setup_symlinks() {
  log_info "設定ファイルのシンボリックリンクを作成中..."
  
  # Windows固有の処理
  if [ "$OS" = "windows" ]; then
    log_info "Windows環境用のシンボリックリンクを作成中..."
    
    # Windowsでのホームディレクトリを取得
    WINDOWS_HOME=$(cygpath -w "$HOME")
    
    # Windows用の設定ファイル
    create_windows_symlink "$DOTFILES_DIR/.vimrc" "$TARGET_DIR/.vimrc"
    create_windows_symlink "$DOTFILES_DIR/.gitconfig" "$TARGET_DIR/.gitconfig"
    
    # Windowsの場合はVim設定をNeovim用にもコピー
    mkdir -p "$TARGET_DIR/AppData/Local/nvim"
    create_windows_symlink "$DOTFILES_DIR/.vimrc" "$TARGET_DIR/AppData/Local/nvim/init.vim"
    
    # テンプレートディレクトリ
    mkdir -p "$TARGET_DIR/.local/share"
    create_windows_symlink "$DOTFILES_DIR/template" "$TARGET_DIR/.local/share/template"
    
    log_info "Windowsでの設定は制限がありますが、基本的なシンボリックリンクを作成しました"
    return
  fi
  
  # UNIX系システム共通の処理
  # ドットファイルのシンボリックリンク
  create_symlink "$DOTFILES_DIR/.vimrc" "$TARGET_DIR/.vimrc"
  create_symlink "$DOTFILES_DIR/.tmux.conf" "$TARGET_DIR/.tmux.conf"
  create_symlink "$DOTFILES_DIR/.gitconfig" "$TARGET_DIR/.gitconfig"
  
  # ディレクトリのシンボリックリンク
  mkdir -p "$TARGET_DIR/.vim"
  mkdir -p "$TARGET_DIR/.tmux"
  mkdir -p "$TARGET_DIR/.newsboat"
  mkdir -p "$TARGET_DIR/.config"
  
  # Vimの設定
  create_symlink "$DOTFILES_DIR/.vim/_config" "$TARGET_DIR/.vim/_config"
  create_symlink "$DOTFILES_DIR/.vim/colors" "$TARGET_DIR/.vim/colors"
  
  # tmuxの設定
  create_symlink "$DOTFILES_DIR/.tmux/bin" "$TARGET_DIR/.tmux/bin"
  
  # newboatの設定
  create_symlink "$DOTFILES_DIR/.newsboat/config" "$TARGET_DIR/.newsboat/config"
  create_symlink "$DOTFILES_DIR/.newsboat/urls" "$TARGET_DIR/.newsboat/urls"
  
  # .configディレクトリの設定
  log_info ".configディレクトリの設定をリンク中..."

  # CONFIG_METHODの値は起動時のコマンドライン引数で設定済み
  # "individual"(個別ファイル) または "whole"(ディレクトリ全体)

  if [ "$CONFIG_METHOD" = "whole" ]; then
    # .configディレクトリ全体をリンクする方法
    # 既存の.configディレクトリが存在し、シンボリックリンクでない場合はバックアップ
    if [ -d "$TARGET_DIR/.config" ] && [ ! -L "$TARGET_DIR/.config" ]; then
      log_warn "既存の.configディレクトリを検出しました"
      mv "$TARGET_DIR/.config" "$TARGET_DIR/.config.backup"
      log_info "既存の.configディレクトリをバックアップしました: .config.backup"
    fi
    
    # ディレクトリ全体のシンボリックリンクを作成
    rm -rf "$TARGET_DIR/.config"
    create_symlink "$DOTFILES_DIR/.config" "$TARGET_DIR/.config"
    log_success ".configディレクトリ全体をリンクしました"
  else
    # 個別のファイルとディレクトリをリンクする方法
    
    # starshipの設定
    if [ -d "$DOTFILES_DIR/.config/starship" ]; then
      mkdir -p "$TARGET_DIR/.config/starship"
      create_symlink "$DOTFILES_DIR/.config/starship/starship.toml" "$TARGET_DIR/.config/starship/starship.toml"
      log_success "starshipの設定をリンクしました"
    fi
    
    # neomuttの設定
    if [ -d "$DOTFILES_DIR/.config/neomutt" ]; then
      mkdir -p "$TARGET_DIR/.config/neomutt"
      for file in "$DOTFILES_DIR/.config/neomutt"/*; do
        if [ -f "$file" ]; then
          basename=$(basename "$file")
          create_symlink "$file" "$TARGET_DIR/.config/neomutt/$basename"
        fi
      done
      log_success "neomuttの設定をリンクしました"
    fi
    
    # その他の.config以下のディレクトリを自動的にリンク
    for dir in "$DOTFILES_DIR/.config"/*; do
      if [ -d "$dir" ] && [ "$(basename "$dir")" != "starship" ] && [ "$(basename "$dir")" != "neomutt" ]; then
        dirname=$(basename "$dir")
        mkdir -p "$TARGET_DIR/.config/$dirname"
        log_info "その他の設定ディレクトリをリンク中: $dirname"
        
        # ディレクトリ内のファイルをリンク
        for file in "$dir"/*; do
          if [ -f "$file" ]; then
            basename=$(basename "$file")
            create_symlink "$file" "$TARGET_DIR/.config/$dirname/$basename"
          fi
        done
      fi
    done
  fi
  
  # Neovimの設定（存在する場合）
  if command -v nvim &>/dev/null; then
    mkdir -p "$TARGET_DIR/.config/nvim"
    create_symlink "$DOTFILES_DIR/.vimrc" "$TARGET_DIR/.config/nvim/init.vim"
  fi
  
  # テンプレートディレクトリ
  mkdir -p "$TARGET_DIR/.local/share"
  create_symlink "$DOTFILES_DIR/template" "$TARGET_DIR/.local/share/template"
}

# 追加ツールのインストール
install_additional_tools() {
  log_info "追加ツールのインストール中..."
  
  # Windowsの場合は一部ツールのインストールをスキップ
  if [ "$OS" = "windows" ]; then
    # Windows用のminimal設定
    if [ ! -f "$HOME/.zshrc" ]; then
      log_info "Windows用の基本的な.zshrcを作成中..."
      cat > "$HOME/.zshrc" << 'EOL'
# Starship
eval "$(starship init zsh)"

# PATH設定
export PATH="$HOME/.local/bin:$PATH"

# 基本エイリアス
alias ll='ls -la'
alias la='ls -a'
alias vi='vim'
EOL
      log_success "Windowsで使える.zshrcを作成しました"
    fi
    return
  fi
  
  # Zinitのインストール
  if [ ! -d "$HOME/.zinit" ]; then
    log_info "Zinitのインストール中..."
    mkdir -p "$HOME/.zinit"
    git clone https://github.com/zdharma-continuum/zinit.git "$HOME/.zinit/bin"
    log_success "Zinitのインストールが完了しました"
  else
    log_success "Zinitは既にインストールされています"
  fi
  
  # Starshipのインストール（OS固有パッケージマネージャー以外の方法）
  if ! command -v starship &>/dev/null; then
    log_info "Starshipのインストール中..."
    curl -sS https://starship.rs/install.sh | sh
    log_success "Starshipのインストールが完了しました"
  else
    log_success "Starshipは既にインストールされています"
  fi
  
  # .zshrcが存在しない場合、基本的な.zshrcを作成
  if [ ! -f "$HOME/.zshrc" ]; then
    log_info "基本的な.zshrcを作成中..."
    
    # OS別の設定
    case "$OS" in
      macos)
        cat > "$HOME/.zshrc" << 'EOL'
# Zinit
source "$HOME/.zinit/bin/zinit.zsh"

# Starship
eval "$(starship init zsh)"

# PATH設定
export PATH="$HOME/.local/bin:$PATH"

# Homebrew
eval "$(/opt/homebrew/bin/brew shellenv)"

# asdf (macOS)
. $(brew --prefix asdf)/libexec/asdf.sh

# 基本エイリアス
alias ll='ls -la'
alias la='ls -a'
alias vi='vim'

# tmuxの自動起動
if [ -z "$TMUX" ]; then
  tmux attach || tmux new-session
fi
EOL
        ;;

      arch)
        cat > "$HOME/.zshrc" << 'EOL'
# Zinit
source "$HOME/.zinit/bin/zinit.zsh"

# Starship
eval "$(starship init zsh)"

# PATH設定
export PATH="$HOME/.local/bin:$PATH"

# asdf (Arch Linux)
. /opt/asdf-vm/asdf.sh

# 基本エイリアス
alias ll='ls -la'
alias la='ls -a'
alias vi='vim'
alias pacup='sudo pacman -Syu'
alias yayup='yay -Syu'

# tmuxの自動起動
if [ -z "$TMUX" ]; then
  tmux attach || tmux new-session
fi
EOL
        ;;

      debian|wsl)
        cat > "$HOME/.zshrc" << 'EOL'
# Zinit
source "$HOME/.zinit/bin/zinit.zsh"

# Starship
eval "$(starship init zsh)"

# PATH設定
export PATH="$HOME/.local/bin:$PATH"

# asdf (Debian/Ubuntu/WSL)
. $HOME/.asdf/asdf.sh

# 基本エイリアス
alias ll='ls -la'
alias la='ls -a'
alias vi='vim'
alias aptup='sudo apt-get update && sudo apt-get upgrade'

# tmuxの自動起動
if [ -z "$TMUX" ]; then
  tmux attach || tmux new-session
fi
EOL
        ;;

      *)
        cat > "$HOME/.zshrc" << 'EOL'
# Zinit
source "$HOME/.zinit/bin/zinit.zsh"

# Starship
eval "$(starship init zsh)"

# PATH設定
export PATH="$HOME/.local/bin:$PATH"

# 基本エイリアス
alias ll='ls -la'
alias la='ls -a'
alias vi='vim'

# tmuxの自動起動
if [ -z "$TMUX" ]; then
  tmux attach || tmux new-session
fi
EOL
        ;;
    esac
    
    log_success ".zshrcを作成しました"
  fi
}

# zshをデフォルトシェルに設定
set_zsh_as_default_shell() {
  # Windowsの場合はスキップ
  if [ "$OS" = "windows" ]; then
    log_info "Windows環境ではデフォルトシェルの変更をスキップします"
    return
  fi
  
  if [[ "$SHELL" != *"zsh"* ]]; then
    log_info "zshをデフォルトシェルに設定中..."
    
    # zshが/etc/shellsにリストされているか確認
    if ! grep -q "$(command -v zsh)" /etc/shells; then
      log_warn "zshが/etc/shellsに登録されていません。追加を試みます..."
      echo "$(command -v zsh)" | sudo tee -a /etc/shells
    fi
    
    # デフォルトシェルをzshに変更
    chsh -s "$(command -v zsh)"
    
    log_success "zshをデフォルトシェルに設定しました"
  else
    log_success "zshは既にデフォルトシェルです"
  fi
}

# Windows固有の設定
setup_windows_specific() {
  if [ "$OS" = "windows" ]; then
    log_info "Windows固有の設定を行います..."
    
    # Windows Terminalの設定ファイル（存在する場合）
    TERMINAL_SETTINGS="$TARGET_DIR/AppData/Local/Packages/Microsoft.WindowsTerminal_8wekyb3d8bbwe/LocalState/settings.json"
    if [ -f "$TERMINAL_SETTINGS" ]; then
      log_info "Windows Terminal設定ファイルをバックアップ中..."
      cp "$TERMINAL_SETTINGS" "${TERMINAL_SETTINGS}.backup"
      log_info "Windows Terminal設定ファイルをバックアップしました: ${TERMINAL_SETTINGS}.backup"
      
      log_info "Windows Terminalで使用するフォントはNerd Fontsのインストールをお勧めします。"
      log_info "インストール方法: scoop install nerd-fonts/FiraCode-NF"
    fi
    
    # PowerShell Profileの作成
    POWERSHELL_PROFILE="$TARGET_DIR/Documents/WindowsPowerShell/Microsoft.PowerShell_profile.ps1"
    if [ ! -f "$POWERSHELL_PROFILE" ]; then
      log_info "PowerShell Profileを作成中..."
      mkdir -p "$(dirname "$POWERSHELL_PROFILE")"
      cat > "$POWERSHELL_PROFILE" << 'EOL'
# Starshipの初期化
Invoke-Expression (&starship init powershell)

# エイリアス
function ll { Get-ChildItem -Force }
function la { Get-ChildItem -Force }
function vi { vim $args }

# GitのSSH設定
$env:GIT_SSH = "C:\Windows\System32\OpenSSH\ssh.exe"

# Scoopで入れた各種コマンドへのパスを確保
$env:Path = $env:Path + ";$HOME\scoop\shims"
EOL
      log_success "PowerShell Profileを作成しました: $POWERSHELL_PROFILE"
    fi
    
    log_success "Windows固有の設定が完了しました"
  fi
}

# 使用方法の表示
show_usage() {
  cat << EOF
使用方法: $0 [オプション]

オプション:
  --config-method=METHOD  .configディレクトリの処理方法を指定します
                          "individual": 各ファイルを個別にシンボリックリンク (デフォルト)
                          "whole": .configディレクトリ全体をシンボリックリンク

例:
  $0                       # デフォルト設定でセットアップ
  $0 --config-method=whole # .configディレクトリ全体をリンク
EOF
}

# メイン処理
main() {
  log_info "dotfiles セットアップを開始します... (検出されたOS: $OS)"
  log_info "設定: CONFIG_METHOD=$CONFIG_METHOD"
  
  setup_package_manager
  install_packages
  setup_symlinks
  install_additional_tools
  
  # Windows固有の設定
  if [ "$OS" = "windows" ]; then
    setup_windows_specific
  else
    set_zsh_as_default_shell
  fi
  
  log_success "セットアップが完了しました! ターミナルを再起動してください。"
  log_info "注意: 一部の設定は新しいセッションで有効になります。"
  
  # Windows特有の注意事項
  if [ "$OS" = "windows" ]; then
    log_info "Windows環境では以下の追加手順を推奨します:"
    log_info "1. WSLをインストールして Linux サブシステムでの環境構築を検討してください"
    log_info "2. Windows Terminalを使用して、プロファイル設定にWSLを追加してください"
    log_info "3. Nerd Fontsをインストールして見た目を改善してください: scoop install nerd-fonts/FiraCode-NF"
  fi
}

# スクリプト実行
main
