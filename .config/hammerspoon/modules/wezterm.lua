-- modules/wezterm.lua
-- WezTerm は display 4 の右側に固定幅で置く。
-- 全画面にすると tmux のセル数が変わり、分割比率の作り直しが発生するため、
-- 幅は Config.weztermRatio で固定する。左の残りは Safari が使う。

-- 起動中の WezTerm を所定の位置に置く。配置できたら true を返す
local function layoutWezTerm()
    local appName = "WezTerm"
    local app = hs.application.get(appName)
    if not app then return false end

    local win = app:mainWindow()
    if not win then return false end

    -- 【1画面最適化】外作業中はその場で最大化
    if isSingleMonitor() then
        win:maximize()
        return true
    end

    local targetScreen = findScreenByKey(Config.appLayout[appName] or "4")
    if not targetScreen then return false end

    local _, weztermFrame = monitor4Frames(targetScreen)
    win:setFrame(weztermFrame, 0)
    return true
end

-- browser.lua の一括配置から呼び出せるように公開
_G.layoutWezTerm = layoutWezTerm
