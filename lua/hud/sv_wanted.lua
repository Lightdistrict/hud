-- DarkRP's own wanted timer (modules/police/sv_init.lua) is a plain
-- server-side timer.Create, never networked to the client -- there's
-- nothing for the HUD to read a countdown from. This mirrors the real
-- duration (GAMEMODE.Config.wantedtime) to the owning client whenever
-- they become wanted, so the HUD can count it down locally.

util.AddNetworkString("maxhud_wanted")

local function sendWantedDuration(ply, duration)
	net.Start("maxhud_wanted")
		net.WriteUInt(duration and math.max(0, math.Round(duration)) or 0, 16)
	net.Send(ply)
end

-- Real DarkRP hook (modules/police/sv_init.lua) -- fires whenever a
-- player becomes wanted, whether via /wanted or a job/addon calling
-- ply:wanted() directly. A duration of 0 (GAMEMODE.Config.wantedtime <= 0)
-- means DarkRP itself never starts an expiry timer either -- indefinite
-- until manually /unwanted.
hook.Add("playerWanted", "maxhud_wanted_start", function(target)
	if not IsValid(target) then return end
	sendWantedDuration(target, GAMEMODE.Config.wantedtime)
end)

-- Catches a player already wanted when this addon (re)starts mid-round.
hook.Add("PlayerInitialSpawn", "maxhud_wanted_sync", function(ply)
	timer.Simple(1, function()
		if IsValid(ply) and ply:isWanted() then
			sendWantedDuration(ply, GAMEMODE.Config.wantedtime)
		end
	end)
end)
