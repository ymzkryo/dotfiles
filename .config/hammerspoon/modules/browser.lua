-- modules/browser.lua
-- display 3 のウルトラワイドを「メイン + 右スタック」で使う。
-- メインは Config.browserMainRatio 分の幅を占め、残りをスタックが上下に等分する。
-- Safari は display 4 の左側（WezTerm が使わない残り）に置く。

-- 現在メインにしている Config.browserStack のインデックス
local mainIndex = 1

-- タイトルに domain を含む Chrome ウィンドウを列挙する
-- string.find の第3引数 true は Lua パターンではなく素の文字列として扱うため
local function chromeWindowsFor(domain)
    local chrome = hs.application.find("Google Chrome")
    if not chrome then return {} end

    return hs.fnutils.filter(chrome:allWindows(), function(win)
        return win:isStandard() and string.find(win:title(), domain, 1, true) ~= nil
    end)
end

-- 実際にウィンドウが存在するものだけを Config.browserStack の順で返す
local function presentEntries()
    local present = {}
    for i, entry in ipairs(Config.browserStack) do
        local wins = chromeWindowsFor(entry.domain)
        if #wins > 0 then
            table.insert(present, { index = i, label = entry.label, wins = wins })
        end
    end
    return present
end

local function placeAll(wins, frame)
    for _, win in ipairs(wins) do win:setFrame(frame, 0) end
end

-- メイン + 右スタックを display 3 に敷き直す。配置できた枚数を返す
local function layoutBrowserStack()
    local present = presentEntries()
    -- 見つからないときの通知は呼び出し側に任せる（一括配置では他の結果とまとめて出すため）
    if #present == 0 then return 0 end

    -- メイン指定のウィンドウが無ければ、存在する先頭を繰り上げてメインにする
    local mainPos = 1
    for i, e in ipairs(present) do
        if e.index == mainIndex then
            mainPos = i
            break
        end
    end
    mainIndex = present[mainPos].index

    local mainEntry = present[mainPos]
    local stack = {}
    for i, e in ipairs(present) do
        if i ~= mainPos then table.insert(stack, e) end
    end

    -- 【1画面最適化】外作業中は分割せず、メインを最大化して前面に出す
    if isSingleMonitor() then
        for _, win in ipairs(mainEntry.wins) do win:maximize() end
        mainEntry.wins[1]:focus()
        hs.alert.show("外作業モード: " .. mainEntry.label .. " を最大化しました")
        return #present
    end

    local screen, screenName = findScreenByKey(Config.browserMonitor)
    if not screen then
        hs.alert.show("モニタ " .. Config.browserMonitor ..
            " (" .. (screenName or "?") .. ") は未接続です")
        return 0
    end

    local f = screen:fullFrame()
    -- スタックが空なら全幅をメインに使う
    local mainW = (#stack > 0)
        and math.floor(f.w * (Config.browserMainRatio or 2 / 3))
        or f.w

    placeAll(mainEntry.wins, { x = f.x, y = f.y, w = mainW, h = f.h })

    -- 端数でスタックに隙間が出ないよう、境界を比率から直接求める
    for i, e in ipairs(stack) do
        local top    = f.y + math.floor(f.h * (i - 1) / #stack)
        local bottom = f.y + math.floor(f.h * i / #stack)
        placeAll(e.wins, { x = f.x + mainW, y = top, w = f.w - mainW, h = bottom - top })
    end

    mainEntry.wins[1]:focus()
    return #present
end

-- Safari は display 4 の左側（WezTerm が使わない残り）に置く。配置できたら true を返す
local function layoutSafari()
    local safari = hs.application.find("Safari")
    if not safari then return false end

    local wins = hs.fnutils.filter(safari:allWindows(), function(win)
        return win:isStandard()
    end)
    if #wins == 0 then return false end

    if isSingleMonitor() then
        for _, win in ipairs(wins) do win:maximize() end
        return true
    end

    local screen = findScreenByKey(Config.appLayout["Safari"] or "4")
    if not screen then return false end

    local safariFrame = monitor4Frames(screen)
    placeAll(wins, safariFrame)
    return true
end

-- 指定した会社をメインに切り替える
local function setMain(stackIndex)
    mainIndex = stackIndex
    if layoutBrowserStack() == 0 then
        hs.alert.show("対象の Chrome ウィンドウが見つかりません")
    end
end

-- 存在するウィンドウだけを巡回してメインを次へ送る
local function rotateMain()
    local present = presentEntries()
    if #present == 0 then
        hs.alert.show("対象の Chrome ウィンドウが見つかりません")
        return
    end

    local pos = 1
    for i, e in ipairs(present) do
        if e.index == mainIndex then
            pos = i
            break
        end
    end

    mainIndex = present[(pos % #present) + 1].index
    layoutBrowserStack()
end

-- display 3 の Chrome、display 4 の Safari と WezTerm をまとめて配置する
local function arrangeAll()
    local placed = layoutBrowserStack()
    local safari = layoutSafari()
    -- wezterm.lua で定義される。読み込み順に依存しないよう呼び出し時に参照する
    local wezterm = _G.layoutWezTerm ~= nil and _G.layoutWezTerm()

    local total = #Config.browserStack
    local parts = { "Chrome " .. placed .. "/" .. total }
    if safari then table.insert(parts, "Safari") end
    if wezterm then table.insert(parts, "WezTerm") end

    local msg = "配置: " .. table.concat(parts, " / ")
    if placed < total then
        msg = msg .. "（Chrome の残りはタイトル不一致）"
    end
    hs.alert.show(msg)
end

-- monitor.lua の resetAllWindowPositions から呼び出せるように公開
_G.arrangeAllWindows = arrangeAll

-- ショートカット登録
for i, entry in ipairs(Config.browserStack) do
    hs.hotkey.bind({"ctrl", "alt"}, entry.key, function() setMain(i) end)
end
hs.hotkey.bind({"ctrl", "alt"}, ";", rotateMain)
hs.hotkey.bind({"ctrl", "alt"}, "l", arrangeAll)
