#!/bin/env luajit

local xdg_runtime_dir = os.getenv("XDG_RUNTIME_DIR")
local stats_file = io.open(xdg_runtime_dir .. "/soundboard/state", "r")

local pgrep = io.popen("pgrep waybar", "r")
if pgrep then
	local f = io.open(xdg_runtime_dir .. "/soundboard/waybar", "w")
	if f then
  	f:write(pgrep:read("l"))
  	f:close()
  end
  pgrep:close()
end

if (not stats_file) then
	print("soundboard not running\n")
	os.exit(0)
end

local page = stats_file:read("l")
local rate = stats_file:read("l")
local bend = stats_file:read("l")
local is_reversed = stats_file:read("l")
local is_reverbed = stats_file:read("l")

local reversed = ""
if is_reversed == "true" then
	reversed = "◀"
else
	reversed = "▶"
end

local reverbed = ""
if is_reverbed == "true" then
	reverbed = "〰️"
else
	reverbed = "—─"
end

print(page .. " 󱗖 " .. rate .. " 󰞌 " .. bend .. " ∿ " .. reversed .. " " .. reverbed .. "\n")
