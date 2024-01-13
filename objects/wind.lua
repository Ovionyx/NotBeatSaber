local vec2 = require("lib.vector2")
local vars = require("vars")
local util = require("util")
local opt = require("options")
local assets = require("assets")

local windx = 0
local windy = 0

local targx = 0
local targy = 0

local particles = {}

local lastParticleTime = 0

return {
    constructor = function(_, _, x, y)
        x = tonumber(x)
        y = tonumber(y)
        return {
            x = x,
            y = y,
        }
    end,

    update = function(self, time, first)
        if time > 0 then
            targx = self.x
            targy = self.y
            return true
        end
    end,

    render = function ()
        
    end,

    staticUpdate = function (dt, time)
        local w, h = love.graphics.getDimensions()
        windx = math.lerp(windx, targx, 0.02)
        windy = math.lerp(windy, targy, 0.02)
        local mp = vars.mousePos
        vars.mousePos = vec2(mp.x + windx * dt, mp.y + windy * dt)

        print(vars.mousePos)

        local i = 1
        while i <= #particles do
            local p = particles[i]
            if p.pos.x < 0 or p.pos.x > w or p.pos.y < 0 or p.pos.y > h then
                table.remove(particles, i)
            else
                p.pos = p.pos + p.vel * dt * 5
                p.vel = math.lerp(p.vel, vec2(windx, windy), 0.02)
                i = i + 1
            end
        end

        if time < lastParticleTime - 0.1 then
            lastParticleTime = time
        end

        while time - lastParticleTime > 0.01 do
            table.insert(particles, {
                pos = vec2(math.random(1, w),
                    math.random(1, h)),
                vel = vec2(0, 0)
            })
            lastParticleTime = lastParticleTime + 0.01
        end
    end,

    staticRender = function (time)
        love.graphics.setColor(1, 1, 1)
        for _, p in ipairs(particles) do
            love.graphics.line(p.pos.x, p.pos.y, p.pos.x + p.vel.x, p.pos.y + p.vel.y)
        end
        love.graphics.print(windy)
    end
}
