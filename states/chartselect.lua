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
local halfPanelHeight = panelHeight / 2
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

local difficultyNotes = {
	
}

local selectedChart
local chartSelected = false
local shift = 0
local selectedDifficulty

local function difficultyToColor(dif)
	return util.hsv2rgb(210 - dif * 30, 0.7, 1, 1)
end

local function drawNoteButtons()
	for _, nb in ipairs(noteButtons) do
		local scale = panelHeight / imageSize
		love.graphics.setShader(assets.shaders.recolor)
		love.graphics.setColor(nb.color)
		love.graphics.draw(assets.sprites.note, width * (nb.x.per or 0) + (nb.x.pix or 0), height * (nb.y.per or 0) + (nb.y.pix or 0), nb.rot, scale.x, scale.y, imageSize.x / 2, imageSize.y / 2)
	end
end

local function difficultyNote(self)
	selectedDifficulty = self.difficulty
end

local function chartListNote(self)
	if shift < 0.5 and not chartSelected then
		-- util.loadState("gameplay").play(self.chart)
		local oldChart = selectedChart
  	selectedChart = self.chart
  	if not selectedChart.loaded then
			selectedChart:load()
  		selectedChart.source = love.audio.newSource(selectedChart.audio)
  		selectedChart.source:setVolume(0)
  		selectedChart.source:setLooping(true)
  	end
  	if oldChart ~= selectedChart then
  		selectedChart.source:seek((selectedChart.meta.previewStart or 0) * selectedChart.bt)
  	end
  	selectedChart.source:play()
  	chartSelected = true
  	for i, dif in ipairs(selectedChart.meta.difficulties) do
			difficultyNotes[i] = {
				func = difficultyNote,
				difficulty = i,
				color = {difficultyToColor(dif.difficulty)},
				t = 0,
				rot = math.atan2(slope, -1)
			}
		end
  	return true
  end
  if shift > 0.5 and chartSelected and selectedChart == self.chart then
  	chartSelected = false
  	return true
	end
end

local function drawChartPanel(chart, x, y)
	x = x - shift * width
	local xOff = -y / slope
	local nextXOff = -(y + panelHeight) / slope
	love.graphics.setShader()
	love.graphics.setColor(colV, colV, colV, 1)
	love.graphics.print(chart.meta.artist .. " - " .. chart.meta.track, width - panelWidth + xOff + x, y + 10)
	love.graphics.print("charter: " .. chart.meta.charter, width - panelWidth + xOff + x, y + 40)
	local color = { util.hsv2rgb(y / panelHeight * 30 - timer * 30, 1, colV, 1) }
	love.graphics.setColor(color)
	love.graphics.polygon("line", chartPanelPolygon(x, y))
	local notex = xOff + x + halfPanelHeight
	if chart == selectedChart then
		notex = math.lerp(notex, x + 2 * panelHeight, shift)
	end
	table.insert(noteButtons, {
		func = chartListNote,
		chart = chart,
		x = {
			per = 1,
			pix = notex
		},
		y = {
			per = 0,
			pix = y + halfPanelHeight,
		},
		rot = chart == selectedChart and shift * math.pi or 0,
		color = color
	})
end

local function chartPanelX(y)
	return --math.exp(-((vars.mousePos.y - (y + panelHeight / 2)) / panelHeight / 5) ^ 2) * 50 +
		math.sin(math.rad(y / 2) + timer) * 10
end

local function scrollVelButton(self)
	if math.abs(scrollVel - self.vel) > 5 then
		scrollVel = scrollVel + self.vel
		return true
	end
end

local function playChartNote(self)
	for _, chart in pairs(charts) do
		if chart.source then
			chart.source:stop()
		end
	end
	util.loadState("gameplay").play(selectedChart, selectedDifficulty)
end

