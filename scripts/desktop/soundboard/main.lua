#!/bin/env lua

local posix = require("posix")
local mod = {}

-- TODO: this function should also link effect-capture.out to my headphones
function mod.main()
	if #arg < 1 then
  	print("Usage:\t" .. arg[0] .. " /path/to/sounds")
  	os.exit(0)
  end

  mod.path = arg[1] .. "/"

	mod.page = 0.0
	mod.rate = 1.0
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

function mod.reverse_handler()
	mod.reversed = not mod.reversed -- toggle reversed to opposite
	mod.update_state()
end

-- The three functions above should call this
function mod.update_state()
	local state = string.format("%d", mod.page) .. "\n"
	state = state .. mod.rate .. "\n"
	state = state .. tostring(mod.reversed) .. "\n"

	local rundir = os.getenv("XDG_RUNTIME_DIR") .. "/soundboard/"
	local statefile = io.open(rundir .. "state", "w")
	if statefile then
  	statefile:write(state)
  	statefile:close()
  end

	local waybar_pid = io.open(rundir .. "waybar", "r")
	if not waybar_pid then
  	return
  end
  os.execute("kill -s 35 " .. waybar_pid:read("l"))
  waybar_pid:close()
end

function mod.sound_handler(signum)
	local pid = posix.unistd.fork()

	if pid ~= 0 then
  	return
  end

	local sound = (mod.page * 10) + (signum - 40)
	sound = string.format("%d", sound)

	local player = "| pw-play --target effect-capture.in -"
	local effects = "asetrate=48000*" .. mod.rate .. ",aresample=48000"
	if mod.reversed then
		effects = "areverse," .. effects
	end
	local ffmpeg = "ffmpeg -i " .. mod.path .. sound .. ".* -af '" .. effects .. "' -c pcm_s16le -f wav - 2> /dev/null "

	os.execute(ffmpeg .. player)
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
