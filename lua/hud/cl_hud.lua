-- One shared translucent strip across the full top of the screen, with
-- individual rounded chips (small gap between each) sitting on top of it --
-- a left cluster (job, health, armor, hunger, leveling) and a right cluster
-- (hourly salary, money, time, date, brand). Replaces DarkRP's own
-- built-in HUD panel entirely.

local Config = MaxHUD.Config

-- DarkRP already hides CHudHealth/CHudBattery/CHudSuitPower/CHUDQuickInfo in
-- favor of its own "DarkRP_LocalPlayerHUD" panel (see the real DarkRP
-- source, gamemode/modules/hud/cl_hud.lua) -- hide that one panel too so we
-- can draw our own version instead of stacking on top of it.
hook.Add("HUDShouldDraw", "maxhud_hide_darkrp_hud", function(name)
	if name == "DarkRP_LocalPlayerHUD" then
		return false
	end
end)

local BAR_H = math.Round(22 * 1.4)
local ICON_W = BAR_H -- the icon side of a bar chip, square, matches chip height
local ICON_SIZE = BAR_H - 8
local ICON_BADGE_SIZE = ICON_SIZE + 8
local SEGMENT_BAR_W = math.Round(90 * 1.5)
local CHIP_RADIUS = 6
local CHIP_GAP = 6
local CLUSTER_PAD = 8 -- left/right screen-edge padding for each cluster

local COLOR_EMPTY_FILL = Color(60, 60, 60, 220)

local icons
local function loadIcons()
	icons = {}
	for key, file in pairs(Config.icons) do
		icons[key] = Material(Config.iconFolder .. file, "noclamp smooth")
	end
end

-- Icons are always drawn plain white, regardless of what's behind them.
local function drawIcon(key, x, y, size)
	if not icons then loadIcons() end

	local mat = icons[key]
	if not mat or mat:IsError() then return end

	surface.SetMaterial(mat)
	surface.SetDrawColor(color_white)
	surface.DrawTexturedRect(x, y, size, size)
end

