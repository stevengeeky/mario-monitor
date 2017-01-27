--[[
    
    A Lua Script for created to monitor various basic info in Super Mario World
    By Steven O'Riley
    
]] --

local options = {
    timer_margin_top = 10 * 4 + 2,  -- Where to start placing timers at (like p-switch countdowns, multicoin timers, etc)
    timer_margin_left = 2,
    timer_show_actual_time = true,   -- Show the real-world time left until each timer will end
    
    frames_margin_left = 2,         -- Where to put the frame info at
    frames_margin_top = 2,
    frames_show_actual_time = true,  -- Whether or not to convert the number of frames to actual time
    
    player_info_margin_left = 2,   -- Where to put the player info at (speeds, positions, etc)
    player_info_margin_top = 512 - 10 * 17,
    
    grid_opacity = 230,             -- A number from 0 to 256, 0 being completely opaque and 256 completely translucent
    show_predictions = false,        -- Whether or not to auto-predict walljumps/corner-clips automatically on screen
    background = 150 * 16777216 + 0x000000,           -- Background for all text
    
    predict_opacity = 160,          -- What the opacity of predictions is
    
    show_box_color = 100 * 0x1000000 + 0x000000
}

local addresses = {
    xspeed = 0x7e007b,          -- 1byte (signed)
    xspeed_decimal = 0x7e007a,  -- 1byte
    yspeed = 0x7e007d,          -- 1byte (signed)
    xpos = 0x7e0094,            -- 2bytes
    xsub = 0x7e13da,            -- 1byte
    ypos = 0x7e0096,            -- 2bytes
    ysub = 0x7e13dc,            -- 1byte
    pmeter = 0x7e13e4,          -- 1byte
    takeoff = 0x7e149f,         -- 1byte
    score = 0x7e0f34,           -- 2bytes
    powerup = 0x7e0019,         -- 1byte
    direction = 0x7e0076,       -- 1byte
    blue_timer = 0x7e14ad,      -- 1byte
    gray_timer = 0x7e14ae,      -- 1byte
    coin_timer = 0x7e186b,      -- 1byte (multiple coin block timer)
    dir_coin_timer = 0x7e186b,  -- 1byte (directional coin block timer)
    pballoon = 0x7e1891,        -- 1byte
    star_timer = 0x7e1490,      -- 1byte
    hurt_timer = 0x7e1497,      -- 1byte
    
    counter = 0x7e0014,         -- 1byte
    xcam = 0x7e001A,            -- 2bytes
    ycam = 0x7e001C,            -- 2bytes
    
    mode = 0x7e0100
    
}

-- Oxymoronic greatness
local global = {
    timers_drawn = 0,
    real_x_res = 256,
    real_y_res = 256,
    
    xcam = 0,
    ycam = 0,
    last_xcam = 0,
    last_ycam = 0,
    dx = 0,
    dy = 0,
    
    left_gap = 100,
    right_gap = 100,
    top_gap = 0,
    bottom_gap = 0,
    gap_color = 0x222222,
    wh = gui.resolution(),
    
    show_box = false,
    show_box_x = 0,
    show_box_y = 0,
    last_mouse_left = 0
}

function main()
    global.timers_drawn = 0
    
    local mode = memory.readbyte(addresses.mode)
    global.wh = gui.resolution()
    global.xp = global.wh / global.real_x_res
    global.yp = global.wh / global.real_y_res
    
    -- Draw gaps
    draw_gap()
    
    -- Camera updating
    update_dcam_before()
    
    -- Frame updating
    draw_frames()
    
    if mode ~= 0x14 then return end
    
    -- Handle user inputs
    do_inputs()
    
    -- Draw the grid
    draw_grid()
    
    -- Predict Wall Jumps/Corner Clips
    if options.show_predictions then predict() end
    
    -- Do stuff with the box
    do_show_box()
    
    --[[ hurt_timer, blue_timer, gray_timer, coin_timer, dir_coin_timer, pballoon, star_timer ]]--
    draw_timer(addresses.hurt_timer, memory.readbyte, "Invincibility", 0xffffff, 1)
    draw_timer(addresses.blue_timer, memory.readbyte, "Blue P-Switch", 0xffffff, 4)
    draw_timer(addresses.gray_timer, memory.readbyte, "Gray P-Switch", 0xffffff, 4)
    draw_timer(addresses.coin_timer, memory.readbyte, "Coin Block", 0xffffff, 1)
    draw_timer(addresses.pballoon, memory.readbyte, "P-Balloon", 0xffffff, 4)
    draw_timer(addresses.star_timer, memory.readbyte, "Star Power", 0xffffff, 4)
    
    draw_sprite_info()
    
    draw_player_info()
    
    update_dcam_after()
    
