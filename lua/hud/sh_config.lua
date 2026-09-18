local Config = MaxHUD.Config

--------------------------------------------------------------------------------
-- Colors -- matches the scoreboard/F4 menu's black background + cyan accent
-- theme, with health/armor/hunger given their own distinct colors per spec.
--------------------------------------------------------------------------------

Config.colors = {
	-- Bar-fill colors -- deliberately a different shade from that stat's
	-- icon badge color (Config.iconBadges below), so the badge and the
	-- fill read as two distinct colors rather than one repeated color.
	health = Color(163, 71, 57),
	armor = Color(57, 142, 163),
	hunger = Color(181, 122, 51),
	leveling = Color(67, 143, 181),
	accent = Color(80, 200, 255),

	-- The one shared strip spanning the full screen width -- same
	-- blackness level as the scoreboard/F4 menu's background.
	strip = Color(0, 0, 0, 210),
	-- Generic chip shell fallback (unused by name-specific chips below, but
	-- kept as a default for anything that doesn't have its own tint).
	chip = Color(20, 20, 22, 170),
	-- Off-white (not pure white) for chip text, per spec -- icons stay pure
	-- white (color_white), text is slightly muted.
	text = Color(225, 225, 225),
}

-- The small colored box directly behind each icon, per icon key -- exact
-- values as specified, not a shared generic tint.
Config.iconBadges = {
	job = Color(113, 142, 171),
	health = Color(214, 20, 15),
	armor = Color(28, 126, 237),
	hunger = Color(232, 116, 30),
	leveling = Color(4, 157, 214),
	hourlySalary = Color(23, 145, 52),
	money = Color(23, 145, 52),
	clock = Color(97, 96, 96),
}

-- Chip-shell background colors for the non-bar (info-style) chips --
-- job, salary+money (which share one color), and the combined time+date
-- chip. The bar-style chips (health/armor/hunger/leveling) use the fill
-- colors above instead; their unfilled track still uses the generic
-- `Config.colors.chip`.
Config.chipBackgrounds = {
	job = Color(60, 104, 122),
	salaryMoney = Color(62, 125, 89),
	clock = Color(76, 77, 76),
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
