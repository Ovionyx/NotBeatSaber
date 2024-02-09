local vec2 = require("lib.vector2")

return {
	gameplay = {
		activeChart = {},
		energy = 50,
		score = 0,
		streak = 0,
		noteCount = 0,
	},
	mousePos = vec2(love.mouse.getPosition()),
	mouseVel = vec2(0, 0),
}