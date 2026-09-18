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

	-- The one shared translucent strip spanning the full screen width.
	strip = Color(0, 0, 0, 90),
	-- Each individual chip sitting on top of the strip -- more opaque than
	-- the strip itself so chips read as distinct "boxes".
	chip = Color(20, 20, 22, 170),
	-- The lighter badge drawn behind every icon, inside its chip.
	iconBadge = Color(255, 255, 255, 40),
	-- Off-white (not pure white) for chip text, per spec -- icons stay pure
	-- white (color_white), text is slightly muted.
	text = Color(225, 225, 225),
}

--------------------------------------------------------------------------------
-- Icons -- from the "MAX Assets" workshop addon, which nests them under
-- materials/hud/icons/ (max_assets/materials/hud/icons/icon_health.png etc).
--
-- `job` -> icon_salary.png and `hourlySalary` -> icon_dollar.png is exactly
-- what was specified (the job chip uses the file named icon_salary, and the
-- separate hourly-salary chip uses icon_dollar) -- looks backwards, but
-- that's what's deployed; swap the two filenames here if it turns out to be
-- a mix-up once you see it in-game.
--------------------------------------------------------------------------------

Config.iconFolder = "hud/icons/"

Config.icons = {
	job = "icon_salary.png",
	health = "icon_health.png",
	armor = "icon_armor.png",
	hunger = "icon_hunger.png",
	leveling = "icon_leveling.png",
	hourlySalary = "icon_dollar.png",
	money = "icon_money.png",
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
