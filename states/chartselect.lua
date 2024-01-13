local charts = require("chartloader")
local util   = require("util")
local vars   = require("vars")
local assets = require("assets")
local vec2   = require("lib.vector2")

local chartKeys = {}

for key, _ in pairs(charts) do
    table.insert(chartKeys, key)
end

table.sort(chartKeys)

local panelWidth = 500
local panelHeight = 50
local slope = 3
local width, height = 0, 0

local font = love.graphics.newFont(25)

local imageSize = vec2(assets.sprites.note:getDimensions())

local scrollOffset = 0

local timer = 0

local colV = 1

local function chartPanelPolygon(x, y)
    local xOff = -y / slope
    local nextXOff = -(y + panelHeight) / slope
    return
        width              + xOff     + x, y,               -- top right
        width - panelWidth + xOff     + x, y,               -- top left
        width - panelWidth + nextXOff + x, y + panelHeight, -- bottom left
        width              + nextXOff + x, y + panelHeight  -- bottom right
end

local function drawChartPanel(chart, x, y)
    local xOff = -y / slope
    local nextXOff = -(y + panelHeight) / slope
    love.graphics.setShader()
    love.graphics.setColor(colV, colV, colV, 1)
    love.graphics.print(chart.meta.artist .. " - " .. chart.meta.track, width - panelWidth + xOff + x, y + 10)
    love.graphics.print("charter: " .. chart.meta.charter, width - panelWidth + xOff + x, y + 40)
    love.graphics.setColor(util.hsv2rgb(y / panelHeight * 30 - timer * 30, 1, colV, 1))
    love.graphics.polygon("line", chartPanelPolygon(x, y))
    local scale = panelHeight / imageSize
    love.graphics.setShader(assets.shaders.recolor)
    love.graphics.draw(assets.sprites.note, width + xOff + x, y, 0, scale.x, scale.y)
end

local function chartPanelX(y)
    return --math.exp(-((vars.mousePos.y - (y + panelHeight / 2)) / panelHeight / 5) ^ 2) * 50 +
        math.sin(math.rad(y / 2) + timer) * 10
end

local function draw()
    love.graphics.setFont(font)
    width, height = love.graphics.getDimensions()
    panelHeight = 75
    local i = 0
    local panelIndex = math.floor((vars.mousePos.y + scrollOffset) / panelHeight)
    local y = panelIndex * panelHeight - scrollOffset
    love.graphics.setColor(colV, colV, colV, 0.1)
    love.graphics.polygon("fill", chartPanelPolygon(chartPanelX(y) - panelHeight, y))
    for _, key in ipairs(chartKeys) do
        local y = i * panelHeight - scrollOffset
        drawChartPanel(charts[key], chartPanelX(y) - panelHeight, y)
        i = i + 1
    end
end

local function update(dt)
    --scrollOffset = vars.mousePos.y
    timer = timer + dt
    local panelIndex = math.floor((vars.mousePos.y + scrollOffset) / panelHeight)
    local y = panelIndex * panelHeight - scrollOffset
    local xOff = -y / slope
    local x = chartPanelX(y) + xOff + width - panelHeight
    local mx, my = vars.mousePos.x, vars.mousePos.y
    print(vars.mouseVel:length())
    if panelIndex < #chartKeys and mx >= x and mx < x + panelHeight and 
        vars.mouseVel:normalize():dot(vec2(1, 0)) > 0.8 and vars.mouseVel:length() > 2000 then
        print("woah")
        util.loadState("gameplay").play(charts[chartKeys[panelIndex+1]])
    end
end

return {
    draw = draw,
    update = update
}