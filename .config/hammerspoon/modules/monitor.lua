-- modules/monitor.lua

-- 1. 単体ウィンドウのワープ機能
local function teleportToScreen(key)
    if isSingleMonitor() then
        hs.alert.show("外作業モード: モニタ移動は無効です")
        return
    end

    local partialName = Config.screenMap[key]
    local targetScreen = findScreen(partialName)
    local win = hs.window.focusedWindow()
    
    if win and targetScreen then
        local f = targetScreen:fullFrame()
        -- 通常のワープはWezTerm含め一律 66% 幅（お好みでWezTermだけ100%にする分岐も可）
        win:setFrame({
            x = f.x, y = f.y,
            w = f.w * (Config.resizeRatio or 0.66), h = f.h
        }, 0)
        hs.mouse.absolutePosition({ x = f.x + (f.w / 2), y = f.y + (f.h / 2) })
    end
end

-- 2. 【要塞復元】全ウィンドウ一括リセット
function resetAllWindowPositions()
    if isSingleMonitor() then
        local wins = hs.window.allWindows()
        for _, win in ipairs(wins) do win:maximize() end
        hs.alert.show("外作業モード: 全ウィンドウを最大化しました")
        return
    end

    for appName, screenKey in pairs(Config.appLayout) do
        local app = hs.application.get(appName)
        if app then
            local targetScreen = findScreen(Config.screenMap[screenKey])
            local win = app:mainWindow()
            
            if win and targetScreen then
                local f = targetScreen:fullFrame()
                
                if appName == "WezTerm" then
                    -- 【WezTerm専用】指定モニタで最大化
                    win:setFrame(f, 0)
                else
                    -- 【その他】Configの比率(66%)を適用
                    win:setFrame({
                        x = f.x, y = f.y,
                        w = f.w * (Config.resizeRatio or 0.66), h = f.h
                    }, 0)
                end
            end
        end
    end

    -- Chromeのドメイン別3分割配置を呼び出す
    if _G.arrangeChromeToMonitor3 then _G.arrangeChromeToMonitor3() end
    
    hs.alert.show("要塞の配置を完全復元（WezTermは最大化）")
end

-- 3. マウス強調機能 (Ctrl + Opt + C)
hs.hotkey.bind({"ctrl", "alt"}, "c", function()
    local mousePos = hs.mouse.absolutePosition()
    local circle = hs.drawing.circle(hs.geometry.rect(mousePos.x - 40, mousePos.y - 40, 80, 80))
    circle:setStrokeColor({["red"]=1, ["blue"]=0, ["green"]=0, ["alpha"]=1}):setStrokeWidth(5):show()
    hs.timer.doAfter(1, function() circle:delete() end)
end)

-- 4. 自動リロード設定

local function reloadConfig(files)
    local doReload = false
    for _, file in pairs(files) do
        -- .lua ファイルの変更、またはフォルダ自体の変更を検知
        if file:sub(-4) == ".lua" then
            doReload = true
            break
        end
    end
    
    if doReload then
        print("Hammerspoon: Config files changed, reloading...")
        hs.reload()
    end
end

-- 監視パスを ~/.hammerspoon/ 以下の全サブディレクトリ(recursive)に設定
if myWatcher then myWatcher:stop() end
myWatcher = hs.pathwatcher.new(os.getenv("HOME") .. "/.hammerspoon/", reloadConfig):start()

-- 5. ショートカット登録
-- Alt + Shift + 1~4: モニタ間ワープ
for key, _ in pairs(Config.screenMap) do
    hs.hotkey.bind({"alt", "shift"}, key, function() teleportToScreen(key) end)
end

-- Ctrl + Opt + Cmd + R: 配置リセット
hs.hotkey.bind({"ctrl", "alt", "cmd"}, "r", resetAllWindowPositions)
