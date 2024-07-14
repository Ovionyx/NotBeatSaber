local mouseTrail = {}
local vec2 = require("lib.vector2")
local util = require("util")
local vars = require("vars")
local objects = require("objects")

charts = {}
local assets = {}

local mouseVel = vec2(0, 0)

local songSource
local samplesRead = 0

local bufferSize
local buffer
local volume

local timesPlayed = 0

CurrentSong = nil

local opt = require("options")
bufferSize = opt.bufferSize

local lastHitNote

local particles = {
	pos = vec2(0, 0),
	vel = vec2(0, 0),
	lifetime = 1,
	rot = 0,
	rotvel = 0,
	scale = 1,
	scalevel = 0,
	update = nil, --func
	render = nil, --func
}

scoreTexts = {}
local center = vec2(love.graphics.getDimensions()) / 2

local metaTexts = {
	song = {},
	charter = {},
}
metaTexts.song.font = love.graphics.newFont("assets/fonts/bold.otf", 50)
metaTexts.charter.font = love.graphics.newFont("assets/fonts/bold.otf", 30)

local fonts = {
	stats = love.graphics.newFont("assets/fonts/regular.otf", 15),
	combo = love.graphics.newFont("assets/fonts/regular.otf", 25)
}

local playbackSpeed = 1
local lastPlaybackSpeed = 1
local paused = false
local deathTimer = 0

local timer = 0

local function recursiveClone(t)
	local ret = {}
	for k, v in pairs(t) do
		if type(v) == "table" and not getmetatable(v) then
			ret[k] = recursiveClone(v)
		else
			ret[k] = v
		end
	end

	return ret
end

local function newScoresText(score, x, y)
	local ret = {}
	ret.score = score
	ret.x = x
	ret.y = y
	ret.age = 0
	table.insert(scoreTexts, ret)
end


local function noteArc(startNote, endNote, t)
	local dt = endNote.time - startNote.time
	local startVec = startNote.pos
	local startDir = startNote.dir * 4 * dt
	local endVec = endNote.pos
	local endDir = endNote.dir * 4 * dt
	return util.bezier(startVec, startVec+startDir, endVec-endDir, endVec, t)
end

local lastMousePos = vec2(love.mouse.getPosition())

local timerPeaks = {}
local timerStarts = {}

local function startTimer(timer)
	timerStarts[timer] = os.clock()
end

local function endTimer(timer)
	local time = (os.clock() - timerStarts[timer]) * 1000
	local peak = timerPeaks[timer]
	if not peak or peak < time then
		print("Timer '" .. timer .. "' took " .. tostring(time) .. " ms")
		timerPeaks[timer] = time
	end
end