end

function do_show_box()
    if global.show_box then
        local U = transform(global.show_box_x, global.show_box_y)
        local scw, sch = 16 * global.xp, 16 * global.yp
        local width = 13 * 16
        local block_x = global.show_box_x * 16
        
        local xspeed, xpos, xsub, yspeed, ypos, ysub = memory.readsbyte(addresses.xspeed), memory.readword(addresses.xpos), memory.readbyte(addresses.xsub), memory.readsbyte(addresses.yspeed), memory.readword(addresses.ypos), memory.readbyte(addresses.ysub)
        
        local x = xpos * 16 + xsub / 16
        local y = ypos * 16 + ysub / 16
        local wj, cc = false, false
        
        if xspeed < 0 and xpos > global.show_box_x + width / 16 then
            local temp_x = x + xspeed * math.ceil((block_x + width - x) / xspeed);
            local difference = (temp_x - block_x) / 16
            
            if difference < 11 and xspeed < -32 then
                wj = true
            end
            if (difference == 11 or difference < 10) and xspeed < -48 then
                cc = true
            end
            
            for i = 0, math.ceil(global.wh / 16) do
                local color, backcolor = 0xffffff, nil
                if i == 0 then
                    if wj then color = 0xffffff; backcolor = 0x0000ff end
                    if cc then color = 0xffffff; backcolor = 0xff0000 end
                end
                
                local _x = temp_x - xspeed * i
                local _xsub = _x % 16
                local _xpos = (_x - _xsub) / 16
                _xsub = _xsub * 16
                
                gui.text(-global.left_gap + 2, 2 + i * 16, string.format("%d.%02x", _xpos, _xsub), color, backcolor)
            end
        elseif xspeed > 0 and xpos + width / 16 < global.show_box_x then
            local temp_x = x + xspeed * math.ceil((block_x - x - width) / xspeed);
            local difference = (block_x - temp_x) / 16
            
            if difference < 11 and xspeed > 32 then
                wj = true
            end
            if (difference == 11.0625 or difference < 10) and xspeed > 48 then
                cc = true
            end
            
            for i = 0, math.ceil(global.wh / 16) do
                local color, backcolor = 0xffffff, nil
                if i == 0 then
                    if wj then color = 0xffffff; backcolor = 0x0000ff end
                    if cc then color = 0xffffff; backcolor = 0xff0000 end
                end
                
                local _x = temp_x - xspeed * i
                local _xsub = _x % 16
                local _xpos = (_x - _xsub) / 16
                _xsub = _xsub * 16
                
                gui.text(-global.left_gap + 2, 2 + i * 16, string.format("%d.%02x", _xpos, _xsub), color, backcolor)
            end
        end
        
        if xpos > global.show_box_x + width / 16 then
            local simulator = Simulator:new()
            simulator.input.run = true
            simulator.input.left = true
            
            while simulator.player.x > block_x + width do
                simulator:advance()
                
                local temp_x = simulator.player.x + simulator.player.xspeed * math.ceil((block_x + width - simulator.player.x) / simulator.player.xspeed);
                local difference = (temp_x - block_x) / 16
                
                --gui.text(100, 50 + 16 * simulator.frame_count, string.format("%d.%02x, %d", (simulator.player.x - simulator.player.x % 16) / 16, simulator.player.x % 16,simulator.player.xspeed))
                
                if difference < 11 and simulator.player.xspeed < -32 then
                    wj = true
                end
                if (difference == 11 or difference < 10) and simulator.player.xspeed < -48 then
                    cc = true
                    break
                end
            end
            
            if cc then gui.text(2, 430, string.format("CC in %d frames", simulator.frame_count), 0xffffff, options.background) end
            
        elseif xpos + width / 16 < global.show_box_x then
            local simulator = Simulator:new()
            simulator.input.right = true
            simulator.input.run = true
            
            while simulator.player.x + width < block_x do
                simulator:advance()
                
                local temp_x = simulator.player.x + simulator.player.xspeed * math.ceil((block_x - simulator.player.x - width) / simulator.player.xspeed);
                local difference = (block_x - temp_x) / 16
                
                --gui.text(100, 100 + 16 * simulator.frame_count, string.format("P: %d", simulator.player.pmeter))
                
                if difference < 11 and simulator.player.xspeed > 32 then
                    wj = true
                end
                if (difference == 11.0625 or difference < 10) and simulator.player.xspeed > 48 then
                    cc = true
                    break
                end
                
            end
            
            if cc then gui.text(2, 430, string.format("CC in %d frames", simulator.frame_count), 0xffffff, options.background) end
            
        end
        
        gui.rectangle(U.x, U.y, scw, sch, options.show_box_color, options.show_box_color)
    end
