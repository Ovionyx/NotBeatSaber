function serializeTable(t, indent)
    indent = indent or 1
    if type(t) == "table" then
        local str = tostring(t) .. " {\n"
        for k, v in pairs(t) do
            str = str .. string.rep("    ", indent) .. "[" .. k .. "] = " .. serializeTable(v, indent + 1) .. ",\n"
        end
        str = str .. string.rep("    ", indent - 1) .. "}"
        return str
    else
        return tostring(t)
    end
end

function logTable(t)
    print(serializeTable(t))
end

local mouseTrail = {}
local vec2 = require("lib.vector2")
local socket = require("socket")

local unit = 0

local charts = {}
local assets = {}

local energy = 50
local score = 0
local streak = 0
local mouseVel = vec2(0, 0)

local songSource
local activeChart
local samplesRead = 0

local bufferSize = 128
local buffer

CurrentSong = nil

local opt = {
    indDist = 2,
    indExp = 4,
    indDur = 1,
    startBeat = 32,
    pitch = 1,
    auto = true
}

local scoreTexts = {}

function recursiveClone(t)
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

function newScoresText(score, x, y)
    local ret = {}
    ret.score = score
    ret.x = x
    ret.y = y
    ret.age = 0
    table.insert(scoreTexts, ret)
end

function math.lerp(a,b,t)
    return t*(b-a)+a
end

function bezier(p0, p1, p2, p3, t)
    return
        p0*(-t^3+3*t^2-3*t+1) +
        p1*(3*t^3-6*t^2+3*t) +
        p2*(-3*t^3+3*t^2) +
        p3*(t^3)
end

function hsv2rgb(h, s, v, a)
    s = 1 - s
    local i = h/60 % 6
    local r, g, b

    if i < 1 then --red to yellow
        r = v
        g = math.lerp((i % 1), 1, s) * v
        b = s  *v
    elseif i < 2 then --yellow to green
        r = math.lerp((1 - i % 1), 1, s) * v
        g = v
        b = s * v
    elseif i < 3 then --green to cyan
        r = s * v
        g = v
        b = math.lerp((i % 1), 1, s) * v
    elseif i < 4 then --cyan to blue
        r = s * v
        g = math.lerp((1 - i % 1), 1, s) * v
        b = v
    elseif i < 5 then --blue to magenta
        r = math.lerp((i % 1), 1, s) * v
        g = s * v
        b = v
    else --magenta to red
        r = v
        g = s * v
        b = math.lerp((1 - i % 1), 1, s) * v
    end

    return r, g, b, a
end

function noteArc(startNote, endNote, t)
    local startVec = startNote.pos
    local startDir = startNote.dir * 3
    local endVec = endNote.pos
    local endDir = endNote.dir * 3
    return bezier(startVec, startVec+startDir, endVec-endDir, endVec, t)
end

