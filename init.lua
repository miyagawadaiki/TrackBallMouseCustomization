-- HANDLE SCROLLING

local deferred = false
local deferred_magnify = false
local scaled = false 

local function appTitle()
   app = hs.application.frontmostApplication()
   if app ~= nil then
      return app:title()
   end
end

overrideRightMouseDown = hs.eventtap.new({ hs.eventtap.event.types.rightMouseDown }, function(e)
    deferred = true
    print("down (deferred, scaled)=", deferred, scaled)
    return true
end)

overrideRightMouseUp = hs.eventtap.new({ hs.eventtap.event.types.rightMouseUp }, function(e)
    print("up")
    if (deferred and not scaled) then
        print('-- deferred, scaled=', deferred, scaled)
        overrideRightMouseDown:stop()
        overrideRightMouseUp:stop()
        deferred = false 
        hs.eventtap.rightClick(e:location())
        overrideRightMouseDown:start()
        overrideRightMouseUp:start()
        return true
    end

    print('-- deferred, scaled=', deferred, scaled)
    deferred = false 
    scaled = false
    return false
end)


local oldmousepos = {}
local scrollmult = -4   -- negative multiplier makes mouse work like traditional scrollwheel
dragRightToScroll = hs.eventtap.new({ hs.eventtap.event.types.rightMouseDragged }, function(e)
    -- print("scroll");
    deferred = false

    if appTitle() == 'Unity' then
        return false
    end


    oldmousepos = hs.mouse.getAbsolutePosition()    

    local dx = e:getProperty(hs.eventtap.event.properties['mouseEventDeltaX'])
    local dy = e:getProperty(hs.eventtap.event.properties['mouseEventDeltaY'])
    local scroll = hs.eventtap.event.newScrollEvent({dx * scrollmult, dy * scrollmult},{},'pixel')

    -- put the mouse back
    hs.mouse.setAbsolutePosition(oldmousepos)


    return true, {scroll}
end)


scrollToMagnify = hs.eventtap.new({ hs.eventtap.event.types.scrollWheel }, function(e)
    if not (deferred_magnify) then -- or hs.eventtap.checkMouseButtons().right
        return false
    end

    print('-- zoom')
    -- print('mouse name', hs.mouse.names())

    -- local wheel_x = e:getProperty(hs.eventtap.event.properties.scrollWheelEventDeltaAxis2)
    local wheel_val = e:getProperty(hs.eventtap.event.properties.scrollWheelEventDeltaAxis1)
    if wheel_val ~= 0 then
        -- scaled = true
        -- print(wheel_val)
        if wheel_val > 0 then
            print('-- -- zoom out')
            hs.eventtap.keyStroke({'cmd'}, '-', 100)
        else
            print('-- -- zoom in')
			if appTitle() == 'Notion' then
				print('-- -- -- Notion')
				hs.eventtap.keyStroke({'cmd'}, '^', 100)
			else
	            hs.eventtap.keyStroke({'shift','cmd'}, ';', 100)
			end
        end
    else
        
    end

    return true
end)


local magnifyButton = 2
overrideOtherMouseDown = hs.eventtap.new({
	hs.eventtap.event.types.otherMouseDown
}, function(e)
	local pressedMouseButton = e:getProperty(
								  hs.eventtap.event.properties['mouseEventButtonNumber'])
	-- ボタン2（ホイールのボタンを押した時の処理）
	if magnifyButton == pressedMouseButton then
		print(pressedMouseButton)

		-- もしGIMPを使っているときは無視
		if appTitle() == 'GIMP-2.10' then
			print('This is GIMP')
		-- ホイールによるズーム機能をスイッチする
		else
			-- 有効化する
			if not deferred_magnify then
				deferred_magnify = true
				print("switched to magnify")
				print("-- deferred_magnify, scaled=", deferred_magnify, scaled)
				return true
			-- 無効化する
			else
				deferred_magnify = false 
				return true
			end
		end
	end

	return false
end)

overrideOtherMouseUp = hs.eventtap.new({
	hs.eventtap.event.types.otherMouseUp
}, function(e)
    print("up")
	local pressedMouseButton = e:getProperty(
                                  hs.eventtap.event.properties['mouseEventButtonNumber'])
	if magnifyButton == pressedMouseButton then
		if deferred_magnify then
			print('-- deferred, scaled=', deferred_magnify, scaled)
			overrideOtherMouseDown:stop()
			overrideOtherMouseUp:stop()
			deferred_ = false 
			hs.eventtap.otherClick(e:location(), 0, pressedMouseButton)
			overrideOtherMouseDown:start()
			overrideOtherMouseUp:start()
			return true
		end
	end

    deferred_magnify = false 
    scaled = false
    print('-- deferred, scaled=', deferred_magnify, scaled)
    return false
end)



overrideRightMouseDown:start()
overrideRightMouseUp:start()
overrideOtherMouseDown:start()
overrideOtherMouseUp:start()
dragRightToScroll:start()
scrollToMagnify:start()