end

function do_inputs()
    if input_get("mouse_left") == 1 and global.last_mouse_left == 0 then
        local x, y = input_get("mouse_x") - global.left_gap, input_get("mouse_y") - global.top_gap
        local T = untransform(x, y)
        T = { x = T.x - T.x % 16, y = T.y - T.y % 16 }
        
        if not global.show_box or (global.show_box and (global.show_box_x ~= T.x or global.show_box_y ~= T.y)) then
            global.show_box = true
            global.show_box_x = T.x
            global.show_box_y = T.y
        else
            global.show_box = false
        end
        
    end
    
    global.last_mouse_left = input_get("mouse_left")
end

function draw_grid()
    if options.grid_opacity == 0 then return end
    
    local origin = untransform(0, 0)
    local mod_origin = {
        x = origin.x - origin.x % 16,
        y = origin.y - origin.y % 16
    }
    
    for x = mod_origin.x, mod_origin.x + global.wh / global.xp, 16 do
        local x1y1, x2y2 = transform(x, origin.y), transform(x, origin.y + global.wh / global.yp)
        gui.line(x1y1.x, x1y1.y, x2y2.x, x2y2.y, options.grid_opacity * 16777216 + 0xffffff)
    end
    for y = mod_origin.y, mod_origin.y + global.wh / global.yp, 16 do
        local x1y1, x2y2 = transform(origin.x, y), transform(origin.x + global.wh / global.xp, y)
        gui.line(x1y1.x, x1y1.y, x2y2.x, x2y2.y, options.grid_opacity * 16777216 + 0xffffff)
    end
    
end

-- Predicting
function predict()
    local xspeed, xpos, xsub, yspeed, ypos, ysub = memory.readsbyte(addresses.xspeed), memory.readword(addresses.xpos), memory.readbyte(addresses.xsub), memory.readsbyte(addresses.yspeed), memory.readword(addresses.ypos), memory.readbyte(addresses.ysub)
    
    -- Position in subpixels
    local x = xpos * 16 + xsub / 16
    local y = ypos * 16 + ysub / 16
    local width = 13 * 16
    
    local scw = 16 * global.xp
    local count = 0
    
    if xspeed > 0 then
        local start = transform((xpos + width / 16) - (xpos + width / 16) % 16 + 16, ypos - ypos % 16 + 16)
        
        for i = start.x, global.wh - global.wh % scw + scw, scw do
            local block_x = untransform(i, 0).x * 16
            local frames = math.ceil((block_x - x - width) / xspeed)
            local temp_x = x + frames * xspeed
            local difference = (block_x - temp_x) / 16
            
            if difference < 11 and xspeed > 32 then
                gui.rectangle(i, 0, 16 * global.xp, global.wh, 0xaaffff, 16777216 * options.predict_opacity + 0xaaffff)
            end
            if (difference == 11.0625 or difference < 10) and xspeed > 48 then
                gui.rectangle(i, 0, 16 * global.xp, global.wh, 0xffaaff, 16777216 * options.predict_opacity + 0xffaaff)
            end
            
            count = count + 1
        end
    elseif xspeed < 0 then
        local start = untransform(0, 0)
        local stop = transform(xpos - 16, ypos)
        start.x = start.x - start.x % 16
        start = transform(start.x, start.y)
        
        for i = start.x, stop.x, scw do
            local block_x = untransform(i, 0).x * 16
            local frames = math.ceil((block_x + width - x) / xspeed)
            local temp_x = x + frames * xspeed
            local difference = (temp_x - block_x) / 16
            
            if difference < 11 and xspeed < -32 then
                gui.rectangle(i, 0, 16 * global.xp, global.wh, 0xaaffff, 16777216 * options.predict_opacity + 0xaaffff)
            end
            if (difference == 11 or difference < 10) and xspeed < -48 then
                gui.rectangle(i, 0, 16 * global.xp, global.wh, 0xffaaff, 16777216 * options.predict_opacity + 0xffaaff)
            end
            
            count = count + 1
        end
    end