local objectMeta = {
    std = {
        constructor = function (_, _, x, y, rot, ox, oy)
            rot = math.rad(tonumber(rot))
            x = tonumber(x)
            y = tonumber(y)
            ox = tonumber(ox) or 0
            oy = tonumber(oy) or 0
            return {
                x = x,
                y = y,
                rot = rot,
                ox = ox,
                oy = oy,
                dir = vec2(math.cos(rot), math.sin(rot)),
                pos = vec2((ox * math.cos(rot) - oy * math.sin(rot)) + x, (ox * math.sin(rot) + oy * math.cos(rot)) + y)
            }
        end,

        render = function(self, time)
            local dt = (time - self.time * activeChart.bt) / opt.indDur
            if dt < -1 then return end

            love.graphics.setShader(assets.shaders.recolor)
            love.graphics.setColor(hsv2rgb(self.time*30, 1, 1, 1+dt))

            local rot = self.rot

            local imageScale = vec2(assets.sprites.note:getPixelDimensions())
            local center = imageScale / 2

            local dtExp = (1 - (1 + dt) ^ opt.indExp) * opt.indDist

            local objPos = vec2(love.graphics.getDimensions()) / 2 +
                vec2(self.x - 5, self.y - 5) * getUnit() / (1 - dt * 0.75 * opt.indDur) +
                vec2((self.ox * math.cos(rot) - self.oy * math.sin(rot)) * unit,
                     (self.ox * math.sin(rot) + self.oy * math.cos(rot)) * unit)

            love.graphics.draw(assets.sprites.note, objPos.x, objPos.y, rot,
                unit / imageScale.x, unit / imageScale.y, center.x, center.y)

            local objPos = vec2(love.graphics.getDimensions()) / 2 +
                vec2(self.x - 5, self.y - 5) * getUnit() +
                vec2((self.ox * math.cos(rot) - self.oy * math.sin(rot)) * unit,
                     (self.ox * math.sin(rot) + self.oy * math.cos(rot)) * unit)

            love.graphics.draw(assets.sprites.indicator,
                objPos.x - math.cos(rot) * dtExp * unit,
                objPos.y - math.sin(rot) * dtExp * unit,
                rot,
                unit / imageScale.x,
                unit / imageScale.y,
                center.x, center.y)
        end,

        update = function (self, time, first)
            local dt = (time - self.time * activeChart.bt)
            if dt > 0.2 then
                energy = math.max(energy - 10, 0)
                assets.sounds.miss:seek(0)
                assets.sounds.miss:play()
                streak = 0
                return true
            end

            if mouseTrail[1] and dt > (first and -0.2 or 0) then
                local rot = self.rot
                local pos = toScreenCoords(
                    self.x + self.ox * math.cos(rot) - self.oy * math.sin(rot), 
                    self.y + self.ox * math.sin(rot) + self.oy * math.cos(rot)
                )
                if (mouseTrail[1] - pos):length() < unit / 2 or opt.auto and dt > 0 then
                    local foreVec = vec2(math.cos(rot), math.sin(rot))
                    local normVel = mouseVel:normalize()
                    local dot = foreVec.x * normVel.x + foreVec.y * normVel.y
                    if dot > 0.8 or opt.auto then
                        assets.sounds.kick:seek(0)
                        assets.sounds.kick:play()
                        energy = math.min(energy + 1, 100)
                        local noteScore =
                            math.floor((dot - 0.8) * 5 * (1 - 1 / (mouseVel:length() + 1)) * 20 + 0.5) * 10
                        newScoresText(noteScore,
                            self.x + self.ox * math.cos(rot) - self.oy * math.sin(rot),
                            self.y + self.ox * math.sin(rot) + self.oy * math.cos(rot)
                        )
                        score = score + noteScore
                        streak = streak + 1
                        return true
                    end
                    energy = math.max(energy - 5, 0)
                    assets.sounds.badhit:seek(0)
                    assets.sounds.badhit:play()
                    streak = 0
                    return true
                end
            end
        end
    }
}
local function loadChart(dir)
    local chart = {}
    local path = "charts/" .. dir .. "/"
    for i, item in ipairs(love.filesystem.getDirectoryItems("charts/"..dir)) do
        print(item)
        if item:sub(1, 5) == "audio" then
            chart.audio = love.sound.newSoundData(path .. item)
        end
    end
    local file = love.filesystem.newFile(path .. "chart.dnchart", "r")
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
            chart.bt = 60/chart.bpm
        elseif #values > 1 then
            local object = objectMeta[values[2]].constructor(unpack(values))
            timeAcc = timeAcc + values[1]
            object.time = timeAcc
            object.delay = values[1]
            object.type = values[2]
            object.render = objectMeta[values[2]].render
            object.update = objectMeta[values[2]].update
            table.insert(chart.objects, object)

        end
    end

    return chart

end


local function play(chartName)
    energy = 50
    score = 0
    activeChart = recursiveClone(charts[chartName])
    CurrentSong = activeChart.audio
    songSource = love.audio.newQueueableSource(
        CurrentSong:getSampleRate(), 
        CurrentSong:getBitDepth(),
        CurrentSong:getChannelCount()
    )
    songSource:setPitch(opt.pitch)
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
end

for i, dir in ipairs(love.filesystem.getDirectoryItems("charts")) do
    print(dir)
    charts[dir] = loadChart(dir)
end

