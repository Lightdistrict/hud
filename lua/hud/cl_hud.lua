-- One shared translucent strip across the full top of the screen, with
-- individual chips (small gap between each) sitting on top of it -- a left
-- cluster (job, health, armor, hunger, leveling, then status icons) and a
-- right cluster (hourly salary, money, time+date, brand). Each chip is one
-- seamless pill: an icon section (its own solid color, rounded only on the
-- side facing outward) fused directly against its content section (rounded
-- only on the opposite side) -- never two independently-rounded shapes.
-- Replaces DarkRP's own built-in HUD panel entirely.

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
local ICON_W = BAR_H -- the icon section of any chip, square, matches chip height
local ICON_SIZE = BAR_H - 8
-- Health/armor/hunger/leveling bars and the salary chip's content, all
-- condensed 20% horizontally per spec.
local SEGMENT_BAR_W = math.Round(90 * 1.5 * 0.8)
local CHIP_RADIUS = 6
local CHIP_GAP = 6
local CLUSTER_PAD_LEFT = 0 -- left cluster sits flush against the screen edge
local CLUSTER_PAD_RIGHT = 8
local INFO_PAD = 10

local COLOR_EMPTY_FILL = Color(60, 60, 60, 220)

local icons
local function loadIcons()
	icons = {}
	for key, file in pairs(Config.icons) do
		icons[key] = Material(Config.iconFolder .. file, "noclamp smooth")
	end
end

-- Icons are always drawn plain white, regardless of what's behind them.
-- Exposed on MaxHUD so other files (e.g. the Laws board) can reuse it.
local function drawIcon(key, x, y, size)
	if not icons then loadIcons() end

	local mat = icons[key]
	if not mat or mat:IsError() then return end

	surface.SetMaterial(mat)
	surface.SetDrawColor(color_white)
	surface.DrawTexturedRect(x, y, size, size)
end
MaxHUD.drawIcon = drawIcon
MaxHUD.BarHeight = BAR_H
MaxHUD.IconSectionWidth = ICON_W
MaxHUD.ChipRadius = CHIP_RADIUS

--[[
- Draws a chip's icon section: a solid color block, rounded only on its
- outward-facing side, with the icon centered on top.
-
- @param number x, y, w, h
- @param string iconKey
- @param Color bgColor
- @param bool roundRight -- true if this section is the right edge of the
-   chip (status icons/standalone); false rounds the left edge instead
-   (the normal case: icon section sits on the left of its content)
]]
local function drawIconSection(x, y, w, h, iconKey, bgColor, roundRight)
	if roundRight then
		draw.RoundedBoxEx(CHIP_RADIUS, x, y, w, h, bgColor, false, true, false, true)
	else
		draw.RoundedBoxEx(CHIP_RADIUS, x, y, w, h, bgColor, true, false, true, false)
	end
	drawIcon(iconKey, x + (w - ICON_SIZE) / 2, y + (h - ICON_SIZE) / 2, ICON_SIZE)
end
MaxHUD.drawIconSection = drawIconSection

