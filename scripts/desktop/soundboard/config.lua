return {
  -- Your microphone source
  mic = "filtered-mic.out",
  -- The sink sound effects will be played to
  target = "effect-capture.in",
  -- The sink of the loopback node that will serve as your soundboard microphone
  source = "soundboard.in",
  -- The source of the sound effects target node
  loopback = "effect-capture.out",
  -- Your audio playback device, be it headphones or speakers if you dare
  playback = "eq.in"
}
