local vec2 = require("lib.vector2")
local vars = require("vars")

local function serializeTable(t, indent)
    indent = indent or 1
    if type(t) == "table" and indent <= 1 then
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

local function logTable(t)
    print(serializeTable(t))
end

function math.lerp(a, b, t)
    return t * (b - a) + a
end

local function bezier(p0, p1, p2, p3, t)
    return
        p0 * (-t ^ 3 + 3 * t ^ 2 - 3 * t + 1) +
        p1 * (3 * t ^ 3 - 6 * t ^ 2 + 3 * t) +
        p2 * (-3 * t ^ 3 + 3 * t ^ 2) +
        p3 * (t ^ 3)
end

local function hsv2rgb(h, s, v, a)
    s = 1 - s
    local i = h / 60 % 6
    local r, g, b

    if i < 1 then --red to yellow
        r = v
        g = math.lerp((i % 1), 1, s) * v
        b = s * v
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

local function getUnit()
    unit = math.min(love.graphics.getDimensions()) / 11
    return unit
end

local function toScreenCoords(x, y)
    return vec2(love.graphics.getDimensions()) / 2 + vec2(x - 5, y - 5) * getUnit()
end

local function loadState(state)
    if type(state) == "string" then
        state = require("states."..state)
    end
    vars.state = state
    return state
end

return {
    bezier = bezier,
    hsv2rgb = hsv2rgb,
    getUnit = getUnit,
    toScreenCoords = toScreenCoords,
    printTable = logTable,
    serializeTable = serializeTable,
    loadState = loadState,
}