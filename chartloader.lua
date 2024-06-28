local objectMeta = require("objects")

local charts = {}

local function chart_load(self)
	if self.loaded then return end
	local path = "charts/" .. self.directory .. "/"
	for i, item in ipairs(love.filesystem.getDirectoryItems("charts/" .. self.directory)) do
		print(item)
		if item:sub(1, 5) == "audio" then
			self.audio = love.sound.newSoundData(path .. item)
		end
	end
	local file = love.filesystem.newFile(path .. "chart.ch", "r")
	self.objects = {}
	local timeAcc = 0
	for line in file:lines() do
		local values = {}
		for match in string.gmatch(line, "[^%s]+") do
			table.insert(values, match)
		end

		if not self.bpm then
			self.bpm = tonumber(values[1])
			self.offset = tonumber(values[2])
			self.bt = 60 / self.bpm
		elseif #values > 1 then
			local object = objectMeta[values[2]].constructor(unpack(values))
			local delay = values[1]
			local slashPos = string.find(delay, "/")
			if slashPos then
				delay = tonumber(delay:sub(1, slashPos - 1)) / tonumber(delay:sub(slashPos + 1))
			else
				delay = tonumber(delay)
			end
			timeAcc = timeAcc + delay
			object.time = timeAcc
			object.delay = delay
			object.type = values[2]
			object.render = objectMeta[values[2]].render
			object.update = objectMeta[values[2]].update
			table.insert(self.objects, object)
		end
	end

	self.duration = timeAcc * self.bt
	self.loaded = true
	
end

local function loadChart(dir)
	local chart = {}
	chart.meta = require("charts." .. dir .. ".meta")
	chart.directory = dir
	chart.load = chart_load
	chart.loaded = false

	return chart
	
end

for i, dir in ipairs(love.filesystem.getDirectoryItems("charts")) do
	charts[dir] = loadChart(dir)
end



return charts
