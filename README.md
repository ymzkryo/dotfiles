dotfiles
========

Personal dotfiles for cross-platform development environment.

Supported Platforms
-------------------
- macOS (Apple Silicon / Intel)
- Arch Linux
- Ubuntu / Debian
- Windows WSL

Install
-------

### One-liner (Recommended)

```bash
curl -fsSL https://raw.githubusercontent.com/ymzkryo/dotfiles/master/install.sh | bash
```

### Manual

```bash
git clone --recursive https://github.com/ymzkryo/dotfiles.git ~/dotfiles
cd ~/dotfiles
./setup.sh
```

### Options

```bash
# Link .config directory as a whole instead of individual files
./setup.sh --config-method=whole
```

What setup.sh Does
------------------

### 1. OS Detection
Automatically detects the running environment:
- macOS (via `$OSTYPE`)
- WSL (via environment variables, `/proc/version`, etc.)
- Arch Linux (via `/etc/arch-release`)
- Debian/Ubuntu (via `/etc/debian_version`)
- Windows MSYS/Cygwin

### 2. Package Manager Setup
| OS | Action |
|----|--------|
| macOS | Install Homebrew if not present |
| Arch | Update system with `pacman -Syu` |
| Debian/WSL | Update system with `apt-get update && upgrade` |
| Windows | Install Scoop if not present |

### 3. Package Installation
| OS | Method |
|----|--------|
| macOS | `brew bundle` (uses Brewfile) |
| Arch | `pacman` + `yay` (AUR helper) |
| Debian/WSL | `apt-get install` |
| Windows | `scoop install` |

### 4. Symlink Creation
Creates symlinks from dotfiles directory to home:

| Source | Destination |
|--------|-------------|
| `.vimrc` | `~/.vimrc` |
| `.tmux.conf` | `~/.tmux.conf` |
| `.gitconfig` | `~/.gitconfig` |
| `.vim/_config`, `.vim/colors` | `~/.vim/` |
| `.tmux/bin` | `~/.tmux/bin` |
| `.newsboat/*` | `~/.newsboat/` |
| `.config/*` | `~/.config/` |
| `template` | `~/.local/share/template` |

### 5. Additional Tools
- **Zinit**: zsh plugin manager
- **Starship**: Cross-shell prompt
- Generates OS-specific `.zshrc` if not present

### 6. Default Shell
Sets zsh as the default shell (Unix systems only).

What's Included
---------------

### Shell
- **zsh** + **zinit** - Plugin manager
- **starship** - Cross-shell prompt

### Terminal
- **tmux** - Terminal multiplexer
- **wezterm** - GPU-accelerated terminal

### Editor
- **Vim** - Text editor

### Tools
- **newsboat** - RSS reader
- **asdf** - Version manager

Requirements
------------

### VM
[asdf](https://asdf-vm.com)

### Terminal
[wezterm](https://wezfurlong.org/wezterm/index.html)
[tmux](https://github.com/tmux/tmux)

### Editor
[Vim](https://github.com/vim/vim)

### zsh + zinit
[zinit](https://github.com/zdharma-continuum/zinit)

### starship
[starship](https://starship.rs)

### Todist
[chaosteil/doist](https://github.com/chaosteil/doist)

### toggl
[watercooler-labs/toggl-cli](https://github.com/watercooler-labs/toggl-cli)

### memo
[mattn/memo](https://github.com/mattn/memo)

### others
[powerline-extra-symbols](https://github.com/ryanoasis/powerline-extra-symbols)
[nerd-fonts](https://www.nerdfonts.com/cheat-sheet)

Screenshots
-----------
![screenshot](screenshot/2025-01-14_dotfiles.png)

Directory Structure
-------------------

```
dotfiles/
├── .config/          # XDG config files
│   ├── neomutt/
│   ├── starship/
│   ├── wezterm/
│   └── zsh/
├── .newsboat/        # RSS reader config
├── .tmux/            # tmux config & plugins
├── .vim/             # Vim config
├── scripts/          # Utility scripts
├── template/         # File templates
├── Brewfile          # Homebrew packages (macOS)
├── install.sh        # One-liner installer
└── setup.sh          # Main setup script
```

Author
------

ymzkryo
