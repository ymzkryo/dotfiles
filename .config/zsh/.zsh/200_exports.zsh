# SSH agent for 1Password
export SSH_AUTH_SOCK=~/Library/Group\ Containers/2BUA8C4S2C.com.1password/t/agent.sock

# Environment variables for Homebrew packages
export PKG_CONFIG_PATH="/opt/homebrew/opt/libxml2/lib/pkgconfig:/opt/homebrew/opt/zlib/lib/pkgconfig:/opt/homebrew/opt/mysql-client/lib/pkgconfig"
export LDFLAGS="-L/opt/homebrew/opt/libxml2/lib"
export CPPFLAGS="-I/opt/homebrew/opt/libxml2/include"
export PATH="/opt/homebrew/opt/jpeg/bin:$PATH"
export LDFLAGS="-L/opt/homebrew/opt/jpeg/lib"
export LDFLAGS="-L/opt/homebrew/opt/zlib/lib"
export CPPFLAGS="-I/opt/homebrew/opt/zlib/include"
export GDLIB_CFLAGS=$(pkg-config --cflags gdlib)
export GDLIB_LIBS=$(pkg-config --libs gdlib)
export PATH="/opt/homebrew/opt/libiconv/bin:$PATH"

# Golang
export GOPATH="$HOME/go"
export PATH="$PATH:$(go env GOPATH)/bin"

# Rust at asdf
export PATH="$PATH:$(asdf where rust)/bin"

# himalaya path
export PATH="$HOME/himalaya/target/release:$PATH"

# Custom scripts
export PATH="$HOME/dotfiles/scripts:$PATH"
