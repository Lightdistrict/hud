-- The Laws board: a short message the Mayor sets via /laws <text>,
-- broadcast to every connected player, and always showing something
-- (starts on Config.defaultLaws, resets back to it if the current Mayor
-- dies). Independent of DarkRP's own generic Agenda system (which is
-- one-agenda-per-listening-team, not "everyone" -- reusing it here would
-- silently break Police/Gang's own agendas since they already listen on
-- their own teams).

local Config = MaxHUD.Config

util.AddNetworkString("maxhud_laws")

MaxHUD.LawsText = Config.defaultLaws

local function broadcastLaws()
	net.Start("maxhud_laws")
		net.WriteString(MaxHUD.LawsText)
	net.Broadcast()
end

local function sendLawsTo(target)
	net.Start("maxhud_laws")
		net.WriteString(MaxHUD.LawsText)
	net.Send(target)
end

-- ply:isMayor() is real DarkRP (modules/police/sh_init.lua), true for
-- whichever job has `mayor = true` set (the stock Mayor job by default).
-- Wrapped in pcall so a job-table edge case can't silently eat the whole
-- command with zero feedback -- if this errors, the player (and console)
-- now hear about it instead of the command just doing nothing.
local function setLawsCommand(ply, args)
	local ok, mayor = pcall(function() return ply:isMayor() end)
	if not ok then
		print("[MaxHUD] /laws: ply:isMayor() errored: " .. tostring(mayor))
		DarkRP.notify(ply, 1, 4, "Something went wrong checking your job -- see server console.")
		return ""
	end

	if not mayor then
		DarkRP.notify(ply, 1, 4, "Only the Mayor can set the laws.")
		return ""
	end

	MaxHUD.LawsText = (args ~= "" and args) or Config.defaultLaws
	broadcastLaws()

	DarkRP.notify(ply, 0, 4, "The laws have been updated.")
	return ""
end

-- Both names do the exact same thing -- registered as two separate
-- commands (not one aliased to the other) since a chat message that
-- didn't match either previously just silently did nothing, which is
-- what looked like "doesn't update live".
--
-- Deferred to the next tick, not run inline at file-load time: addon load
-- order isn't guaranteed relative to the rest of DarkRP finishing its own
-- setup (the same class of issue that made SAM command registration in
-- the levelsystem addon need the same fix). By the start of the next tick
-- every addon's initial files have finished loading either way.
timer.Simple(0, function()
	DarkRP.defineChatCommand("laws", setLawsCommand)
	DarkRP.defineChatCommand("addlaw", setLawsCommand)
	print("[MaxHUD] Registered /laws and /addlaw commands.")
end)

-- Reset to the default laws the moment the current Mayor dies.
hook.Add("PlayerDeath", "maxhud_laws_reset_on_mayor_death", function(victim)
	if not IsValid(victim) or not victim.isMayor or not victim:isMayor() then return end

	MaxHUD.LawsText = Config.defaultLaws
	broadcastLaws()
end)

hook.Add("PlayerInitialSpawn", "maxhud_laws_sync", function(ply)
	timer.Simple(1, function()
		if IsValid(ply) then
			sendLawsTo(ply)
		end
	end)
end)
