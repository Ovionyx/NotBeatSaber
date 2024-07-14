return {
	indDist = 2, --Distance to display indicator arrows
	indExp = 4, --Exponent controlling the movement of the indicator arrow
	indDur = 0.5, --How long to show indicators for
	startBeat = -0x10, --How many beats into the song to start
	pitch = 0.5, --Speed and pitch of the song
	auto = false, --Auto play
	vsync = true,
	fullscreen = false,
	bufferSize = 256, --Number of samples to read into the audio queue at a time. Increase this to fix audio stuttering, decrease to fix video stuttering
	chartName = "heracles" --Name of the chart to load
}
