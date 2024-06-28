local vars = require("vars")

local assets = {}

local dirs = {
	sprites = function (path)
		return love.graphics.newImage(path)
	end,
	sounds = function (path)
		return love.audio.newSource(path, "static")
	end,
	shaders = function (path)
		return love.graphics.newShader(love.filesystem.read(path))
	end
}

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

for dir, loader in pairs(dirs) do
	assets[dir] = {}
	for i, path in ipairs(love.filesystem.getDirectoryItems("assets/"..dir)) do
		local status, result = pcall(loader, "assets/"..dir.."/"..path)
		if status then
			local name = path:match("[^.]*")
			print("assets/" .. dir .. "/" .. path .. " loaded as " .. name)
			assets[dir][name] = result
		end
	end
end

return assets