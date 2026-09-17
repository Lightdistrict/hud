-- Minimal server-side hunger tracking -- in-memory only (resets each life,
-- like health/armor do), networked to the owning client for the HUD to draw.

local Config = MaxHUD.Config

util.AddNetworkString("maxhud_hunger")

MaxHUD.Hunger = MaxHUD.Hunger or {} -- [player] = current hunger value

local function syncHunger(ply)
	net.Start("maxhud_hunger")
		net.WriteUInt(math.Round(MaxHUD.Hunger[ply] or Config.hunger.max), 8)
	net.Send(ply)
end

hook.Add("PlayerSpawn", "maxhud_hunger_reset", function(ply)
	MaxHUD.Hunger[ply] = Config.hunger.max
	syncHunger(ply)
end)

hook.Add("PlayerDisconnected", "maxhud_hunger_cleanup", function(ply)
	MaxHUD.Hunger[ply] = nil
end)

timer.Create("maxhud_hunger_tick", Config.hunger.tickInterval, 0, function()
	for _, ply in ipairs(player.GetAll()) do
		if IsValid(ply) and MaxHUD.Hunger[ply] then
			MaxHUD.Hunger[ply] = math.max(0, MaxHUD.Hunger[ply] - Config.hunger.decayPerTick)
			syncHunger(ply)
		end
	end
end)

--[[
- Adjusts a player's hunger (positive to feed, negative to drain). Exposed
- so a food item/entity elsewhere can hook into the same hunger stat.
-
- @param player ply
- @param number amount
]]
function MaxHUD.AddHunger(ply, amount)
	if not IsValid(ply) or not MaxHUD.Hunger[ply] then return end

	MaxHUD.Hunger[ply] = math.Clamp(MaxHUD.Hunger[ply] + amount, 0, Config.hunger.max)
	syncHunger(ply)
end
