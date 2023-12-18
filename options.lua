return {
    indDist = 2, --Distance to display indicator arrows
    indExp = 4, --Exponent controlling the movement of the indicator arrow
    indDur = 1, --How long to show indicators for
    startBeat = 32, --How many beats into the song to start
    pitch = 1, --Speed and pitch of the song
    auto = true, --Auto play
    vsync = true,
    fullscreen = false,
    bufferSize = 128, --Number of samples to read into the audio queue at a time. Increase this to fix audio stuttering, decrease to fix video stuttering
    chartName = "test" --Name of the chart to load
}
