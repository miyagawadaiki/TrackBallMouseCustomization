-- モード自動終了までの時間
local autoExitDuration = 0.6

-- スクロールモード制御フラグ
local isScrollMode = false
local lastMousePosition = nil
local inactivityTimer = nil
local scrollSpeed = 20  -- スクロールの感度（大きくすると速くなる）

-- 拡大縮小モード
local isZoomMode = false  -- 制御フラグ
local zoomExecResolution = 30.0  -- ズームを実行する分解能
local zoomExecThreshold = 0      -- ズームを実行する閾値
local totalMovementY = 0  -- モード開始からの合計移動量


local alertId = nil


-- モードを制御する (命じられたモードを起動／終了させ、それまでのモードを終了させる)
function controlMode(mode)
	-- Scrollを命じられたとき
	if mode == "Scroll" then
		-- もしすでにScrollモードなら終わるだけ
		if isScrollMode then
			exitScrollMode()
			return
		end

		-- 他のモードが走っているなら終了させる
		if isZoomMode then
			exitZoomMode()
		--elseif isUndoMode then
		--	exitUndoMode()
		end

		-- Scrollモードを開始
		enterScrollMode()
	
	-- Zoomを命じられたとき
	elseif mode == "Zoom" then
		-- もしすでにZoomモードなら終わるだけ
		if isZoomMode then
			exitZoomMode()
			return
		end

		-- 他のモードが走っているなら終了させる
		if isScrollMode then
			exitScrollMode()
		--elseif isUndoMode then
		--	exitUndoMode()
		end

		-- Zoomモードを開始
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
	totalMovementY = 0.0
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
    inactivityTimer = hs.timer.doAfter(autoExitDuration, function()
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
			hs.eventtap.event.newScrollEvent({ -dx * scrollSpeed, dy * scrollSpeed }, {}, "pixel"):post()

		-- ズーム
		else
			totalMovementY = totalMovementY + dy
			--print(string.format("Mouse moved: dy = %.2f, total = %.2f", dy, totalMovementY))
			-- 拡大 or 縮小
			if dy > 0 and totalMovementY > zoomExecThreshold + zoomExecResolution then
				-- ズームインを実行
				hs.eventtap.keyStroke({"cmd"}, ";")
				-- 閾値を更新
				zoomExecThreshold = zoomExecThreshold + zoomExecResolution
			elseif dy < 0 and totalMovementY < zoomExecThreshold - zoomExecResolution then
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
