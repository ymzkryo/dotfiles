-- ~/.config/hammerspoon/init.lua

-- モジュール読み込み（パスの頭に modules. をつける）
require("modules._config")
require("modules.window")
require("modules.monitor")
require("modules.wezterm")
require("modules.browser")
require("modules.autolaunch")

-- 最後に通知を表示
hs.alert.show("Hammerspoon: Modular Config Loaded")
