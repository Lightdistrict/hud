-- The Laws board: a short message the Mayor sets via /laws <text>,
-- broadcast to every connected player. Independent of DarkRP's own generic
-- Agenda system (which is one-agenda-per-listening-team, not "everyone" --
-- reusing it here would silently break Police/Gang's own agendas since
-- they already listen on their own teams).

util.AddNetworkString("maxhud_laws")

MaxHUD.LawsText = MaxHUD.LawsText or ""

local function sendLawsTo(target)
	net.Start("maxhud_laws")
		net.WriteString(MaxHUD.LawsText)
	net.Send(target)
end

-- ply:isMayor() is real DarkRP (modules/police/sh_init.lua), true for
-- whichever job has `mayor = true` set (the stock Mayor job by default).
DarkRP.defineChatCommand("laws", function(ply, args)
	if not ply:isMayor() then
		DarkRP.notify(ply, 1, 4, "Only the Mayor can set the laws.")
		return ""
	end

	MaxHUD.LawsText = args or ""

	for _, v in ipairs(player.GetAll()) do
		sendLawsTo(v)
	end

	DarkRP.notify(ply, 0, 4, "The laws have been updated.")
	return ""
end)

hook.Add("PlayerInitialSpawn", "maxhud_laws_sync", function(ply)
	timer.Simple(1, function()
		if IsValid(ply) then
			sendLawsTo(ply)
		end
	end)
end)
