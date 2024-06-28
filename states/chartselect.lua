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
local scrollVel = 0

local timer = 0

local colV = 1

local function chartPanelPolygon(x, y)
	local xOff = -y / slope
	local nextXOff = -(y + panelHeight) / slope
	return
		width			  + xOff	 + x, y,			   -- top right
		width - panelWidth + xOff	 + x, y,			   -- top left
		width - panelWidth + nextXOff + x, y + panelHeight, -- bottom left
		width			  + nextXOff + x, y + panelHeight  -- bottom right
end

local noteButtons = {
	
}

local function drawNoteButtons()
	for _, nb in ipairs(noteButtons) do
		local scale = panelHeight / imageSize
		love.graphics.setShader(assets.shaders.recolor)
		love.graphics.setColor(nb.color)
		love.graphics.draw(assets.sprites.note, width * (nb.x.per or 0) + (nb.x.pix or 0), height * (nb.y.per or 0) + (nb.y.pix or 0), nb.rot, scale.x, scale.y)
	end
end

local function chartListNote(self)
	util.loadState("gameplay").play(self.chart)
end

local function drawChartPanel(chart, x, y)
	local xOff = -y / slope
	local nextXOff = -(y + panelHeight) / slope
	love.graphics.setShader()
	love.graphics.setColor(colV, colV, colV, 1)
	love.graphics.print(chart.meta.artist .. " - " .. chart.meta.track, width - panelWidth + xOff + x, y + 10)
	love.graphics.print("charter: " .. chart.meta.charter, width - panelWidth + xOff + x, y + 40)
	local color = { util.hsv2rgb(y / panelHeight * 30 - timer * 30, 1, colV, 1) }
	love.graphics.setColor(color)
	love.graphics.polygon("line", chartPanelPolygon(x, y))
	table.insert(noteButtons, {
		func = chartListNote,
		chart = chart,
		x = {
			per = 1,
			pix = xOff + x
		},
		y = {
			per = 0,
			pix = y,
		},
		rot = 0,
		color = color
	})
end

local function chartPanelX(y)
	return --math.exp(-((vars.mousePos.y - (y + panelHeight / 2)) / panelHeight / 5) ^ 2) * 50 +
		math.sin(math.rad(y / 2) + timer) * 10
end

local function scrollVelButton(self)
	scrollVel = scrollVel + self.vel
end

local function draw()
	noteButtons = {}
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

	local xOff = ((height) / slope + width - panelWidth) / 2

	table.insert(noteButtons, {
		func = scrollVelButton,
		vel = -10,
		rot = -math.pi/2,
		x = {
			pix = xOff - panelHeight - panelHeight / slope,
			per = 0
 		},
		y = {
			per = 0,
			pix = panelHeight
		},
		color = {255, 255, 255}
	})

	table.insert(noteButtons, {
		func = scrollVelButton,
		vel = 10,
		rot = math.pi/2,
		x = {
			pix = xOff - (height / slope),
			per = 0
		},
		y = {
			per = 1,
			pix = -panelHeight
		},
		color = {255, 255, 255}
	})
	drawNoteButtons()
end

local function update(dt)
	timer = timer + dt
	scrollOffset = scrollOffset + scrollVel
	scrollVel = scrollVel * 0.9
	width, height = love.graphics.getDimensions()
	for i, nb in ipairs(noteButtons) do
		local mouseIn = nb.mouseIn
		nb.mouseIn = false
		local x = vars.mousePos.x - (width * nb.x.per) - nb.x.pix
		local y = vars.mousePos.y - (height * nb.y.per) - nb.y.pix
		local cos, sin = math.cos, math.sin
		x, y =
			cos(-nb.rot) * x - sin(-nb.rot) * y,
			cos(-nb.rot) * y + sin(-nb.rot) * x
		if x > 0 and x < panelHeight and y > 0 and y < panelHeight then
			local dx, dy = cos(nb.rot), sin(nb.rot)
			local dot = dx*vars.mouseVel.x + dy*vars.mouseVel.y
			if (dot > 1600) then
				if not mouseIn then
					print("hit note button:", i)
					nb:func()
				end
				print(mouseIn)
				nb.mouseIn = true
			end
		end
	end
end

return {
	draw = draw,
	update = update
}
