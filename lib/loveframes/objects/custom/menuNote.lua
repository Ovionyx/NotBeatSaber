local vec2 = require("lib.vector2")

local assets = {}

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

local noteImageSize = vec2(assets.sprites.note:getDimensions())

return function(loveframes)

    local newobject = loveframes.NewObject("menunote", "menunote", true)

    function newobject:initialize()
        --self:SetSize(100, 100)
        --self:SetRetainSize(true)
        self.rotation = 0
        self.direction = vec2(1, 0)
        self.hit = false
        --self:CenterWithinArea(0, 0, love.graphics.getDimensions)
    end

    function newobject:SetRotation(rot, rad)
        local rot = rad and rot or math.rad(rot)
        self.rotation = rot
        self.direction = vec2(math.cos(rot), math.sin(rot))
    end

    function newobject:update()
        self:CheckHover()
        if self.hover and MouseVel:normalize():dot(self.direction) > 0.8 then
            if not self.hit then 
                _ = self.OnHit and self:OnHit()
                self.hit = true
            end
        else
            self.hit = false
        end
    end
    
    function newobject:draw()
        love.graphics.setColor(1, 1, 1)
        local width, height = self:GetSize()
        local parent = self:GetParent()
        local x, y = self.x, self.y
        love.graphics.rectangle("line", x, y, width, height)
        love.graphics.setShader(assets.shaders.recolor)
        love.graphics.draw(assets.sprites.note, x + width / 2, y + height / 2, self.rotation, width / noteImageSize.x,
            height / noteImageSize.y, noteImageSize.x / 2, noteImageSize.y / 2)
        love.graphics.setShader()
    end

    function newobject:on_mouse_enter()
        print("mouse entered")
    end

end