local callbacks = {
	update = function(dt)
		startTimer("loadSamples")
		while songSource:getFreeBufferCount() > 0 do
			for i = 0, bufferSize - 1 do
				for c = 1, CurrentSong:getChannelCount() do
					buffer:setSample(i, c,
						CurrentSong:getSample(
							math.max(math.min(i * playbackSpeed + samplesRead, CurrentSong:getSampleCount() - 1), 0),
							c) * volume
					)
				end
			end
			samplesRead = samplesRead + bufferSize * playbackSpeed
			songSource:queue(buffer)
			songSource:play()
		end
		endTimer("loadSamples")

		if vars.gameplay.energy == 0 then
			playbackSpeed = math.max(0, playbackSpeed - dt*0.2)
		elseif paused then
			playbackSpeed = math.max(0, playbackSpeed - dt)
		else
			playbackSpeed = math.min(1, playbackSpeed + dt)
		end

		local activeChart = vars.gameplay.activeChart

		local time = samplesRead / activeChart.audio:getSampleRate()
		local j = 1
		for i = 1, math.min(#activeChart.objects, 10), 1 do
			if activeChart.objects[j]:update(time, i == 1) then
				lastHitNote = activeChart.objects[j]
				table.remove(activeChart.objects, 1)
			else
				j = j + 1
			end
		end

		for index, value in pairs(objects) do
			if value.staticUpdate then
				value.staticUpdate(dt, time)
			end
		end

		if vars.gameplay.energy == 0 then
			deathTimer = deathTimer + dt
		end

		if time > activeChart.duration then
			volume = (1 - (time - activeChart.duration) / 3)
		end

		if deathTimer > 5 or time - activeChart.duration > 3 then
			util.loadState("chartselect")
		end

		local nextTexts = {}
		for index, text in ipairs(scoreTexts) do
			text.age = text.age + dt
			if text.age < 1 then
				table.insert(nextTexts, text)
			end
		end
		scoreTexts = nextTexts

		table.insert(mouseTrail, 1, vars.mousePos)
		while #mouseTrail > 10 do
			mouseTrail[11] = nil
		end
		if #mouseTrail > 2 then
			mouseVel = ((mouseTrail[1] - mouseTrail[2]) / dt)
		end

		timer = timer + dt

		if timer < 5 then
			metaTexts.song.pos[1] =
				math.lerp(metaTexts.song.pos[1], love.graphics.getDimensions() - metaTexts.song.text:getWidth(), 0.02)
			metaTexts.charter.pos[1] =
				math.lerp(metaTexts.charter.pos[1], love.graphics.getDimensions() - metaTexts.charter.text:getWidth(), 0.02)
		else
			metaTexts.song.pos[1] =
				math.lerp(metaTexts.song.pos[1], love.graphics.getDimensions(), 0.02)
			metaTexts.charter.pos[1] =
				math.lerp(metaTexts.charter.pos[1], love.graphics.getDimensions(), 0.02)
		end
		
	end,

	draw = function()
		startTimer "draw"
		startTimer "mouseTrail"
		if #mouseTrail < 3 then return end
		local coords = {}
		for i, point in ipairs(mouseTrail) do
			coords[i * 2 - 1] = point.x
			coords[i * 2] = point.y
		end
		endTimer "mouseTrail"

		local activeChart = vars.gameplay.activeChart

		local time = samplesRead / CurrentSong:getSampleRate()

		startTimer "renderObjects"
		for i = math.min(#activeChart.objects, 150), 1, -1 do
			activeChart.objects[i]:render(time)
		end
		endTimer "renderObjects"

		startTimer "scoreTexts"
		for index, text in ipairs(scoreTexts) do
			love.graphics.setColor(255, 255, 255, 1 - text.age)
			local pos = util.toScreenCoords(text.x, text.y) + text.vel * (1 - (1 - text.age) ^ opt.indExp) / 20
			local rot = text.rot * (1 - text.age ^ opt.indExp)
			love.graphics.draw(text.text, pos.x, pos.y, rot, 1, 1, text.text:getWidth()/2, text.text:getHeight()/2)
		end
		endTimer "scoreTexts"

		love.graphics.setShader()

		love.graphics.setColor(util.hsv2rgb(time * 60, 1, 1))

		love.graphics.setLineWidth(1)

		love.graphics.polygon("fill", coords)

		startTimer "staticRenders"
		for index, value in pairs(objects) do
			if value.staticRender then
				startTimer("staticRenders."..index)
				value.staticRender(time)
				endTimer("staticRenders."..index)
			end
		end
		endTimer "staticRenders"

		if opt.auto and lastHitNote and activeChart.objects[1] then
			local bezPoint = noteArc(lastHitNote, activeChart.objects[1],
				(time - lastHitNote.time * activeChart.bt) / activeChart.objects[1].delay / activeChart.bt)
			local bezScreen = util.toScreenCoords(bezPoint.x, bezPoint.y)
			love.graphics.ellipse("fill", bezScreen.x, bezScreen.y, 10, 10)
			--love.mouse.setPosition(bezScreen.x, bezScreen.y)
		end

		love.graphics.rectangle("line", 10, 10, 200, 10)
		love.graphics.rectangle("fill", 10, 10, vars.gameplay.energy * 2, 10)
		love.graphics.setFont(fonts.stats)
		love.graphics.print(tostring(vars.gameplay.score), 10, 30)
		love.graphics.print(tostring(math.floor(vars.gameplay.score / 2 / math.max(vars.gameplay.noteCount, 1))) .. "%",
			180, 30)
		love.graphics.setFont(fonts.combo)
		love.graphics.print(tostring(vars.gameplay.streak), 10, 45)

		love.graphics.draw(metaTexts.song.text, unpack(metaTexts.song.pos))
		love.graphics.draw(metaTexts.charter.text, unpack(metaTexts.charter.pos))
		endTimer "draw"

	end,

	keypressed = function (key, scancode, repeated)
		print(key, scancode)
		if key == "escape" then
			paused = not paused
			if not paused then
				playbackSpeed = -1
			end
		end
	end
}

local function play(chart)
	chart:load()
	util.loadState("gameplay")
	timer = 0
	vars.gameplay.energy = 50
	vars.gameplay.score = 0
	vars.gameplay.streak = 0
	volume = 1
	deathTimer = 0
	timesPlayed = timesPlayed + 1
	local activeChart = recursiveClone(chart)
	vars.gameplay.activeChart = activeChart
	CurrentSong = activeChart.audio
	songSource = love.audio.newQueueableSource(
		CurrentSong:getSampleRate(),
		CurrentSong:getBitDepth(),
		CurrentSong:getChannelCount()
	)
	--songSource:setPitch(opt.pitch)
	buffer = love.sound.newSoundData(bufferSize,
		CurrentSong:getSampleRate(),
		CurrentSong:getBitDepth(),
		CurrentSong:getChannelCount()
	)
	samplesRead = CurrentSong:getSampleRate() * (activeChart.offset / 1000 + opt.startBeat * activeChart.bt)
	local new = {}
	for index, value in ipairs(activeChart.objects) do
		if value.time >= opt.startBeat + (opt.auto and 0 or 4) then
			table.insert(new, value)
		end
	end
	activeChart.objects = new
	metaTexts.song.pos = {({love.graphics.getDimensions()})[1], 0}
	metaTexts.song.text = love.graphics.newText(metaTexts.song.font, activeChart.meta.artist .. " - " .. activeChart.meta.track)
	metaTexts.charter.pos = {({love.graphics.getDimensions()})[1], 60}
	metaTexts.charter.text = love.graphics.newText(metaTexts.charter.font, activeChart.meta.charter)

	songSource:play()

	print(#objects)
	
end



love.audio.setVolume(0.2)

return {
	play = play,
	update = callbacks.update,
	draw = callbacks.draw,
	keypressed = callbacks.keypressed
}
