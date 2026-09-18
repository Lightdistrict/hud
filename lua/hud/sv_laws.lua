-- The Laws board: three permanent laws (Config.defaultLawsList), never
-- editable, plus any number of additional laws the Mayor appends on top
-- with /addlaw <text> -- numbered continuing on from the permanent three.
-- /removelaw takes back the most recently added one (never touches the
-- permanent three). /laws (no args) clears all additional laws, back to
-- just the permanent three -- the same reset that happens automatically
-- when the current Mayor dies. Broadcast live to every connected player.
-- Independent of DarkRP's own generic Agenda system (which is
-- one-agenda-per-listening-team, not "everyone" -- reusing it here would
-- silently break Police/Gang's own agendas since they already listen on
-- their own teams).

local Config = MaxHUD.Config

util.AddNetworkString("maxhud_laws")

MaxHUD.AdditionalLaws = MaxHUD.AdditionalLaws or {}

--[[
- @return string -- the permanent three, then any additional laws, all
-   numbered in one continuous list
]]
local function buildLawsText()
	local lines = {}
	local n = 0

	for _, law in ipairs(Config.defaultLawsList) do
		n = n + 1
		table.insert(lines, n .. ". " .. law)
	end

	for _, law in ipairs(MaxHUD.AdditionalLaws) do
		n = n + 1
		table.insert(lines, n .. ". " .. law)
	end

	return table.concat(lines, "\n")
end

MaxHUD.LawsText = buildLawsText()

local function broadcastLaws()
	MaxHUD.LawsText = buildLawsText()
	net.Start("maxhud_laws")
		net.WriteString(MaxHUD.LawsText)
	net.Broadcast()
end

local function sendLawsTo(target)
	net.Start("maxhud_laws")
		net.WriteString(MaxHUD.LawsText)
	net.Send(target)
end

local function resetLaws()
	MaxHUD.AdditionalLaws = {}
	broadcastLaws()
end

--[[
- ply:isMayor() is real DarkRP (modules/police/sh_init.lua), true for
- whichever job has `mayor = true` set (the stock Mayor job by default).
- Wrapped in pcall so a job-table edge case can't silently eat a command
- with zero feedback.
-
- @return bool ok, string|nil errorMessage
]]
local function checkIsMayor(ply)
	local ok, mayor = pcall(function() return ply:isMayor() end)
	if not ok then
		print("[MaxHUD] ply:isMayor() errored: " .. tostring(mayor))
		return false, "Something went wrong checking your job -- see server console."
	end

	if not mayor then
		return false, "Only the Mayor can do that."
	end

	return true
end

local function addLawCommand(ply, args)
	local ok, err = checkIsMayor(ply)
	if not ok then
		DarkRP.notify(ply, 1, 4, err)
		return ""
	end

	if not args or args == "" then
		DarkRP.notify(ply, 1, 4, "Usage: /addlaw <text>")
		return ""
	end

	if #Config.defaultLawsList + #MaxHUD.AdditionalLaws >= Config.maxLaws then
		DarkRP.notify(ply, 1, 4, "The laws are full (max " .. Config.maxLaws .. ") -- remove one first with /removelaw.")
		return ""
	end

	if #args > Config.maxLawLength then
		DarkRP.notify(ply, 1, 4, "That law is too long (max " .. Config.maxLawLength .. " characters).")
		return ""
	end

	table.insert(MaxHUD.AdditionalLaws, args)
	broadcastLaws()

	DarkRP.notify(ply, 0, 4, "Added law #" .. (#Config.defaultLawsList + #MaxHUD.AdditionalLaws) .. ".")
	return ""
end

local function removeLawCommand(ply)
	local ok, err = checkIsMayor(ply)
	if not ok then
		DarkRP.notify(ply, 1, 4, err)
		return ""
	end

	if #MaxHUD.AdditionalLaws == 0 then
		DarkRP.notify(ply, 1, 4, "There are no additional laws to remove.")
		return ""
	end

	table.remove(MaxHUD.AdditionalLaws)
	broadcastLaws()

	DarkRP.notify(ply, 0, 4, "Removed the most recently added law.")
	return ""
end

local function lawsResetCommand(ply)
	local ok, err = checkIsMayor(ply)
	if not ok then
		DarkRP.notify(ply, 1, 4, err)
		return ""
	end

	resetLaws()

	DarkRP.notify(ply, 0, 4, "The laws have been reset to the default three.")
	return ""
end

-- Deferred to the next tick, not run inline at file-load time: addon load
-- order isn't guaranteed relative to the rest of DarkRP finishing its own
-- setup (the same class of issue that made SAM command registration in
-- the levelsystem addon need the same fix). By the start of the next tick
-- every addon's initial files have finished loading either way.
timer.Simple(0, function()
	DarkRP.defineChatCommand("laws", lawsResetCommand)
	DarkRP.defineChatCommand("addlaw", addLawCommand)
	DarkRP.defineChatCommand("removelaw", removeLawCommand)
	print("[MaxHUD] Registered /laws, /addlaw, /removelaw commands.")
end)

-- Reset to the permanent three laws the moment the current Mayor dies.
hook.Add("PlayerDeath", "maxhud_laws_reset_on_mayor_death", function(victim)
	if not IsValid(victim) or not victim.isMayor or not victim:isMayor() then return end
	resetLaws()
end)

hook.Add("PlayerInitialSpawn", "maxhud_laws_sync", function(ply)
	timer.Simple(1, function()
		if IsValid(ply) then
			sendLawsTo(ply)
		end
	end)
end)