local function drawSelectedChart()
	print(selectedChart.meta.difficulties)
	local difficulties = selectedChart.meta.difficulties
	local basex = 2 * width - shift * width - panelHeight * #difficulties - panelWidth / slope - panelHeight * 2
	for i, v in ipairs(difficulties) do
		local sin = math.sin(timer + i) * 10
		love.graphics.setColor(1, 1, 1, 1)
		local x = basex + i * (panelHeight + 10) - sin / slope 
		local bottomy = height - panelHeight * 3 + sin
		love.graphics.print(v.name, x + 5, bottomy - 5 * slope, -math.atan(slope))
		love.graphics.setColor(difficultyToColor(v.difficulty))
		love.graphics.polygon("line", x, bottomy, x + panelHeight, bottomy,
			x + panelHeight + panelWidth / slope, bottomy - panelWidth,
			x + panelWidth / slope, bottomy - panelWidth)
		for i = 1, v.difficulty do
			love.graphics.setColor(difficultyToColor(i))
			love.graphics.draw(assets.sprites.chevron, x + (i - 1) * 15 / slope + 50, -25 + bottomy - 15 * i + 15, 0, 0.2, 0.2)
		end
		local note = difficultyNotes[i]
		note.x = {
			pix = x + halfPanelHeight - 10 - note.t * halfPanelHeight / slope,
			per = 0
		}
		note.y = {
			pix = bottomy + halfPanelHeight + 10 * slope + note.t * halfPanelHeight,
			per = 0
		}
		table.insert(noteButtons, note)
	end
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
	love.graphics.polygon("fill", chartPanelPolygon(chartPanelX(y) - panelHeight - width * shift, y))
	for _, key in ipairs(chartKeys) do
		local y = i * panelHeight - scrollOffset
		drawChartPanel(charts[key], chartPanelX(y) - panelHeight, y)
		i = i + 1
	end

	local xOff = ((height) / slope + width - panelWidth) / 2

	table.insert(noteButtons, {
		func = scrollVelButton,
		vel = -80,
		rot = -math.pi/2,
		x = {
			pix = xOff - halfPanelHeight - panelHeight / slope,
			per = -shift
 		},
		y = {
			per = 0,
			pix = panelHeight
		},
		color = {255, 255, 255}
	})

	table.insert(noteButtons, {
		func = scrollVelButton,
		vel = 80,
		rot = math.pi/2,
		x = {
			pix = xOff - (height / slope),
			per = - shift
		},
		y = {
			per = 1,
			pix = -panelHeight
		},
		color = {255, 255, 255}
	})

	table.insert(noteButtons, {
		func = playChartNote,
		rot = 0,
		x = {
			per = 2 - shift,
			pix = -panelHeight
		},
		y = {
			per = 1,
			pix = -panelHeight
		},
		color = {255, 255, 255}
	})

	if shift > 0.01 and selectedChart then
		drawSelectedChart()
  end
	
	drawNoteButtons()
end

local function update(dt)
	timer = timer + dt
	scrollOffset = scrollOffset + scrollVel * 60 * dt
	vars.mousePos.y = vars.mousePos.y - scrollVel * 60 * dt
	width, height = love.graphics.getDimensions()
	local t = 0.5 ^ (dt * 3)
	scrollVel = scrollVel * 0.5 ^ (dt * 10)
	shift = math.lerp(chartSelected and 1 or 0, shift, t)
	for i, nb in ipairs(noteButtons) do
		local mouseIn = nb.mouseIn
		nb.mouseIn = false
		local x = vars.mousePos.x - (width * nb.x.per) - nb.x.pix
		local y = vars.mousePos.y - (height * nb.y.per) - nb.y.pix
		local cos, sin = math.cos, math.sin
		x, y =
			cos(-nb.rot) * x - sin(-nb.rot) * y,
			cos(-nb.rot) * y + sin(-nb.rot) * x
		if x > -halfPanelHeight and x < halfPanelHeight and y > -halfPanelHeight and y < halfPanelHeight then
			local dx, dy = cos(nb.rot), sin(nb.rot)
			local dot = dx*vars.mouseVel.x + dy*vars.mouseVel.y
			if (dot > 1600) then
				if not mouseIn then
					print("hit note button:", i)
					if nb:func() then
						assets.sounds.kick:seek(0)
						assets.sounds.kick:play()
					end
				end
				print(mouseIn)
				nb.mouseIn = true
			end
		end
	end
	for _, chart in pairs(charts) do
		if chart.source then
			if chart == selectedChart then
				chart.source:setVolume(math.min(chart.source:getVolume() + dt, 1))
			else
				chart.source:setVolume(math.max(chart.source:getVolume() - dt, 0))
			end
    end
	end
	local t = 0.5 ^ (dt * 10)
	for i, note in ipairs(difficultyNotes) do
		if note.difficulty == selectedDifficulty then
			note.t = math.lerp(1, note.t, t)
		else
			note.t = math.lerp(0, note.t, t)
		end
	end
end

return {
	draw = draw,
	update = update
}
