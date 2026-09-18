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

-- Test command: type "maxhud_testarrest [seconds]" in your own in-game
-- console. Goes through the real ply:arrest() (same as a police arrest),
-- so it exercises the exact same path as the real thing. Admin-gated since
-- it does a real arrest (Arrested var + teleport to jail if configured).
concommand.Add("maxhud_testarrest", function(ply, cmd, args)
	if not IsValid(ply) or not ply:IsAdmin() then return end
	local duration = tonumber(args[1]) or 30
	ply:arrest(duration, ply)
end)
