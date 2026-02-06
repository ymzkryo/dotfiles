-- modules/wezterm.lua

local function manageWezTerm()
    local appName = "WezTerm"
    local app = hs.application.get(appName)
    
    if not app then
        hs.application.launchOrFocus(appName)
    else
        app:activate()
        
        -- 1画面（外作業）でも4画面（自宅）でも、共通して「最大化」を目指す
        local win = app:mainWindow()
        if not win then return end

        if isSingleMonitor() then
            -- 1画面モード：その場で最大化
            win:maximize()
            return
        end

        -- 4画面モード：Configで指定したモニタ(通常は4)へ移動して最大化
        local targetKey = Config.appLayout[appName] or "4"
        local targetScreen = findScreen(Config.screenMap[targetKey])
        
        if targetScreen then
            -- 指定モニタのフルフレーム（全画面サイズ）を取得して適用
            win:setFrame(targetScreen:fullFrame(), 0) 
            hs.alert.show("WezTerm をモニタ " .. targetKey .. " で最大化しました")
        end
    end
end

-- Ctrl + Opt + W で発動
hs.hotkey.bind({"ctrl", "alt"}, "w", manageWezTerm)

_G.manageWezTerm = manageWezTerm
