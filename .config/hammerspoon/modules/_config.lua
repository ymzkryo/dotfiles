-- config.lua
Config = {}

Config.resizeRatio = 0.66

Config.screenMap = {
    ["1"] = "Retina",
    ["2"] = "BL650",
    ["3"] = "PL3490WQ",
    ["4"] = "LG HDR WQHD"
}

-- Chrome をメイン+スタックで並べるモニタ (screenMap のキー)
Config.browserMonitor = "3"

-- メインが占める横幅の比率。残りをスタックが上下に等分する
Config.browserMainRatio = 2 / 3

-- display 4 で WezTerm が占める右側の幅の比率。左の残りを Safari が使う
Config.weztermRatio = 2 / 3

-- display 3 のメイン+スタックに載せる Chrome ウィンドウ（スタックは上から順）
-- 会社ごとのドメインを含むため、中身は private リポジトリの modules/private.lua が持つ。
-- private を持たないマシンでは空のままで、ブラウザ配置のホットキーは登録されない。
Config.browserStack = {}

local ok, private = pcall(require, "modules.private")
if ok and type(private) == "table" and private.browserStack then
    Config.browserStack = private.browserStack
end

-- アプリごとのデフォルト配置モニタ設定 (Config.screenMapのキーを指定)
Config.appLayout = {
    ["WezTerm"]      = "4",
    ["Slack"]        = "1",
    ["Discord"]      = "1",
    ["LINE"]         = "1",
    ["Google Chrome"] = "3",
    ["Safari"]       = "4",
    ["Mail"]         = "1",
    ["iCal"]     = "1",
    ["Zoom.us"]      = "3",
    -- 他のアプリもここに追加
}

-- 接続されているモニタ数を確認する関数
function screenCount()
    return #hs.screen.allScreens()
end

function isSingleMonitor()
    return screenCount() == 1
end

-- 例：1画面の時だけ特別なメッセージを出す、などの分岐が可能
if isSingleMonitor() then
    hs.alert.show("外作業モード: 1画面最適化を適用します")
end

-- 共通ヘルパー関数もここに置いておくと便利
-- 第2引数は Lua パターンではなく素の文字列として扱う
function findScreen(name)
    if not name then return nil end
    return hs.fnutils.find(hs.screen.allScreens(), function(s)
        return s:name():find(name, 1, true) ~= nil
    end)
end

-- display 4 を「左: Safari / 右: WezTerm」に分けた枠を返す。
-- 左右をここで一括して求めるので、両者の間に隙間や重なりが出ない
function monitor4Frames(screen)
    local f = screen:fullFrame()
    local rightW = math.floor(f.w * (Config.weztermRatio or 2 / 3))
    local leftW  = f.w - rightW
    return
        { x = f.x,          y = f.y, w = leftW,  h = f.h },
        { x = f.x + leftW,  y = f.y, w = rightW, h = f.h }
end

-- screenMap のキーからスクリーンを引く。未接続なら nil と名前を返す
function findScreenByKey(key)
    local name = Config.screenMap[key]
    return findScreen(name), name
end

-- 起動時に screenMap のうち未接続のモニタを一度だけ知らせる
hs.timer.doAfter(1, function()
    if isSingleMonitor() then return end
    local missing = {}
    for key, name in pairs(Config.screenMap) do
        if not findScreen(name) then
            table.insert(missing, key .. ":" .. name)
        end
    end
    if #missing > 0 then
        table.sort(missing)
        hs.alert.show(screenCount() .. "画面モード / 未接続: " .. table.concat(missing, ", "))
    end
end)
