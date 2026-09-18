-- DarkRP's warrant status (ply.warranted, modules/police/sv_init.lua) is
-- a plain server-side field, unlike "wanted"/"Arrested" (real DarkRP vars,
-- already broadcast to every client by setDarkRPVar's default target of
-- player.GetAll()) -- there's nothing for the client to read directly.
-- This tracks and broadcasts just the live count of currently-warranted
-- players whenever it changes.

util.AddNetworkString("maxhud_warrant_count")

local function countWarranted()
	local n = 0
	for _, ply in ipairs(player.GetAll()) do
		if ply.warranted then n = n + 1 end
	end
	return n
end

local function broadcastWarrantCount()
	net.Start("maxhud_warrant_count")
		net.WriteUInt(math.min(countWarranted(), 255), 8)
	net.Broadcast()
end

-- Real DarkRP hooks (modules/police/sv_init.lua).
hook.Add("playerWarranted", "maxhud_warrant_count_up", broadcastWarrantCount)
hook.Add("playerUnWarranted", "maxhud_warrant_count_down", broadcastWarrantCount)

-- Warrants aren't cleared via a hook on disconnect -- the player just
-- leaves player.GetAll(), so recompute next tick (after they're fully
-- removed) whenever anyone disconnects.
hook.Add("PlayerDisconnected", "maxhud_warrant_count_leave", function()
	timer.Simple(0, broadcastWarrantCount)
end)

hook.Add("PlayerInitialSpawn", "maxhud_warrant_count_sync", function(ply)
	timer.Simple(1, function()
		if IsValid(ply) then
			net.Start("maxhud_warrant_count")
				net.WriteUInt(math.min(countWarranted(), 255), 8)
			net.Send(ply)
		end
	end)
end)
