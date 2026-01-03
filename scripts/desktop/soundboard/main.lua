#!/bin/env lua

local posix = require("posix")
local config = require("config")
local mod = {}

function mod.main()
	if #arg < 1 then
  	print("Usage:\t" .. arg[0] .. " /path/to/sounds")
  	os.exit(0)
  end

  mod.path = arg[1] .. "/"

	mod.page = 0.0
	mod.rate = 1.0
	mod.bend = 0.0
	mod.echo = false
	mod.tempo = false
	mod.reverb = false
	mod.reversed = false

  mod.rundir = os.getenv("XDG_RUNTIME_DIR") .. "/soundboard/"

	local check = "ls " .. mod.path .. " > /dev/null 2>&1 && echo 'true' || echo 'false'"
	local path_status = io.popen(check, "r"):read("l")
	print("Path status: " .. path_status)
	if path_status == "false" then
  	error("path doesn't exist or is invalid")
  end

	-- Control signals
	posix.signal(34, mod.page_handler)		-- last page
	posix.signal(35, mod.page_handler)		-- next page
	posix.signal(36, mod.reverse_handler)	-- reverse audio
	posix.signal(37, mod.rate_handler)		-- slow audio
	posix.signal(38, mod.rate_handler)		-- speed up audio
	posix.signal(39, mod.reverb_handler)	-- reverb audio
	posix.signal(54, mod.echo_handler)		-- insert echoes
	posix.signal(50, mod.rate_switch)			-- tempo toggle
	posix.signal(51, mod.bend_handler)		-- bend audio down
	posix.signal(52, mod.bend_handler)		-- bend audio up
	posix.signal(53, mod.bend_handler)		-- reset audio bend

	-- Handle child process issue
	posix.signal(posix.signal.SIGCHLD, mod.reap)

	-- Sound effect signals
	posix.signal(41, mod.sound_handler)		-- 1
	posix.signal(42, mod.sound_handler)		-- 2
	posix.signal(43, mod.sound_handler)		-- 3
	posix.signal(44, mod.sound_handler)		-- 4
	posix.signal(45, mod.sound_handler)		-- 5
	posix.signal(46, mod.sound_handler)		-- 6
	posix.signal(47, mod.sound_handler)		-- 7
	posix.signal(48, mod.sound_handler)		-- 8
	posix.signal(49, mod.sound_handler)		-- 9

	-- Program is now setup, we're ready to export our state for IPC
	local rundir = os.getenv("XDG_RUNTIME_DIR") .. "/soundboard/"
	os.execute("mkdir " .. rundir)

	local pidfile = io.open(rundir .. "pid", "w")
	if pidfile then
		pidfile:write(posix.unistd.getpid())
		pidfile:close()
		else
			error("What the Fuck")
  end

  local statefile = io.open(rundir .. "state", "w")
  if statefile then
  	statefile:write(mod.page .. "\n")
  	statefile:close()
  	else
  		error("What the FUCK")
  end

  -- Link effect loopback to your audio device to hear the sound effects
  os.execute("pw-link " .. config.loopback .. " " .. config.playback)

  while true do
  	posix.sleep(1000)
  end
end

function mod.page_handler(signum)
	local page_delta = 2 * (signum - 34.5)
	mod.page = mod.page + page_delta

	mod.update_state()
end

function mod.rate_handler(signum)
	local rate_delta = 2 * (signum - 37.5)
	mod.rate = mod.rate * 1.25^rate_delta
	mod.update_state()
end

function mod.rate_switch()
	mod.tempo = not mod.tempo
end

function mod.reverse_handler()
	mod.reversed = not mod.reversed -- toggle reversed to opposite
	mod.update_state()
end

function mod.reverb_handler()
	mod.reverb = not mod.reverb
	mod.update_state()
end

function mod.echo_handler()
	mod.echo = not mod.echo
	mod.update_state()
end

function mod.bend_handler(signum)
	if signum == 53 then
		mod.bend = 0
	elseif signum > 51 then
		mod.bend = mod.bend + 200
	else
		mod.bend = mod.bend - 200
	end
	mod.update_state()
end

-- The three functions above should call this
function mod.update_state()
	local state = string.format("%d", mod.page) .. "\n"
	state = state .. mod.rate .. "\n"
	state = state .. mod.bend .. "\n"
	state = state .. tostring(mod.reversed) .. "\n"
	state = state .. tostring(mod.reverb) .. "\n"

	local rundir = os.getenv("XDG_RUNTIME_DIR") .. "/soundboard/"
	local statefile = io.open(rundir .. "state", "w")
	if statefile then
  	statefile:write(state)
  	statefile:close()
  end

  os.execute("polybar-msg action soundboard hook 0")
end

function mod.sound_handler(signum)
	local pid = posix.unistd.fork()

	if pid ~= 0 then
  	return
  end

	local sound = (mod.page * 10) + (signum - 40)
	sound = mod.path .. string.format("%d", sound)
	sound = sound .. ".*"

	local base = "sox " .. sound .. " -t wav -"
	local player = "pw-play - --target " .. config.target

	local effects = ""
	if mod.reversed then
  	effects = "reverse "
  end

	if mod.rate ~= 1.0 then
		if mod.tempo then
			effects = effects .. "tempo " .. mod.rate .. " 40 "
		else
			effects = effects .. "speed " .. mod.rate .. " "
		end
  end

	-- in the case that audio is bent, we're just going to pitch it down massively
	-- across the duration of the audio, so we need to get that duration, then
	-- find the real duration by the current set rate, then finally formulate
	-- the bend filter
	if mod.bend ~= 0 then
		local soxi = io.popen("soxi -D " .. sound, "r")
		if soxi then
			local file_duration = soxi:read("l")
			local duration = tonumber(file_duration) / mod.rate

			effects = effects .. "bend 0," .. mod.bend .. "," .. duration .. " "
			print(effects)
		end
	end

	if mod.reverb then
		-- Only echo when reverb is also enabled
		if mod.echo then
			effects = effects .. "echos 1.0 0.75 900 0.3 900 0.2 900 0.1 900 0.03 "
		end
		effects = effects .. "pad 0 4 reverb 80 50 100 "
  end

	local sox = base .. effects

	os.execute(sox .. " | " .. player)
	os.exit(0)
end

function mod.reap()
	while true do
    local pid, _ = posix.sys.wait.wait(-1, posix.sys.wait.WNOHANG)
    if pid == nil or pid <= 0 then
    	break
    end
  end
end

mod.main()

-- TODO for this: 
-- * make pw-play take in piped input from ffmpeg
-- * make a more versatile builder for the command
-- * segment signal handler at 38
-- posix.signal(37, lib.handler) -- multiply rate by 1.25^-1
-- posix.signal(39, lib.handler) -- multiply rate by 1.25^1
