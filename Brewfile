# Brewfile
#
# 役割分担:
#   - 言語ランタイム・バージョンを固定したい CLI は mise で管理する
#     (~/.config/mise/config.toml を参照。node / python / go / terraform / awscli / gcloud など)
#     npm / cargo / go のグローバルパッケージも mise の該当バックエンドに置く
#   - GUI アプリと、バージョン固定が不要なシステム寄りのツールは Brewfile で管理する
#
# 実態と乖離したら以下で再生成する。種別を絞らないと go / cargo / uv / npm の
# エントリまで混ざり、ローカル絶対パスを含む行が出てしまうので必ずフラグを付ける
#   brew bundle dump --force --formula --cask --tap

tap "asmvik/formulae", "https://github.com/asmvik/homebrew-formulae.git"
tap "bufbuild/buf"
tap "dotenvx/brew"
tap "nikitabobko/tap"
# Library for manipulating PNG images
brew "libpng"
# Automatic configure script builder
brew "autoconf"
# Tool for generating GNU Standards-compliant Makefiles
brew "automake"
# Parser generator
brew "bison"
# Core application library for C
brew "glib"
# Perl script to extracts URLs from emails or plain text
brew "extract_url"
# Cryptography and SSL/TLS Toolkit
brew "openssl@3"
# Play, record, convert, and stream select audio and video codecs
brew "ffmpeg"
# Command-line fuzzy finder written in Go
brew "fzf"
# GNU multiple precision arithmetic library
brew "gmp"
# GNU compiler collection
brew "gcc"
# Graphics library to dynamically manipulate images
brew "gd"
# GitHub command-line tool
brew "gh"
# Remote repository management made easy
brew "ghq"
# Asynchronous event library
brew "libevent"
# Fast linters runner for Go
brew "golangci-lint"
# Graph visualization software from AT&T and Bell Labs
brew "graphviz"
# Like cURL, but for gRPC
brew "grpcurl"
# Text-based UI library
brew "ncurses"
# Improved top (interactive process viewer)
brew "htop"
# Get events and tasks from the macOS calendar database
brew "ical-buddy"
# Tools and libraries to manipulate images in select formats
brew "imagemagick"
# Image manipulation library
brew "jpeg"
# Implementation of the file(1) command
brew "libmagic"
# NaCl networking and cryptography library
brew "libsodium"
# GNOME XML library
brew "libxml2"
# C library for reading, creating, and modifying zip archives
brew "libzip"
# Text-to-HTML conversion tool
brew "markdown"
# Polyglot runtime manager (asdf rust clone)
brew "mise"
# General-purpose lossless data-compression library
brew "zlib"
# Open source relational database management system
brew "mysql-client"
# E-mail reader with support for Notmuch, NNTP and much more
brew "neomutt"
# RSS/Atom feed reader for text terminals
brew "newsboat"
# Create, run, and share large language models (LLMs)
brew "ollama"
# Regular expressions library
brew "oniguruma"
# Simplistic interactive filtering tool
brew "peco"
# Package compiler and linker metadata toolkit
brew "pkgconf"
# Draw UML diagrams
brew "plantuml"
# PDF rendering library (based on the xpdf-3.0 code base)
brew "poppler"
# Framework for managing multi-language pre-commit hooks
brew "pre-commit"
# Generate C-based recognizers from regular expressions
brew "re2c"
# Cross-shell prompt for astronauts
brew "starship"
# Display directories as trees (with optional color/HTML output)
brew "tree"
# URL extractor/launcher
brew "urlview"
# Clean C library for processing UTF-8 Unicode data
brew "utf8proc"
# Password manager that keeps all passwords secure behind one password
cask "1password"
# Command-line interface for 1Password
cask "1password-cli"
cask "aerospace"
# Virtual Audio Driver
cask "blackhole-2ch"
# Open links in any browser
cask "choosy"
# Voice and text chat software
cask "discord"
# App to build and share containerised applications and microservices
cask "docker-desktop"
# Client for the Dropbox cloud storage service
cask "dropbox"
cask "font-fira-code-nerd-font"
# Set of tools to manage resources and applications hosted on Google Cloud
cask "gcloud-cli"
# Web browser
cask "google-chrome"
# Desktop automation application
cask "hammerspoon"
# Utility to hide menu bar items
cask "hiddenbar"
# Markdown editor
cask "inkdrop"
# Keyboard customiser
cask "karabiner-elements"
cask "livetail"
# Open-source software for live streaming and screen recording
cask "obs"
# Remote desktop
cask "parsec"
# Control your tools with a few keystrokes
cask "raycast"
# Team communication and collaboration software
cask "slack"
# To-do list
cask "todoist-app"
# GPU-accelerated cross-platform terminal emulator and multiplexer
cask "wezterm"
# Video communication and virtual meeting platform
cask "zoom"
