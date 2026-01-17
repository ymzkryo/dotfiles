#!/bin/bash
#
# Dotfiles One-liner Installer
# Usage: curl -fsSL https://raw.githubusercontent.com/ymzkryo/dotfiles/master/install.sh | bash
#

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

DOTFILES_REPO="https://github.com/ymzkryo/dotfiles.git"
DOTFILES_DIR="$HOME/dotfiles"

# Check if git is installed
check_git() {
  if ! command -v git &>/dev/null; then
    log_error "git is not installed."
    log_info "Please install git first:"

    # Detect OS and show appropriate install command
    if [[ "$OSTYPE" == "darwin"* ]]; then
      log_info "  xcode-select --install"
    elif [[ -f /etc/arch-release ]]; then
      log_info "  sudo pacman -S git"
    elif [[ -f /etc/debian_version ]]; then
      log_info "  sudo apt-get install git"
    else
      log_info "  Install git using your package manager"
    fi
    exit 1
  fi
}

# Clone or update dotfiles
clone_dotfiles() {
  if [[ -d "$DOTFILES_DIR" ]]; then
    log_warn "dotfiles directory already exists: $DOTFILES_DIR"
    log_info "Updating existing dotfiles..."
    cd "$DOTFILES_DIR"
    git pull origin master
    git submodule update --init --recursive
  else
    log_info "Cloning dotfiles to $DOTFILES_DIR..."
    git clone --recursive "$DOTFILES_REPO" "$DOTFILES_DIR"
  fi
}

# Run setup script
run_setup() {
  cd "$DOTFILES_DIR"

  if [[ ! -x "setup.sh" ]]; then
    chmod +x setup.sh
  fi

  log_info "Running setup script..."
  ./setup.sh "$@"
}

main() {
  echo ""
  echo "=================================="
  echo "  Dotfiles Installer"
  echo "=================================="
  echo ""

  check_git
  clone_dotfiles
  run_setup "$@"

  log_success "Installation complete!"
  log_info "Please restart your terminal or run: exec \$SHELL"
}

main "$@"
