--    _        __
-- / /_)/_/ |/ / /_/ /|// \
--/ / \/ /  / / / / / */  /

local gameplay = require("gameplay")
local vec2 = require("lib.vector2")
require("objects")
local opt = require("options")
local charts = require("chartloader")

local lastMousePos = vec2(love.mouse.getPosition())
MouseVel = vec2(0, 0)


local callbacks = {
    update = function(dt)
        -- your code

        local mousePos = vec2(love.mouse.getPosition())
        MouseVel = (mousePos - lastMousePos) / dt
        lastMousePos = mousePos
    end,

    draw = function()
        -- your code
    end,

    mousepressed = function(x, y, button)
        -- your code

    end,

    mousereleased = function(x, y, button)
        -- your code

    end,

    keypressed = function(key, scancode, isrepeat)
        -- your code

        print(key, scancode)

    end,

    keyreleased = function(key)
        -- your code

    end,

    textinput = function(text)
        -- your code

    end,

    wheelmoved = function (x, y)
    end
}

function chartSelect()
    for key, value in pairs(callbacks) do
        love[key] = value
    end
    --list:SetVisible(true)
end

chartSelect()

gameplay.play(charts[opt.chartName])

--gameplay.play(require("options").chartName)
