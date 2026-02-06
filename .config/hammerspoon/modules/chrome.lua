-- modules/chrome.lua

local function moveSpecificChrome(domain, screenKey, x_pos)
    local chrome = hs.application.find("Google Chrome")
    if not chrome then return end

    -- 【1画面最適化】外作業中は特定のスロット(1/3)に分けず、最大化して見やすくする
    if isSingleMonitor() then
        for _, win in ipairs(chrome:allWindows()) do
            if string.find(win:title(), domain) then
                win:maximize()
                win:focus()
            end
        end
        return
    end

    -- 4画面モード時のロジック
    local targetScreen = findScreen(Config.screenMap[screenKey])
    if not targetScreen then return end

    local f = targetScreen:fullFrame()
    local w3 = f.w / 3

    for _, win in ipairs(chrome:allWindows()) do
        if string.find(win:title(), domain) then
            win:setFrame({
                x = f.x + (w3 * x_pos),
                y = f.y,
                w = w3,
                h = f.h
            }, 0)
            win:focus()
        end
    end
end

local function arrangeChromeToMonitor3()
    if isSingleMonitor() then
        hs.alert.show("1画面モードのため一括配置をスキップします")
        return
    end
    
    local layouts = {
        { domain = "outarc.co.jp",      x_pos = 0 },
        { domain = "katatsumuri.works", x_pos = 1 },
    }
    for _, layout in ipairs(layouts) do
        moveSpecificChrome(layout.domain, "3", layout.x_pos)
    end
end

-- ショートカット登録
hs.hotkey.bind({"ctrl", "alt"}, "o", function() moveSpecificChrome("outarc.co.jp", "4", 0) end)
hs.hotkey.bind({"ctrl", "alt"}, "k", function() moveSpecificChrome("katatsumuri.works", "4", 0) end)
hs.hotkey.bind({"ctrl", "alt"}, "l", arrangeChromeToMonitor3)
