local objectMeta = require("objects")

local charts = {}

local function loadChart(dir)
    local chart = {}
    local path = "charts/" .. dir .. "/"
    for i, item in ipairs(love.filesystem.getDirectoryItems("charts/" .. dir)) do
        print(item)
        if item:sub(1, 5) == "audio" then
            chart.audio = love.sound.newSoundData(path .. item)
        end
    end
    local file = love.filesystem.newFile(path .. "chart.ch", "r")
    chart.objects = {}
    local timeAcc = 0
    for line in file:lines() do
        local values = {}
        for match in string.gmatch(line, "[^%s]+") do
            table.insert(values, match)
        end

        if not chart.bpm then
            chart.bpm = tonumber(values[1])
            chart.offset = tonumber(values[2])
            chart.bt = 60 / chart.bpm
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
            table.insert(chart.objects, object)
        end
    end

    chart.duration = timeAcc * chart.bt
    chart.meta = require("charts." .. dir .. ".meta")

    return chart
    
end

for i, dir in ipairs(love.filesystem.getDirectoryItems("charts")) do
    print(dir)
    charts[dir] = loadChart(dir)
end

return charts
