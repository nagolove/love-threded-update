-- original source https://github.com/love2d/love/issues/1723#issuecomment-899083939
local game_thread_code = [[
    require("love.timer")

    local event_channel = love.thread.getChannel("event_channel")
    local draw_ready_channel = love.thread.getChannel("draw_ready_channel")
    local graphic_command_channel = love.thread.getChannel("graphic_command_channel")

    local accum = 0
    
    local mx, my = 0, 0
    
    local time = love.timer.getTime()
    local dt = 0
    
    while true do
        local events = event_channel:pop()
        if events then
            for _,e in ipairs(events) do
                if e[1] == "mousemoved" then
                    mx = e[2]
                    my = e[3]
                end
            end
        end
        
        local nt = love.timer.getTime()
        dt = nt - time
        time = nt

        if draw_ready_channel:peek() then
            graphic_command_channel:push({ mx, my })
            graphic_command_channel:push(tostring( math.floor( 1 / dt ) ) )
            draw_ready_channel:pop()
        end
        love.timer.sleep(0.001)
    end
]]

io.stdout:setvbuf("no")

require("love.timer")
require("love.event")
require("love.thread")
require("love.window")
require("love.graphics")
require("love.font")

love.window.setMode(800, 600 )

function love.run()

    local game_thread = love.thread.newThread( game_thread_code )

    local event_channel = love.thread.getChannel("event_channel")
    local draw_ready_channel = love.thread.getChannel("draw_ready_channel")
    local graphic_command_channel = love.thread.getChannel("graphic_command_channel")
    graphic_command_channel:push({ 0, 0 })
    graphic_command_channel:push("0")
    
    game_thread:start()
    
    local time = love.timer.getTime()
    local dt = 0

	-- Main loop
	return function()
        
        if not game_thread:isRunning() then error(game_thread:getError()) end

        love.event.pump()
        local events = {}
        for name,a,b,c,d,e,f in love.event.poll() do
            if name == "quit" then return 0 end
            table.insert( events, {name, a, b, c, d, e, f} )
        end        
        event_channel:push( events )
                
        local nt = love.timer.getTime()
        dt = nt - time
        time = nt                
                
        draw_ready_channel:supply("ready")
        
        if love.graphics.isActive() then
            local mpos = graphic_command_channel:demand()
            local ups = graphic_command_channel:demand()
            
            love.graphics.origin()
			love.graphics.clear(love.graphics.getBackgroundColor())
            love.graphics.print(tostring(os.clock()), 10, 10 )
            love.graphics.print(("UPS: %s"):format(ups), 10, 20 )
            love.graphics.print(("FPS: %s"):format( tostring(math.floor( 1 / dt ) )), 10, 30)
            love.graphics.circle("fill", mpos[1], mpos[2], 10)
            love.timer.sleep(0.01)
			love.graphics.present()
        end
	end
end