--[[
- Draws one bar-style chip (health/armor/hunger/leveling): a rounded chip
- shell, an icon on a lighter badge, a proportional fill bar, and the value
- text over it.
-
- @param number x, y
- @param number value, max
- @param Color color
- @param string iconKey
- @param string|nil text -- overrides the default "<value><suffix>" label
- @param string|nil suffix
- @param bool|nil hideColorWhenEmpty -- fill turns neutral grey at value <= 0
-   (used for armor, so it doesn't visually read as "full" at 0)
-
- @return number -- total chip width, so the caller can advance x
]]
local function drawBarChip(x, y, value, max, color, iconKey, text, suffix, hideColorWhenEmpty)
	max = max > 0 and max or 1
	local frac = math.Clamp(value / max, 0, 1)
	local w = ICON_W + SEGMENT_BAR_W

	draw.RoundedBox(CHIP_RADIUS, x, y, w, BAR_H, Config.colors.chip)

	local barX = x + ICON_W
	if frac > 0 then
		local fillColor = (hideColorWhenEmpty and value <= 0) and COLOR_EMPTY_FILL or color
		draw.RoundedBox(CHIP_RADIUS, barX, y, SEGMENT_BAR_W * frac, BAR_H, fillColor)
	end

	local badgeX, badgeY = x + ICON_W / 2, y + BAR_H / 2
	draw.RoundedBox(4, badgeX - ICON_BADGE_SIZE / 2, badgeY - ICON_BADGE_SIZE / 2, ICON_BADGE_SIZE, ICON_BADGE_SIZE, Config.colors.iconBadge)
	drawIcon(iconKey, badgeX - ICON_SIZE / 2, badgeY - ICON_SIZE / 2, ICON_SIZE)

	local label = text or (math.Round(value) .. (suffix or ""))
	draw.SimpleText(label, MaxHUD.Fonts.value, barX + SEGMENT_BAR_W - 8, y + BAR_H / 2, Config.colors.text, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)

	return w
end

local INFO_PAD = 10
local INFO_ICON_GAP = 6

--[[
- @param string|nil iconKey
- @param string text
- @param string font
- @param number|nil widthMultiplier
-
- @return number -- the chip's total width, without drawing anything
]]
local function measureInfoChip(iconKey, text, font, widthMultiplier)
	surface.SetFont(font)
	local tw = surface.GetTextSize(text)
	local natural = INFO_PAD + (iconKey and (ICON_SIZE + INFO_ICON_GAP) or 0) + tw + INFO_PAD
	return math.Round(natural * (widthMultiplier or 1))
end

--[[
- Draws one info-style chip (job/salary/money/time/date) at a known width
- and position: a rounded chip shell, an optional icon on a lighter badge,
- and text.
-
- @param number x, y, w -- w should come from measureInfoChip with the same
-   arguments, so the icon/text land inside it correctly
- @param string|nil iconKey
- @param string text
- @param string font
]]
local function drawInfoChip(x, y, w, iconKey, text, font)
	draw.RoundedBox(CHIP_RADIUS, x, y, w, BAR_H, Config.colors.chip)

	if iconKey then
		local badgeX, badgeY = x + INFO_PAD + ICON_SIZE / 2, y + BAR_H / 2
		draw.RoundedBox(4, badgeX - ICON_BADGE_SIZE / 2, badgeY - ICON_BADGE_SIZE / 2, ICON_BADGE_SIZE, ICON_BADGE_SIZE, Config.colors.iconBadge)
		drawIcon(iconKey, badgeX - ICON_SIZE / 2, badgeY - ICON_SIZE / 2, ICON_SIZE)
	end

	draw.SimpleText(text, font, x + w - INFO_PAD, y + BAR_H / 2, Config.colors.text, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
end

--[[
- @return number -- the brand chip's total width, without drawing anything
]]
local function measureBrandChip()
	surface.SetFont(MaxHUD.Fonts.brand)
	return surface.GetTextSize("MAX Servers") + INFO_PAD * 2
end

--[[
- Draws the brand chip at a known position: "MAX" in the cyan accent color,
- "Servers" in white.
]]
local function drawBrandChip(x, y, w)
	local font = MaxHUD.Fonts.brand
	surface.SetFont(font)
	local maxW = surface.GetTextSize("MAX")

	draw.RoundedBox(CHIP_RADIUS, x, y, w, BAR_H, Config.colors.chip)
	draw.SimpleText("MAX", font, x + INFO_PAD, y + BAR_H / 2, Config.colors.accent, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
	draw.SimpleText(" Servers", font, x + INFO_PAD + maxW, y + BAR_H / 2, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
end

hook.Add("HUDPaint", "maxhud_draw", function()
	local ply = LocalPlayer()
	if not IsValid(ply) or not ply:Alive() then return end

	-- One shared translucent strip across the entire top of the screen.
	surface.SetDrawColor(Config.colors.strip)
	surface.DrawRect(0, 0, ScrW(), BAR_H)

	-- Left cluster: job, health, armor, hunger, leveling.
	local x = CLUSTER_PAD
	local jobText = ply:getDarkRPVar("job") or "Unemployed"
	local jobW = measureInfoChip("job", jobText, MaxHUD.Fonts.job)
	drawInfoChip(x, 0, jobW, "job", jobText, MaxHUD.Fonts.job)
	x = x + jobW + CHIP_GAP

	x = x + drawBarChip(x, 0, ply:Health(), ply:GetMaxHealth(), Config.colors.health, "health") + CHIP_GAP
	x = x + drawBarChip(x, 0, ply:Armor(), Config.armorMax, Config.colors.armor, "armor", nil, nil, true) + CHIP_GAP

	local hungerPct = math.Round(((MaxHUD.MyHunger or Config.hunger.max) / Config.hunger.max) * 100)
	x = x + drawBarChip(x, 0, hungerPct, 100, Config.colors.hunger, "hunger", nil, "%") + CHIP_GAP

	if LevelSystem and LevelSystem.MyData then
		local d = LevelSystem.MyData
		local pct = (d.xpNeeded and d.xpNeeded > 0) and math.floor((d.xp / d.xpNeeded) * 100) or 0
		local levelText = (d.prestige and d.prestige > 0 and ("P" .. d.prestige .. " ") or "") .. "Lvl " .. (d.level or 1) .. " " .. pct .. "%"
		drawBarChip(x, 0, d.xp or 0, d.xpNeeded or 1, Config.colors.accent, "leveling", levelText)
	end

	-- Right cluster: hourly salary, money, time, date, brand -- built
	-- right-to-left from the screen edge so the visual order still reads
	-- left-to-right.
	local paydelay = (GAMEMODE and GAMEMODE.Config and GAMEMODE.Config.paydelay) or Config.payDelayFallback
	local salary = ply:getDarkRPVar("salary") or 0
	local hourlySalary = salary * (3600 / paydelay)
	local salaryText = DarkRP.formatMoney(math.Round(hourlySalary)) .. "/hr"
	local moneyText = DarkRP.formatMoney(ply:getDarkRPVar("money") or 0)
	local timeText = os.date("%H:%M")
	local dateText = os.date("%m/%d/%Y")

	local rx = ScrW() - CLUSTER_PAD
	local w

	w = measureBrandChip()
	rx = rx - w
	drawBrandChip(rx, 0, w)
	rx = rx - CHIP_GAP

	w = measureInfoChip(nil, dateText, MaxHUD.Fonts.date)
	rx = rx - w
	drawInfoChip(rx, 0, w, nil, dateText, MaxHUD.Fonts.date)
	rx = rx - CHIP_GAP

	w = measureInfoChip("clock", timeText, MaxHUD.Fonts.time)
	rx = rx - w
	drawInfoChip(rx, 0, w, "clock", timeText, MaxHUD.Fonts.time)
	rx = rx - CHIP_GAP

	w = measureInfoChip("money", moneyText, MaxHUD.Fonts.money)
	rx = rx - w
	drawInfoChip(rx, 0, w, "money", moneyText, MaxHUD.Fonts.money)
	rx = rx - CHIP_GAP

	w = measureInfoChip("hourlySalary", salaryText, MaxHUD.Fonts.label, 1.25)
	rx = rx - w
	drawInfoChip(rx, 0, w, "hourlySalary", salaryText, MaxHUD.Fonts.label)
end)
