
return function (loveframes)

    local skin = {}

    skin.name = "Main"
    skin.author = "BlueMoonJune"
    skin.version = "0.0.0"
    --skin.base = "Default"

    function skin.frame(object)
        love.graphics.setColor(1, 1, 1)
        love.graphics.rectangle("line", object:GetX(), object:GetY(), object:GetWidth(), object:GetHeight())
    end

    function skin.button(object)
        love.graphics.setColor(1, 1, 1)
        love.graphics.rectangle("line", object:GetX(), object:GetY(), object:GetWidth(), object:GetHeight())
    end

    loveframes.RegisterSkin(skin)

end
