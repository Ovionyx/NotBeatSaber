--    _        __
-- / /_)/_/ |/ / /_/ /|// \
--/ / \/ /  / / / / / */  /

local loveframes = require("lib.loveframes")
--loveframes.SetActiveSkin("Default")
local gameplay = require("gameplay")
local vec2 = require("lib.vector2")


local list = loveframes.Create("list")
list:SetSize(love.graphics.getDimensions())

local chartObjects = {}
for key, value in pairs(charts) do
    local panel = loveframes.Create("panel", list)
    panel:SetHeight(100)
    local note = loveframes.Create("menunote", panel)
    note.x = 200
    note:SetSize(100, 100)
    logTable(note)
    local song = loveframes.Create("text", panel)
    song:SetText(value.meta.artist .. " - " .. value.meta.track)
    local charter = loveframes.Create("text", panel)
    charter:SetText(value.meta.charter)
    charter:SetPos(0, 50)
    function note:OnHit()
        gameplay.play(key)
        list:SetVisible(false)
    end
    chartObjects[key] = panel
end

local lastMousePos = vec2(love.mouse.getPosition())
MouseVel = vec2(0, 0)


local callbacks = {
    update = function(dt)
        -- your code

        local mousePos = vec2(love.mouse.getPosition())
        MouseVel = (mousePos - lastMousePos) / dt
        lastMousePos = mousePos

        loveframes.update(dt)
    end,

    draw = function()
        -- your code

        loveframes.draw()
    end,

    mousepressed = function(x, y, button)
        -- your code

        loveframes.mousepressed(x, y, button)
    end,

    mousereleased = function(x, y, button)
        -- your code

        loveframes.mousereleased(x, y, button)
    end,

    keypressed = function(key, scancode, isrepeat)
        -- your code

        print(key, scancode)

        loveframes.keypressed(key, isrepeat)
    end,

    keyreleased = function(key)
        -- your code

        loveframes.keyreleased(key)
    end,

    textinput = function(text)
        -- your code

        loveframes.textinput(text)
    end
}

function chartSelect()
    for key, value in pairs(callbacks) do
        love[key] = value
    end
    list:SetVisible(true)
end

chartSelect()

--gameplay.play(require("options").chartName)
