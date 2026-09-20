-- DarkRP's own arrested countdown is drawn client-side already
-- ("DarkRP_ArrestedHUD", modules/hud/cl_hud.lua) -- hidden via
-- HUDShouldDraw (see cl_hud.lua) in favor of our own top-strip version.
-- Unlike the wanted timer, DarkRP already passes the exact jail duration
-- straight into a real hook ("playerArrested", modules/police/sv_init.lua),
-- so this works correctly even with a custom /arrest <time> length, not
-- just the config default.

util.AddNetworkString("maxhud_arrested")

local function sendArrestedDuration(ply, duration)
	net.Start("maxhud_arrested")
		net.WriteUInt(duration and math.max(0, math.Round(duration)) or 0, 16)
	net.Send(ply)
end

hook.Add("playerArrested", "maxhud_arrested_start", function(target, time)
	if not IsValid(target) then return end
	sendArrestedDuration(target, time)
end)

-- Catches a player already arrested when this addon (re)starts mid-round.
hook.Add("PlayerInitialSpawn", "maxhud_arrested_sync", function(ply)
	timer.Simple(1, function()
		if IsValid(ply) and ply:isArrested() then
			sendArrestedDuration(ply, GAMEMODE.Config.jailtimer)
		end
	end)
end)

--[[
- Finds a player by a case-insensitive substring of their nickname --
- used by the test concommands below so you can target a spawned bot
- (or anyone else) by a partial name instead of needing an exact match.
-
- @return Player|nil
]]
local function findPlyByName(query)
	if not query or query == "" then return nil end
	query = string.lower(query)
	for _, p in ipairs(player.GetAll()) do
		if string.find(string.lower(p:Nick()), query, 1, true) then
			return p
		end
	end
	return nil
end

--[[
- Parses the shared "[target name] [seconds]" argument convention used by
- both test commands below: args[1] may be a target name OR the duration
- (if it parses as a number and no player matches it), args[2] is the
- duration when args[1] was a name.
-
- @return Player, number
]]
local function parseTargetAndDuration(ply, args, defaultDuration)
	local target = findPlyByName(args[1])
	local duration
	if target then
		duration = tonumber(args[2])
	else
		target = ply
		duration = tonumber(args[1])
	end
	return target, duration or defaultDuration
end

-- Test command: type "maxhud_testarrest [target name] [seconds]" in your
-- own in-game console. With no target name, arrests yourself; with one,
-- finds the first player whose nickname contains it (handy for testing
-- the overhead ARRESTED tag on a bot -- "bot" in console spawns one).
-- Goes through the real ply:arrest() (same as a police arrest), so it
-- exercises the exact same path as the real thing. Admin-gated since it
-- does a real arrest (Arrested var + teleport to jail if configured).
concommand.Add("maxhud_testarrest", function(ply, cmd, args)
	if not IsValid(ply) or not ply:IsAdmin() then return end
	local target, duration = parseTargetAndDuration(ply, args, 30)
	target:arrest(duration, ply)
end)

-- Test command: type "maxhud_testwanted [target name] [seconds]". Same
-- target-by-partial-name convention as maxhud_testarrest above. Goes
-- through the real ply:wanted() (gamemode/modules/police/sv_init.lua).
concommand.Add("maxhud_testwanted", function(ply, cmd, args)
	if not IsValid(ply) or not ply:IsAdmin() then return end
	local target, duration = parseTargetAndDuration(ply, args, 60)
	target:wanted(ply, "testing", duration)
end)
