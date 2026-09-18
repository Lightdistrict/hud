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
local function setLawsCommand(ply, args)
	if not ply:isMayor() then
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
DarkRP.defineChatCommand("laws", setLawsCommand)
DarkRP.defineChatCommand("addlaw", setLawsCommand)

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
