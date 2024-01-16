###################################
# *env PATH setting
###################################

# asdf
. $HOME/.asdf/asdf.sh

# openjdk11
export PATH="/opt/homebrew/opt/openjdk@11/bin:$PATH"

# ARM Homebrew
export PATH="/opt/homebrew/bin:$PATH"
export PATH="/opt/homebrew/sbin:$PATH"

# chatgpt-api
# 外部ファイルから読み込むように変更
export CHATGPT_API_KEY=~/.config/chatgpt-api/api_key
