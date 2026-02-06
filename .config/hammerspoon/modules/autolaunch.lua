-- modules/autolaunch.lua

local function handleAppEvent(appName, eventType, app)
    if eventType == hs.application.watcher.launched or eventType == hs.application.watcher.activated then
        -- 【1画面最適化】外作業中は複雑な移動をせず、その場で最大化して終了
        if isSingleMonitor() then
            hs.timer.doAfter(0.5, function()
                local win = app:mainWindow()
                if win then win:maximize() end
            end)
            return
        end

        -- 4画面モード時のロジック
        local bundleID = app:bundleID()
        local targetScreenKey = nil

        for configAppName, screenKey in pairs(Config.appLayout) do
            if appName == configAppName or (bundleID and bundleID:find(configAppName)) then
                targetScreenKey = screenKey
                break
            end
        end
        
        if targetScreenKey then
            local targetScreenName = Config.screenMap[targetScreenKey]
            local targetScreen = findScreen(targetScreenName)
            
            hs.timer.doAfter(0.5, function()
                local win = app:mainWindow()
                if win and targetScreen then
                    local f = targetScreen:fullFrame()
                    win:setFrame({
                        x = f.x,
                        y = f.y,
                        w = f.w * (Config.resizeRatio or 0.66),
                        h = f.h
                    }, 0)
                end
            end)
        end
    end
end

local appWatcher = hs.application.watcher.new(handleAppEvent):start()
