local objectMeta = {}

for key, value in ipairs(love.filesystem.getDirectoryItems("objects")) do
	if value:sub(-4) == ".lua" then
		objectMeta[value:sub(1, -5)] = require("objects." .. value:sub(1, -5))
	end 
end

return objectMeta