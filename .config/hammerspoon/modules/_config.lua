-- config.lua
Config = {}

Config.resizeRatio = 0.66

Config.screenMap = {
    ["1"] = "Retina",
    ["2"] = "BL650",
    ["3"] = "PL3490WQ",
    ["4"] = "LG HDR WQHD"
}

-- Chrome自動配置のターゲットを定義
Config.chromeMainMonitor = Config.screenMap["3"]

-- アプリごとのデフォルト配置モニタ設定 (Config.screenMapのキーを指定)
Config.appLayout = {
    ["WezTerm"]      = "4",
    ["Slack"]        = "1",
    ["Discord"]      = "2",
    ["LINE"]         = "1",
    ["Google Chrome"] = "3",
    ["Mail"]         = "1",
    ["iCal"]     = "1",
    ["Zoom.us"]      = "3",
    -- 他のアプリもここに追加
}

-- 接続されているモニタ数を確認する関数
function isSingleMonitor()
    return #hs.screen.allScreens() == 1
end

-- 例：1画面の時だけ特別なメッセージを出す、などの分岐が可能
if isSingleMonitor() then
    hs.alert.show("外作業モード: 1画面最適化を適用します")
end

-- 共通ヘルパー関数もここに置いておくと便利
function findScreen(name)
    return hs.fnutils.find(hs.screen.allScreens(), function(s)
        return s:name():find(name)
    end)
end
