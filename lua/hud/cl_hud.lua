-- Minimalistic HUD, flush to the top-left (health/armor/hunger) and
-- top-right (salary/money/level/clock/date) corners as one continuous flat
-- strip per side -- no gaps, no rounded pill boxes -- replacing DarkRP's
-- own built-in HUD panel entirely.

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

-- Whole HUD scaled 40% taller than the original pass (22 -> 31), and the
-- health/armor/hunger bars an additional 50% wider (90 -> 135).
local BAR_H = math.Round(22 * 1.4)
local ICON_W = BAR_H -- square icon block, matches the bar's full height
local ICON_SIZE = BAR_H - 8
local SEGMENT_BAR_W = math.Round(90 * 1.5)

local COLOR_EMPTY_BG = Color(30, 30, 30, 220)

local icons
local function loadIcons()
	icons = {}
	for key, file in pairs(Config.icons) do
		icons[key] = Material(Config.iconFolder .. file, "noclamp smooth")
	end
end

-- Icons are always drawn plain white, regardless of the segment/pill color
-- behind them.
local function drawIcon(key, x, y, size)
	if not icons then loadIcons() end

	local mat = icons[key]
	if not mat or mat:IsError() then return end

	surface.SetMaterial(mat)
	surface.SetDrawColor(color_white)
	surface.DrawTexturedRect(x, y, size, size)
end

--[[
- Draws one flush stat segment (icon block + fill bar butted right against
- it, no gaps) and returns the x position the next segment should start at.
-
- @param number x, y
- @param number value, max
- @param Color color
- @param string iconKey
- @param string|nil suffix -- e.g. "%" for hunger
- @param bool|nil hideColorWhenEmpty -- if true, the icon block and any
-   filled portion turn neutral grey instead of `color` when value <= 0
-   (used for armor, so it doesn't look "full" of color at 0)
-
- @return number -- x position for the next segment
]]
local function drawStatSegment(x, y, value, max, color, iconKey, suffix, hideColorWhenEmpty)
	max = max > 0 and max or 1
	local frac = math.Clamp(value / max, 0, 1)
	local hasValue = value > 0

	local iconColor = (hideColorWhenEmpty and not hasValue) and COLOR_EMPTY_BG or color

	surface.SetDrawColor(iconColor)
	surface.DrawRect(x, y, ICON_W, BAR_H)
	drawIcon(iconKey, x + (ICON_W - ICON_SIZE) / 2, y + (BAR_H - ICON_SIZE) / 2, ICON_SIZE)

	local barX = x + ICON_W
	surface.SetDrawColor(20, 20, 20, 220)
	surface.DrawRect(barX, y, SEGMENT_BAR_W, BAR_H)
	if frac > 0 then
		surface.SetDrawColor(color)
		surface.DrawRect(barX, y, SEGMENT_BAR_W * frac, BAR_H)
	end

	local text = math.Round(value) .. (suffix or "")
	draw.SimpleText(text, MaxHUD.Fonts.value, barX + SEGMENT_BAR_W - 8, y + BAR_H / 2, Config.colors.text, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)

	return barX + SEGMENT_BAR_W
end

--[[
- Builds the right-side info strip's items in left-to-right order. Each
- item can carry its own `font` (defaults to the base label font) and
- `widthMultiplier` (extra breathing room added to its box without
- affecting its text size -- used for salary's "25% thicker" width-only
- bump).
]]
local function buildInfoItems(ply)
	local paydelay = (GAMEMODE and GAMEMODE.Config and GAMEMODE.Config.paydelay) or Config.payDelayFallback
	local salary = ply:getDarkRPVar("salary") or 0
	local hourlySalary = salary * (3600 / paydelay)

	local items = {
		{ icon = "salary", text = DarkRP.formatMoney(math.Round(hourlySalary)) .. "/hr", font = MaxHUD.Fonts.label, widthMultiplier = 1.25 },
		{ icon = "money", text = DarkRP.formatMoney(ply:getDarkRPVar("money") or 0), font = MaxHUD.Fonts.money },
	}

	if LevelSystem and LevelSystem.MyData then
		local d = LevelSystem.MyData
		local pct = (d.xpNeeded and d.xpNeeded > 0) and math.floor((d.xp / d.xpNeeded) * 100) or 0
		local levelText = (d.prestige and d.prestige > 0 and ("P" .. d.prestige .. " ") or "") .. "Lvl " .. (d.level or 1) .. " " .. pct .. "%"
		table.insert(items, { icon = "leveling", text = levelText, font = MaxHUD.Fonts.level })
	end

	table.insert(items, { icon = "clock", text = os.date("%H:%M"), font = MaxHUD.Fonts.time })
	table.insert(items, { icon = nil, text = os.date("%m/%d/%Y"), font = MaxHUD.Fonts.date })

	return items
end

--[[
- Draws the right-side info strip as one continuous flat bar with thin
- dividers between items, flush to the top-right corner.
]]
local function drawInfoStrip(items)
	local ITEM_PAD = 10
	local ICON_GAP = 6

	local widths = {}
	local naturalWidths = {}
	local totalWidth = 0
	for i, item in ipairs(items) do
		surface.SetFont(item.font)
		local tw = surface.GetTextSize(item.text)
		local natural = ITEM_PAD + (item.icon and (ICON_SIZE + ICON_GAP) or 0) + tw + ITEM_PAD
		local w = math.Round(natural * (item.widthMultiplier or 1))
		naturalWidths[i] = natural
		widths[i] = w
		totalWidth = totalWidth + w
	end

	local x = ScrW() - totalWidth
	surface.SetDrawColor(Config.colors.background)
	surface.DrawRect(x, 0, totalWidth, BAR_H)

	local cx = x
	for i, item in ipairs(items) do
		local w = widths[i]
		local extra = w - naturalWidths[i]
		local tx = cx + extra + ITEM_PAD

		if item.icon then
			drawIcon(item.icon, tx, (BAR_H - ICON_SIZE) / 2, ICON_SIZE)
		end

		draw.SimpleText(item.text, item.font, cx + w - ITEM_PAD, BAR_H / 2, Config.colors.text, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)

		if i < #items then
			surface.SetDrawColor(255, 255, 255, 30)
			surface.DrawRect(cx + w - 1, 3, 1, BAR_H - 6)
		end

		cx = cx + w
	end
end

hook.Add("HUDPaint", "maxhud_draw", function()
	local ply = LocalPlayer()
	if not IsValid(ply) or not ply:Alive() then return end

	local x = 0
	x = drawStatSegment(x, 0, ply:Health(), ply:GetMaxHealth(), Config.colors.health, "health")
	x = drawStatSegment(x, 0, ply:Armor(), Config.armorMax, Config.colors.armor, "armor", nil, true)

	local hungerPct = math.Round(((MaxHUD.MyHunger or Config.hunger.max) / Config.hunger.max) * 100)
	drawStatSegment(x, 0, hungerPct, 100, Config.colors.hunger, "hunger", "%")

	drawInfoStrip(buildInfoItems(ply))
end)
