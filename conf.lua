function love.conf(t)
    local opt = require("options")
    
    t.console = true
    t.window.resizable = true
    t.window.fullscreen = opt.fullscreen
    t.window.vsync = opt.vsync
end