play("test")
logTable(activeChart.objects[1])
love.window.setMode(800, 600, {vsync = true, resizable = true, msaa = 8})

function love.load()
    assets.sprites = {
        note = love.graphics.newImage("assets/sprites/note.png"),
        indicator = love.graphics.newImage("assets/sprites/indicator.png")
    }
    assets.sounds = {
        kick = love.audio.newSource("assets/sounds/kick.wav", "static"),
        miss = love.audio.newSource("assets/sounds/miss.wav", "static"),
        badhit = love.audio.newSource("assets/sounds/badhit.wav", "static")
    }
    assets.shaders = {
        recolor = love.graphics.newShader(love.filesystem.read("assets/shaders/recolor.lvsl"))
    }
    love.audio.setVolume(0.2)
end

local lastHitNote
function love.update(dt)

    while songSource:getFreeBufferCount() > 0 do
        for i = 0, bufferSize-1 do
            for c = 1, CurrentSong:getChannelCount() do
                buffer:setSample(i, c, CurrentSong:getSample(i + samplesRead, c))
            end
        end
        samplesRead = samplesRead + bufferSize
        songSource:queue(buffer)
        songSource:play()
    end

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

    if energy == 0 or #activeChart.objects == 0 then
        play("test")
    end

    local nextTexts = {}
    for index, text in ipairs(scoreTexts) do
        text.age = text.age + dt
        if text.age < 1 then
            table.insert(nextTexts, text)
        end
    end
    scoreTexts = nextTexts

    table.insert(mouseTrail, 1, vec2(love.mouse.getPosition()))
    while #mouseTrail > 10 do
        mouseTrail[11] = nil
    end
    if #mouseTrail > 2 then
        mouseVel = ((mouseTrail[1]-mouseTrail[2]) / dt)
    end
end

function getUnit()
    unit = math.min(love.graphics.getDimensions()) / 11
    return unit
end

function toScreenCoords(x, y)
    return vec2(love.graphics.getDimensions()) / 2 + vec2(x - 5, y - 5) * getUnit()
end

local center = vec2(love.graphics.getDimensions()) / 2
print(center + vec2(5 - 5, 5 - 5) * getUnit())

local lastTime = 0
function love.draw()
    if #mouseTrail < 3 then return end
    local coords = {}
    for i, point in ipairs(mouseTrail) do
        coords[i*2-1] = point.x
        coords[i*2] = point.y
    end

    local time = samplesRead / activeChart.audio:getSampleRate()
    for i = math.min(#activeChart.objects, 150), 1, -1 do
        activeChart.objects[i]:render(time)
    end

    for index, text in ipairs(scoreTexts) do
        love.graphics.setColor(255, 255, 255, 1 - text.age)
        local pos = toScreenCoords(text.x, text.y)
        love.graphics.print(tostring(text.score), pos.x, pos.y)
    end

    love.graphics.setShader()

    print(hsv2rgb(time, 1, 1))
    love.graphics.setColor(hsv2rgb(time*60, 1, 1))

    love.graphics.setLineWidth(1)

    love.graphics.polygon("fill", coords)

    if opt.auto and lastHitNote and activeChart.objects[1] then
        local bezPoint = noteArc(lastHitNote, activeChart.objects[1],
            (time - lastHitNote.time * activeChart.bt) / activeChart.objects[1].delay / activeChart.bt)
        local bezScreen = toScreenCoords(bezPoint.x, bezPoint.y)
        love.graphics.ellipse("fill", bezScreen.x, bezScreen.y, 10, 10)
        --love.mouse.setPosition(bezScreen.x, bezScreen.y)
    end

    love.graphics.rectangle("line", 10, 10, 200, 10)
    love.graphics.rectangle("fill", 10, 10, energy * 2, 10)
    love.graphics.print(tostring(score), 10, 30)
    love.graphics.print(tostring(streak), 10, 45, 0, 2, 2)

    --[[
    love.graphics.setColor(0, 255, 0)
    local s = mouseTrail[1]
    local e = mouseVel / 10 + s
    love.graphics.line(s.x, s.y, e.x, e.y)]]
end