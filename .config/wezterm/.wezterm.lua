local wezterm = require 'wezterm'
local config = {}

if wezterm.config_builder then
    config = wezterm.config_builder()
end

-- font  FireCode Nerd Font
config.font = wezterm.font("FiraCode Nerd Font")

-- font size
config.font_size = 18
-- color scheme
config.color_scheme = 'Solarized (dark) (terminal.sexy)'

-- automatically reload config
config.automatically_reload_config = true

-- not show title bar
config.window_decorations = "RESIZE"

-- not show new tab button in tab bar
config.show_new_tab_button_in_tab_bar = false

-- active tab coler
wezterm.on("format-tab-title", function(tab, tabs, panes, config, hover, max_width)
    local background = "#5c6d74"
    local foreground = "#FFFFFF"

    if tab.is_active then
        background = "#ae8b2d"
        foreground = "#FFFFFF"
    end

    local title = "   " .. wezterm.truncate_right(tab.active_pane.title, max_width - 1) .. "   "
    return {
      { Background = { Color = background } },
      { Foreground = { Color = foreground } },
      { Text = title },
    }
end)

-- set current directory
local function set_title(pane)
    local cwd_uri = pane:get_current_working_dir()
    local cwd_uri_str = wezterm.to_string(cwd_uri)
    local cwd = cwd_uri_str:match("^file://", "")

    if (not cwd) then
        return nil
    end
end

local title_cache = {}

wezterm.on("update-status", function(window, pane)
    local title = set_title(pane)
    local pane_id = pane:pane_id()
    title_cache[pane_id] = title
end)


-- tab title change current directory
wezterm.on("format-tab-title", function(tab, tabs, panes, config, hover, max_width)
    local pane = tab.active_pane
    local pane_id = pane.pane_id

    if title_cache[pane_id] then
        return title_cache[pane_id]
    else 
        return tab.tactive_pane.title
    end
end)

return config
