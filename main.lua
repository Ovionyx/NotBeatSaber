--    _        __
-- / /_)/_/ |/ / /_/ /|//
--/ / \/ /  / / / / / */ 

local util = require("util")
local vec2 = require("lib.vector2")
require("objects")
local opt = require("options")
local charts = require("chartloader")
local vars = require("vars")

local lastMousePos = vec2(love.mouse.getPosition())
MouseVel = vec2(0, 0)

local call = function (func, ...)
    if func then
        func(...)
    end
end

love.mouse.setRelativeMode(true)

local callbacks = {
    update = function(dt)
        --vars.mousePos = vec2(love.mouse.getPosition())
        vars.mouseVel = (vars.mousePos - lastMousePos) / dt
        lastMousePos = vars.mousePos
        call(vars.state.update, dt)
    end,

    draw = function()
        call(vars.state.draw)
        love.graphics.circle("fill", vars.mousePos.x, vars.mousePos.y, 5)
    end,

    mousemoved = function(x, y, dx, dy, istouch)
        local w, h = love.graphics.getDimensions()
        vars.mousePos = vars.mousePos + vec2(dx, dy)
        vars.mousePos.x = vars.mousePos.x % w
        vars.mousePos.y = vars.mousePos.y % h
    end,

    mousepressed = function(x, y, button)
        call(vars.state.mousepressed, x, y, button)
    end,

    mousereleased = function(x, y, button)
        call(vars.state.mousereleased, x, y, button)
    end,

    keypressed = function(key, scancode, isrepeat)
        call(vars.state.keypressed, key, scancode, isrepeat)
    end,

    keyreleased = function(key)
        call(vars.state.keyreleased, key)
    end,

    textinput = function(text)
        call(vars.state.textinput, text)
    end,

    wheelmoved = function(x, y)
        call(vars.state.wheelmoved, x, y)
    end
}

function chartSelect()
    for key, value in pairs(callbacks) do
        love[key] = value
    end
    --list:SetVisible(true)
end

chartSelect()

util.loadState("chartselect")

--gameplay.play(require("options").chartName)
