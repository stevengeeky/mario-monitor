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
    show_predictions = true,        -- Whether or not to auto-predict walljumps/corner-clips automatically on screen
    background = 150 * 16777216 + 0x000000,           -- Background for all text
    
    predict_opacity = 160
}

local addresses = {
    xspeed = 0x7e007b,          -- 1byte (signed)
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
    xcam = 0x7e001A,            -- 2byte
    ycam = 0x7e001C,            -- 2byte
    
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
    wh = gui.resolution()
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
    
    -- Draw the grid
    draw_grid()
    
    -- Predict Wall Jumps/Corner Clips
    if options.show_predictions then predict() end
    
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

function draw_grid()
    if options.grid_opacity == 0 then return end
    
    local origin = untransform(0, 0)
    local mod_origin = {
        x = origin.x - origin.x % 16,
        y = origin.y - origin.y % 16
    }
    
    for x = mod_origin.x, mod_origin.x + global.wh, 16 do
        local x1y1, x2y2 = transform(x, origin.y), transform(x, origin.y + global.wh)
        gui.line(x1y1.x, x1y1.y, x2y2.x, x2y2.y, options.grid_opacity * 16777216 + 0xffffff)
    end
    for y = mod_origin.y, mod_origin.y + global.wh, 16 do
        local x1y1, x2y2 = transform(origin.x, y), transform(origin.x + global.wh, y)
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
    
    gui.text( options.player_info_margin_left, options.player_info_margin_top, string.format("%02d, %d.%02x\n%02d, %d.%02x\n%d, %d", xspeed, xpos, xsub, yspeed, ypos, ysub, pmeter, takeoff), 0xffffff, options.background )
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

-- Handle main() every frame
function on_paint()
    
    main()
    
    return
end