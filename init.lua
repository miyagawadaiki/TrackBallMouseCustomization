local scrollMode = false
local zoomMode = false
local undoMode = false

-- 変数の監視
-- F1キーを押すたびにモードをトグル
hs.hotkey.bind({}, "F1", function()
    scrollMode = not scrollMode
    print("Scroll mode: ", scrollMode)
    --hs.alert.show("Scroll mode: " .. (scrollMode and "ON" or "OFF"), 0.3)
end)
hs.hotkey.bind({}, "F2", function()
    zoomMode = not zoomMode
    print("Zoom mode: ", zoomMode)
    --hs.alert.show("Zoom mode: " .. (zoomMode and "ON" or "OFF"), 0.3)
end)
hs.hotkey.bind({}, "F3", function()
    undoMode = not undoMode
    --hs.alert.show("undo mode: " .. (undoMode and "ON" or "OFF"), 0.3)
end)


-- マウス移動を監視してスクロールに変換
local eventTap = hs.eventtap.new({hs.eventtap.event.types.mouseMoved}, function(e)
    if scrollMode then
        local dx = e:getProperty(hs.eventtap.event.properties.mouseEventDeltaX)
        local dy = e:getProperty(hs.eventtap.event.properties.mouseEventDeltaY)
        print(dx, dy)
        hs.eventtap.scrollWheel({-dy, -dx}, {}, "pixel")
        return true
    elseif zoomMode then
        local dx = e:getProperty(hs.eventtap.event.properties.mouseEventDeltaX)
        print(dx)
        if dx > 0 then
            print("zoom in")
            hs.eventtap.keyStroke({"cmd"}, ";")
        elseif dx < 0 then
            print("zoom out")
            hs.eventtap.keyStroke({"cmd"}, "-")
        else
            print("not zoom") 
        end
        return true
    end
    return false
end):start()

-- スクロールホイールで Command+Z / Y
local scrollTap = hs.eventtap.new({hs.eventtap.event.types.scrollWheel}, function(e)
    if undoMode then
        local dy = e:getProperty(hs.eventtap.event.properties.scrollWheelEventDeltaAxis1)
        if dy > 0 then
            hs.eventtap.keyStroke({"cmd","shift"}, "z")
        elseif dy < 0 then
            hs.eventtap.keyStroke({"cmd"}, "z")
        end
        return true
    end
    return false
end):start()
