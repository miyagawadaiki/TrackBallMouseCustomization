-- スクロールモード制御フラグ
local isScrollMode = false
local lastMousePosition = nil
local inactivityTimer = nil
local scrollSpeed = 10  -- スクロールの感度（大きくすると速くなる）

local alertId = nil

function toggleScrollMode()
    if isScrollMode then
        exitScrollMode()
    else
        enterScrollMode()
    end
end

function enterScrollMode()
    isScrollMode = true
    lastMousePosition = hs.mouse.absolutePosition()
    showTempAlert("Scroll Mode ON", 0.4)
    startInactivityTimer()
end

function exitScrollMode()
    isScrollMode = false
    showTempAlert("Scroll Mode OFF", 0.4)
    if inactivityTimer then
        inactivityTimer:stop()
        inactivityTimer = nil
    end
end

function showTempAlert(message, duration)
    if alertId then
        hs.alert.closeSpecific(alertId)
    end
    alertId = hs.alert.show(message, {}, hs.screen.mainScreen(), duration)
end

function startInactivityTimer()
    if inactivityTimer then inactivityTimer:stop() end
    inactivityTimer = hs.timer.doAfter(1, function()
        if isScrollMode then
            exitScrollMode()
        end
    end)
end

-- マウス移動を監視
mouseTracker = hs.eventtap.new({hs.eventtap.event.types.mouseMoved}, function(event)
    if not isScrollMode then return false end

    local currentPosition = hs.mouse.absolutePosition()
    if lastMousePosition then
        local dx = event:getProperty(hs.eventtap.event.properties['mouseEventDeltaX'])
        --local dx = currentPosition.x - lastMousePosition.x
        local dy = event:getProperty(hs.eventtap.event.properties['mouseEventDeltaY'])
        --local dy = currentPosition.y - lastMousePosition.y

        --print(string.format("Mouse moved: dx = %.2f, dy = %.2f", dx, dy))

        -- スクロールイベント送信（dyは方向反転）
        hs.eventtap.event.newScrollEvent({ -dx * scrollSpeed, -dy * scrollSpeed }, {}, "pixel"):post()

		-- カーソルは元の位置に戻す
		hs.mouse.absolutePosition(lastMousePosition)
		--hs.mouse.absolutePosition(lastMousePosition)
    end

    --lastMousePosition = currentPosition
    startInactivityTimer()
    return false
end)

mouseTracker:start()

-- F1キーをホットキーに割り当て
hs.hotkey.bind({}, "F1", function()
    toggleScrollMode()
end)

