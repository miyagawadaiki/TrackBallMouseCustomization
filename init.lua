-- スクロールモード制御フラグ
local isScrollMode = false
local lastMousePosition = nil
local inactivityTimer = nil
local scrollSpeed = 10  -- スクロールの感度（大きくすると速くなる）

-- 拡大縮小モード制御フラグ
local isZoomMode = false
local zoomExecResolution = 20.0  -- ズームを実行する分解能
local totalMovementX = 0
local zoomExecThreshold = 0


local alertId = nil

function controlMode(mode)
	if mode == "Scroll" then
		if isScrollMode then
			exitScrollMode()
			return
		end

		if isZoomMode then
			exitZoomMode()
		--elseif isUndoMode then
		--	exitUndoMode()
		end

		enterScrollMode()
	
	elseif mode == "Zoom" then
		if isZoomMode then
			exitZoomMode()
			return
		end

		if isScrollMode then
			exitScrollMode()
		--elseif isUndoMode then
		--	exitUndoMode()
		end

		enterZoomMode()
	end
end


-- スクロールモードをスイッチする
function toggleScrollMode()
    if isScrollMode then
        exitScrollMode()
    else
        enterScrollMode()
    end
end

-- スクロールモードに入る
function enterScrollMode()
    isScrollMode = true
    lastMousePosition = hs.mouse.absolutePosition()
    showTempAlert("Scroll Mode ON", 0.4)
    startInactivityTimer()
end

-- スクロールモードから出る
function exitScrollMode()
    isScrollMode = false
    showTempAlert("Scroll Mode OFF", 0.4)
    if inactivityTimer then
        inactivityTimer:stop()
        inactivityTimer = nil
    end
end


-- ズームモードをスイッチする
function toggleZoomMode()
    if isZoomMode then
        exitZoomMode()
    else
        enterZoomMode()
    end
end

-- ズームモードに入る
function enterZoomMode()
    isZoomMode = true
    lastMousePosition = hs.mouse.absolutePosition()
	totalMovementX = 0.0
	zoomExecThreshold = 0.0
    showTempAlert("Zoom Mode ON", 0.4)
    startInactivityTimer()
end

-- ズームモードから出る
function exitZoomMode()
    isZoomMode = false
    showTempAlert("Zoom Mode OFF", 0.4)
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
		elseif isZoomMode then
			exitZoomMode()
        end
    end)
end

-- マウス移動を監視
mouseTracker = hs.eventtap.new({hs.eventtap.event.types.mouseMoved}, function(event)
    if not isScrollMode and not isZoomMode then return false end

    local currentPosition = hs.mouse.absolutePosition()
    if lastMousePosition then
		local dx = event:getProperty(hs.eventtap.event.properties['mouseEventDeltaX'])
		--local dx = currentPosition.x - lastMousePosition.x
		local dy = event:getProperty(hs.eventtap.event.properties['mouseEventDeltaY'])
		--local dy = currentPosition.y - lastMousePosition.y

		--print(string.format("Mouse moved: dx = %.2f, dy = %.2f", dx, dy))
		
		-- スクロール
		if isScrollMode then

			-- スクロールイベント送信（dyは方向反転）
			hs.eventtap.event.newScrollEvent({ -dx * scrollSpeed, -dy * scrollSpeed }, {}, "pixel"):post()

		-- ズーム
		else
			totalMovementX = totalMovementX + dx
			print(string.format("Mouse moved: dx = %.2f, total = %.2f", dx, totalMovementX))
			-- 拡大 or 縮小
			if dx > 0 and totalMovementX > zoomExecThreshold + zoomExecResolution then
				-- ズームインを実行
				hs.eventtap.keyStroke({"cmd"}, ";")
				-- 閾値を更新
				zoomExecThreshold = zoomExecThreshold + zoomExecResolution
			elseif dx < 0 and totalMovementX < zoomExecThreshold - zoomExecResolution then
				-- ズームアウトを実行
				hs.eventtap.keyStroke({"cmd"}, "-")
				-- 閾値を更新
				zoomExecThreshold = zoomExecThreshold - zoomExecResolution
			end
		end

		-- カーソルは元の位置に戻す
		hs.mouse.absolutePosition(lastMousePosition)
		--hs.mouse.absolutePosition(lastMousePosition)
    end

    --lastMousePosition = currentPosition
    startInactivityTimer()
    return false
end)

mouseTracker:start()

-- F1キーをスクロールのホットキーに割り当て
hs.hotkey.bind({}, "F1", function()
	controlMode("Scroll")
    --toggleScrollMode()
end)

-- F2キーをズームのホットキーに割り当て
hs.hotkey.bind({}, "F2", function()
	controlMode("Zoom")
    --toggleScrollMode()
end)
