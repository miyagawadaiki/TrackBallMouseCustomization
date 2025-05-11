-- モード自動終了までの時間
local autoExitDuration = 0.6

-- スクロールとズームを許すフラグ
local isScrollAndZoomMode = false

-- スクロールモード制御フラグ
local isScrollMode = false
local lastMousePosition = nil
local inactivityTimer = nil
local scrollSpeed = 20  -- スクロールの感度（大きくすると速くなる）

-- 拡大縮小モード
local isZoomMode = false  -- 制御フラグ
--local zoomExecResolution = 30.0  -- ズームを実行する分解能
--local zoomExecThreshold = 0      -- ズームを実行する閾値
--local totalMovementY = 0  -- モード開始からの合計移動量


local alertId = nil


function toggleScrollAndZoom()
    if isScrollAndZoomMode then
        exitScrollAndZoomMode()
    else
        enterScrollAndZoomMode()
    end
end

-- スクロール&ズームモードに入る
function enterScrollAndZoomMode()
    isScrollAndZoomMode = true
	isScrollMode = false
	isZoomMode = false
    lastMousePosition = hs.mouse.absolutePosition()
    showTempAlert("Scroll & Zoom Mode ON", 0.4)
    startInactivityTimer()
end

-- スクロール&ズームモードから出る
function exitScrollAndZoomMode()
    isScrollAndZoomMode = false
    showTempAlert("Scroll & Zoom Mode OFF", 0.4)
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
        if isScrollAndZoomMode then
            exitScrollAndZoomMode()
        end
    end)
end

-- マウス移動を監視
mouseTracker = hs.eventtap.new({hs.eventtap.event.types.mouseMoved}, function(event)
    if not isScrollAndZoomMode then return false end

	if not isScrollMode then
		isScrollMode = true
		return true
	end

    local currentPosition = hs.mouse.absolutePosition()
    if lastMousePosition then
		-- マウスの移動量を得る
		local dx = event:getProperty(hs.eventtap.event.properties['mouseEventDeltaX'])
		--local dx = currentPosition.x - lastMousePosition.x
		local dy = event:getProperty(hs.eventtap.event.properties['mouseEventDeltaY'])
		--local dy = currentPosition.y - lastMousePosition.y
		--print(string.format("Mouse moved: dx = %.2f, dy = %.2f", dx, dy))
		
		-- スクロールイベント送信（dyは方向反転）
		hs.eventtap.event.newScrollEvent({ -dx * scrollSpeed, dy * scrollSpeed }, {}, "pixel"):post()

		-- カーソルは元の位置に戻す
		hs.mouse.absolutePosition(lastMousePosition)
    end

    --lastMousePosition = currentPosition
	
	-- モードを延長
    startInactivityTimer()
    return false
end)

mouseTracker:start()


-- ホイールを監視
wheelTracker = hs.eventtap.new({hs.eventtap.event.types.scrollWheel}, function(event)
	-- もしスクロールモードが始まっていたらそちらを優先
    if isScrollMode or not isScrollAndZoomMode then return false end

	-- スクロール量を取得
	local wheelVal = event:getProperty(hs.eventtap.event.properties.scrollWheelEventDeltaAxis1)

	-- スクロールの向きによってズームインかアウトか決める
	if wheelVal > 0 then
		--print("zoom in")
		hs.eventtap.keyStroke({'cmd'}, ';')
	elseif wheelVal < 0 then
		--print("zoom out")
		hs.eventtap.keyStroke({'cmd'}, '-')
	else

	end

	-- モードを延長
    startInactivityTimer()
	return false
end)

wheelTracker:start()



-- F1キーをスクロールのホットキーに割り当て
hs.hotkey.bind({}, "F5", function()
	toggleScrollAndZoom()
end)







-- 変換キーを押したら「かな入力」に切り替える（macOSのIME）
-- 変換キーの keyCode は環境により異なる（Karabiner EventViewer で確認）
-- 一般的には keyCode = 102（JISキーボードの変換キー）
local IME_KANA_KEYCODE = 138  -- 変換キーの keyCode をここに指定
hs.eventtap.new({hs.eventtap.event.types.keyDown}, function(event)
	if event:getKeyCode() == IME_KANA_KEYCODE then
		hs.keycodes.setInputMethod("com.apple.inputmethod.Kotoeri.Japanese")  -- 日本語入力に切り替え
		return true
	end
	return false
end):start()


-- 無変換キーや英数キーの keyCode（例: 104）は環境により異なるので確認してください
local EISUU_KEYCODE = 139  -- 無変換キーや英数キーの keyCode
hs.eventtap.new({hs.eventtap.event.types.keyDown}, function(event)
  if event:getKeyCode() == EISUU_KEYCODE then
    hs.keycodes.setInputMethod("com.apple.keylayout.ABC")  -- 英字入力に切り替え
    return true  -- macOS のデフォルト動作をブロック
  end
  return false
end):start()