end

function draw_player_info()
    local xspeed, xpos, xsub, yspeed, ypos, ysub = memory.readsbyte(addresses.xspeed), memory.readword(addresses.xpos), memory.readbyte(addresses.xsub), memory.readsbyte(addresses.yspeed), memory.readword(addresses.ypos), memory.readbyte(addresses.ysub)
    
    local pmeter, takeoff = memory.readbyte(addresses.pmeter), memory.readbyte(addresses.takeoff)
    local res = gui.resolution()
    
    gui.text( options.player_info_margin_left, options.player_info_margin_top, string.format("%02d.%02d, %d.%02x\n%02d, %d.%02x\n%d, %d", xspeed, memory.readbyte(addresses.xspeed_decimal) / 0x100 * 100, xpos, xsub, yspeed, ypos, ysub, pmeter, takeoff), 0xffffff, options.background )
end

function draw_sprite_info()
    local count, max = 0, 12
    local palette = {
        0xffffff,
        0xff9090,
        0x80ff80,
        0xa0a0ff,
        0xffff80,
        0xff80ff,
        0x80ffff
    }
    
    for i = 0, max - 1 do
        local status = memory.readbyte(0x7e14c8 + i)
        
        if status ~= 0 then
            local x = memory.readsbyte(0x7e14e0 + i) * 0x100 + memory.readbyte(0x7e00e4 + i)
            local y = memory.readsbyte(0x7e14d4 + i) * 0x100 + memory.readbyte(0x7e00d8 + i)
            local xsub = memory.readbyte(0x7e14f8 + i)
            local ysub = memory.readbyte(0x7e14ec + i)
            local xspeed = memory.readbyte(0x7e00b6 + i)
            local yspeed = memory.readbyte(0x7e00aa + i)
            
            local screenP = transform(x, y)
            
            local drawX = clamp( screenP.x, 2, global.wh - 28 )
            local drawY = clamp( screenP.y, 2, global.wh - 10 )
            local color = palette[1 + i % #palette]
            
            gui.text(350, 2 + count * 16, string.format("#%02d [%d.%02x, %d.%02x]", i, x, xsub, y, ysub), color, options.background)
            
            gui.text(drawX, drawY, string.format("#%02d", i), color, options.background)
            
            count = count + 1
        end
    end
    
end

function draw_gap()
    if global.left_gap ~= 0 then gui.left_gap(global.left_gap) end
    if global.right_gap ~= 0 then gui.right_gap(global.right_gap) end
    if global.top_gap ~= 0 then gui.top_gap(global.top_gap) end
    if global.bottom_gap ~= 0 then gui.bottom_gap(global.bottom_gap) end
    
    gui.rectangle(-global.left_gap, -global.top_gap, global.left_gap, global.wh, global.gap_color, global.gap_color)
    
    gui.rectangle(-global.left_gap, -global.top_gap, global.wh, global.top_gap, global.gap_color, global.gap_color)
    
    gui.rectangle(-global.left_gap, global.wh, global.wh, global.bottom_gap, global.gap_color, global.gap_color)
    
    gui.rectangle(global.wh, -global.top_gap, global.right_gap, global.wh, global.gap_color, global.gap_color)
    
end

function draw_frames()
    local current_frame = movie.currentframe()
    local num_frames = movie.framecount()
    
    local text = string.format("%d / %d", current_frame, num_frames)
    if options.frames_show_actual_time then
        text = text .. string.format("\n%s / %s", frames_to_time(current_frame), frames_to_time(num_frames))
    end
    
    gui.text( options.frames_margin_left, options.frames_margin_top, text, 0xffffff, options.background )
end

function draw_timer(address, callable, name, color, multiplier)
    local value = callable(address)
    if value ~= 0 then
        if multiplier ~= 1 then
            value = value * multiplier - memory.readbyte(addresses.counter) % multiplier
        end
        
        local text = string.format("%s: %d", name, value)
        if options.timer_show_actual_time then
            text = text .. string.format(" (%s)", frames_to_time(value))
        end
        
        gui.text(options.timer_margin_left, options.timer_margin_top + 8 * global.timers_drawn, text, color, options.background)
        global.timers_drawn = global.timers_drawn + 1
    end
end

function frames_to_time(frames)
    local days, hours, minutes, seconds, frame = nil, nil, nil, nil, nil
    local result_string = ""
    
    frame = frames % 60         -- 60 frames in 1 second
    frames = (frames - frame) / 60
    
    if frames ~= 0 then
        seconds = frames % 60       -- 60 seconds in 1 minute
        frames = (frames - seconds) / 60
    end
    
    if frames ~= 0 then
        minutes = frames % 60       -- 60 minutes in 1 hour
        frames = (frames - minutes) / 60
    end
    
    if frames ~= 0 then
        hours = frames % 24         -- 24 hours in 1 day
        frames = (frames - hours) / 24
    end
    
    if frames ~= 0 then
        days = frames
    end
    
    result_string = string.format("%02d", frame)
    if seconds ~= nil then result_string = string.format("%02d|", seconds) .. result_string end
    if minutes ~= nil then result_string = string.format("%02d:", minutes) .. result_string end
    if hours ~= nil then result_string = string.format("%02d:", hours) .. result_string end
    if days ~= nil then result_string = string.format("%02d:", days) .. result_string end
    
    return result_string
end

-- Transforms a point on the viewWindow to a point in the game
function untransform(orig_x, orig_y, multiplier)
    if not multiplier then multiplier = 1 end
    
    return {
        x = orig_x / global.xp + global.xcam * multiplier - global.dx,
        y = orig_y / global.yp + global.ycam * multiplier - global.dy
    }
end

-- Transforms a point in the game to a point on the viewWindow
function transform(orig_x, orig_y, multiplier)
    if not multiplier then multiplier = 1 end
    
    return {
        x = (orig_x - global.xcam * multiplier + global.dx) * global.xp,
        y = (orig_y - global.ycam * multiplier + global.dy) * global.yp
    }
end

function update_dcam_before()
    global.xcam = memory.readword(addresses.xcam)
    global.ycam = memory.readword(addresses.ycam)
    
    if global.last_xcam ~= 0 then global.dx = global.xcam - global.last_xcam end
    if global.last_ycam ~= 0 then global.dy = global.ycam - global.last_ycam end
end

function update_dcam_after()
    global.last_xcam = global.xcam
    global.last_ycam = global.ycam
end

function clamp(v, a, b)
    if a > b then
        local temp = a
        a = b
        b = temp
    end
    
    if v < a then v = a end
    if v > b then v = b end
    
    return v
end

Array = {}
function Array:new(o)
    o = o or {}
    setmetatable(o, self)
    
    self.__current = #o
    self.__index = self
    
    return o
end
function Array:push(value)
    self[self.__current] = value
    self.__current = self.__current + 1
end
function Array:pop(value)
    local temp = self[self.__current]
    self.__current = self.__current - 1
    self[self.__current] = nil
    return temp
end
function Array:length()
    return self.__current
end

Simulator = {}
function Simulator:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    
    self.input = {
        right = false,
        left = false,
        up = false,
        down = false,
        A = false,
        B = false,
        run = false,
        start = false,
        select = false
    }
    self.player = {
        xspeed = memory.readsbyte(addresses.xspeed),
        xspeed_decimal = memory.readbyte(addresses.xspeed_decimal) / 0x100 * 2,
        xcap = 37,
        xdelta = 2,
        pmeter = memory.readbyte(addresses.pmeter),
        x = memory.readword(addresses.xpos) * 16 + memory.readbyte(addresses.xsub) / 16
    }
    self.frame_count = 0
    
    return o
end
function Simulator:advance()
    self.frame_count = self.frame_count + 1
    
    self.player.x = self.player.x + self.player.xspeed
    
    if math.abs(self.player.xspeed) >= 35 and (self.input.left or self.input.right) then
        self.player.pmeter = math.min(self.player.pmeter + 2, 112)
    else
        self.player.pmeter = math.max(self.player.pmeter - 1, 0)
    end
    
    if self.player.pmeter == 112 then self.player.xcap = 49 end
    
    if self.input.left == true then
        if self.player.xspeed <= 0 then
            if self.player.xspeed < -self.player.xcap then
                self.player.xspeed = self.player.xspeed + 1
            elseif self.player.xspeed == -self.player.xcap and self.player.xspeed_decimal == 1 then self.player.xspeed = -self.player.xcap + 1
            elseif self.player.xspeed == -self.player.xcap + 1 and self.player.xspeed_decimal == 1 then self.player.xspeed = -self.player.xcap + 2
            elseif self.player.xspeed == -self.player.xcap + 2 and self.player.xspeed_decimal == 1 then self.player.xspeed = -self.player.xcap + 1; self.player.xspeed_decimal = 0
            elseif self.player.xspeed == -self.player.xcap + 1 and self.player.xspeed_decimal == 0 then self.player.xspeed = -self.player.xcap + 2
            elseif self.player.xspeed == -self.player.xcap + 2 and self.player.xcap == 0 then self.player.xspeed = -self.player.xcap; self.player.xspeed_decimal = 1
            else
                if self.player.xspeed_decimal == 1 then
                    self.player.xspeed = self.player.xspeed - 1
                    self.player.xspeed_decimal = 0
                else
                    self.player.xspeed = self.player.xspeed - 2
                    self.player.xspeed_decimal = 1
                end
            end
        else
            self.player.xspeed = self.player.xspeed - 5
        end
    elseif self.input.right == true then
        if self.player.xspeed >= 0 then
            if self.player.xspeed > self.player.xcap then
                self.player.xspeed = self.player.xspeed - 1
            else
                if self.player.xspeed_decimal == 1 then
                    self.player.xspeed = self.player.xspeed + 2
                    self.player.xspeed_decimal = 0
                else
                    self.player.xspeed = self.player.xspeed + 1
                    self.player.xspeed_decimal = 1
                end
                
                if self.player.xspeed > self.player.xcap or (self.player.xspeed == self.player.xcap and self.player.xspeed_decimal == 1) then
                    local new_speed = self.player.xspeed + self.player.xspeed_decimal * .5 - 2.5
                    
                    if math.floor(new_speed) ~= new_speed then self.player.xspeed_decimal = 1 else self.player.xspeed_decimal = 0 end
                    
                    self.player.xspeed = new_speed - self.player.xspeed_decimal * .5
                end
            end
        else
            self.player.xspeed = self.player.xspeed + 5
        end
    else
        --Evaluate only if the player is grounded
        --[[if self.player.xspeed > 0 then self.player.xspeed = self.player.xspeed - 1 end
        if self.player.xspeed < 0 then self.player.xspeed = self.player.xspeed + 1 end
        
        self.player.pmeter = math.max(self.player.pmeter - 1, 0)
        ]]
        if self.player.xspeed == 0 then self.player.xspeed_decimal = 0 end
    end
    
end

-- Other helper functions
function input_get(reference)
    return input.raw()[reference]["last_rawval"]
end

-- Handle main() every frame
function on_paint()
    
    main()
    
    return
end