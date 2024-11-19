local wezterm = require 'wezterm'
local config = {}

if wezterm.config_builder then
    config = wezterm.config_builder()
end

config.font_size = 16
config.color_scheme = 'Solarized (dark) (terminal.sexy)'
config.automatically_reload_config = true

return config

