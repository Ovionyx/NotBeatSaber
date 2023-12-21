local vec2 = require("lib.vector2")
local vars = require("vars")
local util = require("util")
local opt = require("options")
local assets = require("assets")

return {
    constructor = function(_, _, x, y, rot, ox, oy)
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

        local dt = (time - self.time * vars.gameplay.activeChart.bt) / opt.indDur
        if dt < -1 then return end

        local unit = util.getUnit()

        love.graphics.setShader(assets.shaders.recolor)
        love.graphics.setColor(
            util.hsv2rgb(self.time * 30, 1, 1, (1 + dt)))

        local rot = self.rot

        local imageScale = vec2(assets.sprites.note:getPixelDimensions())
        local center = imageScale / 2

        local dtExp = (1 - (1 + dt) ^ opt.indExp) * opt.indDist
        local invDtExp = (1 - (dt) ^ opt.indExp)

        local pos = vec2(self.x - 5, self.y - 5) * unit

        local objPos = vec2(love.graphics.getDimensions()) / 2 +
            pos * (invDtExp * opt.indDur) +
            vec2((self.ox * math.cos(rot) - self.oy * math.sin(rot)) * unit,
                (self.ox * math.sin(rot) + self.oy * math.cos(rot)) * unit)

        love.graphics.draw(assets.sprites.note, objPos.x, objPos.y, rot,
            unit / imageScale.x, unit / imageScale.y, center.x, center.y)

        local objPos = vec2(love.graphics.getDimensions()) / 2 +
            pos +
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

    update = function(self, time, first)
        local dt = (time - self.time * vars.gameplay.activeChart.bt)
        if dt > 0.2 and vars.gameplay.energy > 0 then
            if self.badhit then
                vars.gameplay.energy = math.max(vars.gameplay.energy - 5, 0)
                assets.sounds.badhit:seek(0)
                assets.sounds.badhit:play()
            else
                vars.gameplay.energy = math.max(vars.gameplay.energy - 10, 0)
                assets.sounds.miss:seek(0)
                assets.sounds.miss:play()
            end
            vars.gameplay.streak = 0
            vars.gameplay.noteCount = vars.gameplay.noteCount + 1
            return true
        end

        if vars.mousePos and dt > (first and -0.2 or 0) and vars.gameplay.energy > 0 then

            local unit = util.getUnit()

            local rot = self.rot
            local pos = util.toScreenCoords(
                self.x + self.ox * math.cos(rot) - self.oy * math.sin(rot),
                self.y + self.ox * math.sin(rot) + self.oy * math.cos(rot)
            )
            local dif = vars.mouseVel - pos
            if (dif):lengthSquared() + dif:dot(self.dir) ^ 2 < unit ^ 2 or opt.auto and dt > 0 then
                local foreVec = vec2(math.cos(rot), math.sin(rot))
                local normVel = vars.mouseVel:normalize()
                local dot = foreVec.x * normVel.x + foreVec.y * normVel.y
                if dot > 0.8 or opt.auto then
                    assets.sounds.kick:seek(0)
                    assets.sounds.kick:play()
                    vars.gameplay.energy = math.min(vars.gameplay.energy + 1, 100)
                    local noteScore =
                        math.floor((dot - 0.8) * 5 * (1 - 1 / (vars.mouseVel:length() + 1)) * 20 + 0.5) * 10
                    vars.gameplay.score = vars.gameplay.score + noteScore
                    vars.gameplay.streak = vars.gameplay.streak + 1
                    vars.gameplay.noteCount = vars.gameplay.noteCount + 1
                    return true
                end
                self.badhit = true
            end
        end
    end
}