--[[
- Draws one bar-style chip (health/armor/hunger/leveling): an icon section
- fused directly against a fill bar, one seamless pill -- no double
- rounding at the seam.
-
- @param number x, y
- @param number value, max
- @param Color color
- @param string iconKey
- @param string|nil text -- overrides the default "<value><suffix>" label
- @param string|nil suffix
- @param bool|nil hideColorWhenEmpty -- fill turns neutral grey at value <= 0
-   (used for armor, so it doesn't visually read as "full" at 0)
- @param bool|nil leftAlignText -- left-aligns the label near the icon
-   instead of right-aligning it near the far edge (used for leveling)
-
- @return number -- total chip width, so the caller can advance x
]]
local function drawBarChip(x, y, value, max, color, iconKey, text, suffix, hideColorWhenEmpty, leftAlignText)
	max = max > 0 and max or 1
	local frac = math.Clamp(value / max, 0, 1)
	local label = text or (math.Round(value) .. (suffix or ""))

	-- The bar always fits its own label -- long text (e.g. a high prestige
	-- + level + percent string) simply widens the bar instead of
	-- overflowing past its edge.
	surface.SetFont(MaxHUD.Fonts.value)
	local labelW = surface.GetTextSize(label)
	local barW = math.max(SEGMENT_BAR_W, labelW + INFO_PAD * 2)

	local w = ICON_W + barW
	local barX = x + ICON_W

	drawIconSection(x, y, ICON_W, BAR_H, iconKey, Config.iconBadges[iconKey], false)
	draw.RoundedBoxEx(CHIP_RADIUS, barX, y, barW, BAR_H, Config.colors.chip, false, true, false, true)

	if frac > 0 then
		local fillColor = (hideColorWhenEmpty and value <= 0) and COLOR_EMPTY_FILL or color
		local fillW = barW * frac
		if frac >= 0.999 then
			-- Fill reaches the far edge -- round it to match the track
			-- underneath, otherwise its flat corner would poke out past it.
			draw.RoundedBoxEx(CHIP_RADIUS, barX, y, fillW, BAR_H, fillColor, false, true, false, true)
		else
			surface.SetDrawColor(fillColor)
			surface.DrawRect(barX, y, fillW, BAR_H)
		end
	end

	if leftAlignText then
		draw.SimpleText(label, MaxHUD.Fonts.value, barX + INFO_PAD, y + BAR_H / 2, Config.colors.text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
	else
		draw.SimpleText(label, MaxHUD.Fonts.value, barX + barW - INFO_PAD, y + BAR_H / 2, Config.colors.text, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
	end

	return w
end

--[[
- @param string|nil iconKey
- @param string text
- @param string font
- @param number|nil widthMultiplier -- stretches the content section only,
-   the icon section always stays a fixed width
-
- @return number -- the chip's total width, without drawing anything
]]
local function measureInfoChip(iconKey, text, font, widthMultiplier)
	surface.SetFont(font)
	local tw = surface.GetTextSize(text)
	local contentW = math.Round((INFO_PAD + tw + INFO_PAD) * (widthMultiplier or 1))
	return (iconKey and ICON_W or 0) + contentW
end

--[[
- Draws one info-style chip (job/salary/money) at a known width and
- position: icon section fused against a content section, one seamless
- pill, with right-aligned text.
-
- @param number x, y, w -- w should come from measureInfoChip with the same
-   arguments, so the icon/text land inside it correctly
- @param string|nil iconKey
- @param string text
- @param string font
- @param Color|nil bgColor -- defaults to the generic chip color
]]
local function drawInfoChip(x, y, w, iconKey, text, font, bgColor)
	bgColor = bgColor or Config.colors.chip

	if iconKey then
		drawIconSection(x, y, ICON_W, BAR_H, iconKey, Config.iconBadges[iconKey], false)
		draw.RoundedBoxEx(CHIP_RADIUS, x + ICON_W, y, w - ICON_W, BAR_H, bgColor, false, true, false, true)
	else
		draw.RoundedBox(CHIP_RADIUS, x, y, w, BAR_H, bgColor)
	end

	draw.SimpleText(text, font, x + w - INFO_PAD, y + BAR_H / 2, Config.colors.text, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
end

--[[
- Draws a standalone, icon-only square badge (wanted/arrested/license,
- lockdown, etc) -- no content section, fully rounded.
-
- @return number -- the badge's width (== BAR_H), so the caller can advance
]]
local function drawStatusIcon(x, y, iconKey)
	draw.RoundedBox(CHIP_RADIUS, x, y, BAR_H, BAR_H, Config.statusIconBg)
	drawIcon(iconKey, x + (BAR_H - ICON_SIZE) / 2, y + (BAR_H - ICON_SIZE) / 2, ICON_SIZE)
	return BAR_H
end

local CLOCK_GAP = 8 -- space between the time and date text, inside the same chip

-- Time and date share one font/size (both use "time") so they line up on
-- the same baseline instead of looking mismatched against each other.
local CLOCK_FONT = MaxHUD.Fonts.time

--[[
- @return number -- the combined time+date chip's total width
]]
local function measureClockChip(timeText, dateText)
	surface.SetFont(CLOCK_FONT)
	local timeW = surface.GetTextSize(timeText)
	local dateW = surface.GetTextSize(dateText)
	return ICON_W + INFO_PAD + timeW + CLOCK_GAP + dateW + INFO_PAD
end

--[[
- Draws the combined time+date chip: one icon section, one content
- section, time and date text side by side with a small gap between them.
]]
local function drawClockChip(x, y, w, timeText, dateText)
	drawIconSection(x, y, ICON_W, BAR_H, "clock", Config.iconBadges.clock, false)
	draw.RoundedBoxEx(CHIP_RADIUS, x + ICON_W, y, w - ICON_W, BAR_H, Config.chipBackgrounds.clock, false, true, false, true)

	local tx = x + ICON_W + INFO_PAD
	surface.SetFont(CLOCK_FONT)
	local timeW = surface.GetTextSize(timeText)
	draw.SimpleText(timeText, CLOCK_FONT, tx, y + BAR_H / 2, Config.colors.text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
	draw.SimpleText(dateText, CLOCK_FONT, tx + timeW + CLOCK_GAP, y + BAR_H / 2, Config.colors.text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
end

local BRAND_TEXT = "MAX SERVERS"

--[[
- @return number -- the brand chip's total width, without drawing anything
]]
local function measureBrandChip()
	surface.SetFont(MaxHUD.Fonts.brand)
	return surface.GetTextSize(BRAND_TEXT) + INFO_PAD * 2
end

-- How long a full one-way sweep across the text takes, in seconds -- the
-- window bounces back and forth (like a Cylon/KITT scanner) rather than
-- wrapping, so a full cycle is twice this.
local SCAN_SWEEP_SECONDS = 2

--[[
- Draws the brand text at a known position: "MAX SERVERS", default white,
- with a 3-letter-wide cyan window sweeping back and forth across it on a
- loop. No chip background -- just floats on the shared strip, per spec.
]]
local function drawBrandChip(x, y, w)
	local text = BRAND_TEXT
	local font = MaxHUD.Fonts.brand
	surface.SetFont(font)

	local len = #text
	local t = RealTime() % (SCAN_SWEEP_SECONDS * 2)
	local progress = t < SCAN_SWEEP_SECONDS and (t / SCAN_SWEEP_SECONDS) or (2 - t / SCAN_SWEEP_SECONDS)
	local center = progress * (len - 1)

	local cx = x + INFO_PAD
	for i = 1, len do
		local ch = text:sub(i, i)
		local col = math.abs((i - 1) - center) <= 1.2 and Config.colors.accent or color_white
		draw.SimpleText(ch, font, cx, y + BAR_H / 2, col, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
		cx = cx + surface.GetTextSize(ch)
	end
end

--------------------------------------------------------------------------------
-- Center-strip alerts -- lockdown, and anything else registered later (e.g.
-- a future lottery addon). Each is just an icon shown while its check
-- function returns true, centered in the strip's empty middle space.
--------------------------------------------------------------------------------

MaxHUD.CenterAlerts = MaxHUD.CenterAlerts or {}

--[[
- @param string iconKey
- @param function checkFn -- function() return bool end
- @param function|nil textFn -- function() return string end -- if given,
-   draws an icon+text warning box (glowing red text) instead of a bare
-   icon-only badge
]]
function MaxHUD.RegisterCenterAlert(iconKey, checkFn, textFn)
	table.insert(MaxHUD.CenterAlerts, { icon = iconKey, check = checkFn, text = textFn })
end

MaxHUD.RegisterCenterAlert("lockdown", function()
	return GetGlobalBool("DarkRP_LockDown", false)
end, function()
	return "Lockdown is active!"
end)

--[[
- @return number -- t interpolated between two colors (0..1)
]]
local function lerpColor(t, a, b)
	return Color(Lerp(t, a.r, b.r), Lerp(t, a.g, b.g), Lerp(t, a.b, b.b))
end

--[[
- Draws one center-strip alert: an icon-only badge if `text` is nil, or an
- icon fused against a text box with a pulsing red glow if it's set.
-
- @return number -- the alert's width, so the caller can advance x
]]
local function drawAlertBox(x, y, iconKey, text)
	if not text then
		return drawStatusIcon(x, y, iconKey)
	end

	surface.SetFont(MaxHUD.Fonts.value)
	local contentW = INFO_PAD + surface.GetTextSize(text) + INFO_PAD
	local w = ICON_W + contentW

	drawIconSection(x, y, ICON_W, BAR_H, iconKey, Config.statusIconBg, false)
	draw.RoundedBoxEx(CHIP_RADIUS, x + ICON_W, y, contentW, BAR_H, Config.statusIconBg, false, true, false, true)

	local pulse = (math.sin(RealTime() * 6) + 1) / 2
	local glowColor = lerpColor(pulse, Config.colors.lockdownGlowLow, Config.colors.lockdownGlowHigh)
	draw.SimpleText(text, MaxHUD.Fonts.value, x + ICON_W + INFO_PAD, y + BAR_H / 2, glowColor, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

	return w
end

local function drawCenterAlerts()
	local active = {}
	for _, alert in ipairs(MaxHUD.CenterAlerts) do
		if alert.check() then
			table.insert(active, { icon = alert.icon, text = alert.text and alert.text() or nil })
		end
	end
	if #active == 0 then return end

	local totalW = 0
	for _, a in ipairs(active) do
		if a.text then
			surface.SetFont(MaxHUD.Fonts.value)
			totalW = totalW + ICON_W + INFO_PAD + surface.GetTextSize(a.text) + INFO_PAD
		else
			totalW = totalW + BAR_H
		end
	end
	totalW = totalW + (#active - 1) * CHIP_GAP

	local cx = ScrW() / 2 - totalW / 2
	for _, a in ipairs(active) do
		cx = cx + drawAlertBox(cx, 0, a.icon, a.text) + CHIP_GAP
	end
end

hook.Add("HUDPaint", "maxhud_draw", function()
	local ply = LocalPlayer()
	if not IsValid(ply) or not ply:Alive() then return end

	-- One shared translucent strip across the entire top of the screen.
	surface.SetDrawColor(Config.colors.strip)
	surface.DrawRect(0, 0, ScrW(), BAR_H)

	-- Left cluster: job, health, armor, hunger, leveling, status icons.
	local x = CLUSTER_PAD_LEFT
	local jobText = ply:getDarkRPVar("job") or "Unemployed"
	local jobW = measureInfoChip("job", jobText, MaxHUD.Fonts.job)
	drawInfoChip(x, 0, jobW, "job", jobText, MaxHUD.Fonts.job, Config.chipBackgrounds.job)
	x = x + jobW + CHIP_GAP

	x = x + drawBarChip(x, 0, ply:Health(), ply:GetMaxHealth(), Config.colors.health, "health") + CHIP_GAP
	x = x + drawBarChip(x, 0, ply:Armor(), Config.armorMax, Config.colors.armor, "armor", nil, nil, true) + CHIP_GAP

	-- Real DarkRP hunger -- the "Energy" DarkRP var, registered and decayed
	-- by DarkRP's own hungermod module (net.WriteFloat/ReadFloat, already
	-- networked to the owning client same as money/salary).
	local energy = math.Round(ply:getDarkRPVar("Energy") or 100)
	x = x + drawBarChip(x, 0, energy, 100, Config.colors.hunger, "hunger", nil, "%") + CHIP_GAP

	if LevelSystem and LevelSystem.MyData then
		local d = LevelSystem.MyData
		local pct = (d.xpNeeded and d.xpNeeded > 0) and math.floor((d.xp / d.xpNeeded) * 100) or 0
		local levelText = (d.prestige and d.prestige > 0 and ("P" .. d.prestige .. " ") or "") .. "Lvl " .. (d.level or 1) .. " " .. pct .. "%"
		x = x + drawBarChip(x, 0, d.xp or 0, d.xpNeeded or 1, Config.colors.leveling, "leveling", levelText, nil, false, true) + CHIP_GAP
	end

	-- Status icons -- wanted/arrested/license, real DarkRP state, verified
	-- against the actual gamemode source (ply:isWanted/isArrested, and the
	-- "HasGunlicense" DarkRP var used by DarkRP's own police module).
	if ply:isWanted() then
		x = x + drawStatusIcon(x, 0, "wanted") + CHIP_GAP
	end
	if ply:isArrested() then
		x = x + drawStatusIcon(x, 0, "arrested") + CHIP_GAP
	end
	if ply:getDarkRPVar("HasGunlicense") then
		x = x + drawStatusIcon(x, 0, "license") + CHIP_GAP
	end

	drawCenterAlerts()

	-- Right cluster: money, hourly salary, time+date, brand -- built
	-- right-to-left from the screen edge so the visual order still reads
	-- left-to-right. No currency symbol on the numbers, per spec -- plain
	-- comma-formatted numbers instead of DarkRP.formatMoney().
	local paydelay = (GAMEMODE and GAMEMODE.Config and GAMEMODE.Config.paydelay) or Config.payDelayFallback
	local salary = ply:getDarkRPVar("salary") or 0
	local hourlySalary = salary * (3600 / paydelay)
	local salaryText = string.Comma(math.Round(hourlySalary)) .. "/hr"
	local moneyText = string.Comma(math.Round(ply:getDarkRPVar("money") or 0))
	local timeText = os.date("%H:%M")
	local dateText = os.date("%m/%d/%Y")

	local rx = ScrW() - CLUSTER_PAD_RIGHT
	local w

	w = measureBrandChip()
	rx = rx - w
	drawBrandChip(rx, 0, w)
	rx = rx - CHIP_GAP

	w = measureClockChip(timeText, dateText)
	rx = rx - w
	drawClockChip(rx, 0, w, timeText, dateText)
	rx = rx - CHIP_GAP

	w = measureInfoChip("money", moneyText, MaxHUD.Fonts.money)
	rx = rx - w
	drawInfoChip(rx, 0, w, "money", moneyText, MaxHUD.Fonts.money, Config.chipBackgrounds.salaryMoney)
	rx = rx - CHIP_GAP

	-- Salary's text now matches money's font/size exactly (was a smaller
	-- font before). Content was previously widened 25%, now condensed 20%
	-- on top of that per spec (1.25 * 0.8 = 1.0 -- nets out to its natural
	-- width).
	w = measureInfoChip("hourlySalary", salaryText, MaxHUD.Fonts.money, 1.0)
	rx = rx - w
	drawInfoChip(rx, 0, w, "hourlySalary", salaryText, MaxHUD.Fonts.money, Config.chipBackgrounds.salaryMoney)
end)
