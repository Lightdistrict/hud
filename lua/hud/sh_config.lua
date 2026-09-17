local Config = MaxHUD.Config

--------------------------------------------------------------------------------
-- Colors -- matches the scoreboard/F4 menu's black background + cyan accent
-- theme, with health/armor/hunger given their own distinct colors per spec.
--------------------------------------------------------------------------------

Config.colors = {
	health = Color(214, 69, 69),
	armor = Color(70, 130, 220),
	hunger = Color(230, 150, 60),
	accent = Color(80, 200, 255),
	background = Color(0, 0, 0, 180),
	text = Color(255, 255, 255),
}

--------------------------------------------------------------------------------
-- Icons -- from the "MAX Assets" workshop addon, which nests them under
-- materials/hud/icons/ (max_assets/materials/hud/icons/icon_health.png etc).
--------------------------------------------------------------------------------

Config.iconFolder = "hud/icons/"

Config.icons = {
	health = "icon_health.png",
	armor = "icon_armor.png",
	hunger = "icon_hunger.png",
	salary = "icon_salary.png",
	money = "icon_money.png",
	leveling = "icon_leveling.png",
	clock = "icon_clock2.png",
}

--------------------------------------------------------------------------------
-- Hunger -- this addon owns a minimal hunger stat since nothing else on the
-- server tracks one. It decays passively over time; `MaxHUD.AddHunger(ply,
-- amount)` (sv_hunger.lua) is exposed for a food item/entity to hook into
-- later. Resets to full on spawn.
--------------------------------------------------------------------------------

Config.hunger = {
	max = 100,
	decayPerTick = 1,   -- hunger lost every `tickInterval` seconds
	tickInterval = 30,  -- so by default it takes 100/1 * 30s = 50 minutes to starve
}

-- Armor doesn't have a real "max armor" getter on the base player -- 100 is
-- the vanilla HL2 cap. Bump this if a skill/job effect can push it higher so
-- the bar doesn't visually cap out early.
Config.armorMax = 100

-- DarkRP's own pay interval (GAMEMODE.Config.paydelay, in seconds) isn't
-- known until the gamemode's loaded -- this is only the fallback used if
-- that config value can't be read for some reason.
Config.payDelayFallback = 160
