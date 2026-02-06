-- modules/window.lua

-- 1/3分割
local function resizeThird(pos)
    local win = hs.window.focusedWindow()
    if not win then return end
    local f = win:screen():fullFrame()
    local thirdWidth = f.w / 3
    local newFrame = { y = f.y, w = thirdWidth, h = f.h }
    if pos == "left" then newFrame.x = f.x
    elseif pos == "center" then newFrame.x = f.x + thirdWidth
    elseif pos == "right" then newFrame.x = f.x + (thirdWidth * 2) end
    win:setFrame(newFrame, 0)
end

-- 2/3分割
local function resizeTwoThirds(pos)
    local win = hs.window.focusedWindow()
    if not win then return end
    local f = win:screen():fullFrame()
    local twoThirdsWidth = f.w * (2/3)
    local newFrame = { y = f.y, w = twoThirdsWidth, h = f.h }
    if pos == "left" then newFrame.x = f.x
    elseif pos == "right" then newFrame.x = f.x + (f.w - twoThirdsWidth) end
    win:setFrame(newFrame, 0)
end

-- 1/2分割
local function resizeHalf(pos)
    local win = hs.window.focusedWindow()
    if not win then return end
    local f = win:screen():fullFrame()
    local newFrame = { y = f.y, w = f.w / 2, h = f.h }
    newFrame.x = (pos == "left") and f.x or (f.x + f.w / 2)
    win:setFrame(newFrame, 0)
end

-- --- キーバインド設定 ---

-- 1/3分割 (D/F/G)
hs.hotkey.bind({"ctrl", "alt"}, "d", function() resizeThird("left") end)
hs.hotkey.bind({"ctrl", "alt"}, "f", function() resizeThird("center") end)
hs.hotkey.bind({"ctrl", "alt"}, "g", function() resizeThird("right") end)

-- 2/3分割 (E/R)
hs.hotkey.bind({"ctrl", "alt"}, "e", function() resizeTwoThirds("left") end)
hs.hotkey.bind({"ctrl", "alt"}, "r", function() resizeTwoThirds("right") end)

-- 1/2分割 (矢印)
hs.hotkey.bind({"ctrl", "alt"}, "left", function() resizeHalf("left") end)
hs.hotkey.bind({"ctrl", "alt"}, "right", function() resizeHalf("right") end)

-- 全画面 (Enter)
hs.hotkey.bind({"ctrl", "alt"}, "return", function()
    local win = hs.window.focusedWindow()
    if win then win:setFrame(win:screen():fullFrame(), 0) end
end)
