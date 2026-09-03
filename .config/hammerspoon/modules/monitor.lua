-- modules/monitor.lua

-- 1. 単体ウィンドウのワープ機能
local function teleportToScreen(key)
    if isSingleMonitor() then
        hs.alert.show("外作業モード: モニタ移動は無効です")
        return
    end

    local targetScreen, partialName = findScreenByKey(key)
    if not targetScreen then
        hs.alert.show("モニタ " .. key .. " (" .. (partialName or "?") .. ") は未接続です")
        return
    end

    local win = hs.window.focusedWindow()

    if win then
        local f = targetScreen:fullFrame()
        -- 通常のワープはWezTerm含め一律 66% 幅（お好みでWezTermだけ100%にする分岐も可）
        win:setFrame({
            x = f.x, y = f.y,
            w = f.w * (Config.resizeRatio or 0.66), h = f.h
        }, 0)
        hs.mouse.absolutePosition({ x = f.x + (f.w / 2), y = f.y + (f.h / 2) })
    end
end

-- 1b. 隣のディスプレイへウィンドウを送る
-- hs.screen:next() は公式ドキュメントで "in arbitrary order" と明記されており
-- 物理的な並び順が保証されないため、左→右に自前で並べ替えてから隣を求める
local function screensLeftToRight()
    local screens = hs.screen.allScreens()
    table.sort(screens, function(a, b)
        local fa, fb = a:fullFrame(), b:fullFrame()
        if fa.x == fb.x then return fa.y < fb.y end
        return fa.x < fb.x
    end)
    return screens
end

-- step = 1 で右隣、-1 で左隣。端はラップアラウンドする
local function moveWindowToAdjacentScreen(step)
    if isSingleMonitor() then
        hs.alert.show("外作業モード: モニタ移動は無効です")
        return
    end

    local win = hs.window.focusedWindow()
    if not win then return end

    local screens = screensLeftToRight()
    local current = win:screen()
    if not current then return end

    -- スクリーンの同一判定は原点で行う。macOS のグローバル座標では
    -- 原点が一致するスクリーンは存在しないため、同名モニタが2枚あっても取り違えない
    local cur = current:fullFrame()
    local pos = 1
    for i, sc in ipairs(screens) do
        local f = sc:fullFrame()
        if f.x == cur.x and f.y == cur.y then
            pos = i
            break
        end
    end

    local target = screens[((pos - 1 + step) % #screens) + 1]
    -- noResize=false なので、元の画面に対する相対サイズを保ったまま移動する
    win:moveToScreen(target, false, true, 0)

    local f = target:fullFrame()
    hs.mouse.absolutePosition({ x = f.x + (f.w / 2), y = f.y + (f.h / 2) })
    hs.alert.show("-> " .. target:name())
end

-- 2. 【要塞復元】全ウィンドウ一括リセット
function resetAllWindowPositions()
    if isSingleMonitor() then
        local wins = hs.window.allWindows()
        for _, win in ipairs(wins) do win:maximize() end
        hs.alert.show("外作業モード: 全ウィンドウを最大化しました")
        return
    end

    local skipped = {}

    for appName, screenKey in pairs(Config.appLayout) do
        local app = hs.application.get(appName)
        if app then
            local targetScreen, screenName = findScreenByKey(screenKey)
            local win = app:mainWindow()

            if win and not targetScreen then
                table.insert(skipped, appName .. "->" .. screenKey .. ":" .. (screenName or "?"))
            end
            
            -- WezTerm と Safari の枠は arrangeAllWindows 側で決めるのでここでは触らない
            if win and targetScreen and appName ~= "WezTerm" and appName ~= "Safari" then
                local f = targetScreen:fullFrame()
                -- Configの比率(66%)を適用
                win:setFrame({
                    x = f.x, y = f.y,
                    w = f.w * (Config.resizeRatio or 0.66), h = f.h
                }, 0)
            end
        end
    end

    -- Chrome / Safari / WezTerm の配置を呼び出す
    if _G.arrangeAllWindows then _G.arrangeAllWindows() end

    if #skipped > 0 then
        table.sort(skipped)
        hs.alert.show("配置復元（未接続モニタのためスキップ: " .. table.concat(skipped, ", ") .. "）")
    end
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

-- Ctrl + Opt + . : フォーカス中のウィンドウを右隣のディスプレイへ
hs.hotkey.bind({"ctrl", "alt"}, ".", function() moveWindowToAdjacentScreen(1) end)

-- Ctrl + Opt + Cmd + R: 配置リセット
hs.hotkey.bind({"ctrl", "alt", "cmd"}, "r", resetAllWindowPositions)
