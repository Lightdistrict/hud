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

local BAR_H = 22
local ICON_W = 24
local SEGMENT_BAR_W = 90
local ICON_SIZE = 16

local icons
local function loadIcons()
	icons = {}
	for key, file in pairs(Config.icons) do
		icons[key] = Material(Config.iconFolder .. file, "noclamp smooth")
	end
end

local function drawIcon(key, x, y, size, col)
	if not icons then loadIcons() end

	local mat = icons[key]
	if not mat or mat:IsError() then return end

	surface.SetMaterial(mat)
	surface.SetDrawColor(col)
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
-
- @return number -- x position for the next segment
]]
local function drawStatSegment(x, y, value, max, color, iconKey, suffix)
	max = max > 0 and max or 1
	local frac = math.Clamp(value / max, 0, 1)

	surface.SetDrawColor(color)
	surface.DrawRect(x, y, ICON_W, BAR_H)
	drawIcon(iconKey, x + (ICON_W - ICON_SIZE) / 2, y + (BAR_H - ICON_SIZE) / 2, ICON_SIZE, color_white)

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
- Builds the right-side info strip's items in left-to-right order.
]]
local function buildInfoItems(ply)
	local paydelay = (GAMEMODE and GAMEMODE.Config and GAMEMODE.Config.paydelay) or Config.payDelayFallback
	local salary = ply:getDarkRPVar("salary") or 0
	local hourlySalary = salary * (3600 / paydelay)

	local items = {
		{ icon = "salary", text = DarkRP.formatMoney(math.Round(hourlySalary)) .. "/hr" },
		{ icon = "money", text = DarkRP.formatMoney(ply:getDarkRPVar("money") or 0) },
	}

	if LevelSystem and LevelSystem.MyData then
		local d = LevelSystem.MyData
		local pct = (d.xpNeeded and d.xpNeeded > 0) and math.floor((d.xp / d.xpNeeded) * 100) or 0
		local levelText = (d.prestige and d.prestige > 0 and ("P" .. d.prestige .. " ") or "") .. "Lvl " .. (d.level or 1) .. " " .. pct .. "%"
		table.insert(items, { icon = "leveling", text = levelText })
	end

	table.insert(items, { icon = "clock", text = os.date("%H:%M") })
	table.insert(items, { icon = nil, text = os.date("%m/%d/%Y") })

	return items
end

--[[
- Draws the right-side info strip as one continuous flat bar with thin
- dividers between items, flush to the top-right corner.
]]
local function drawInfoStrip(items)
	local ITEM_PAD = 10
	local ICON_GAP = 6

	surface.SetFont(MaxHUD.Fonts.label)

	local widths = {}
	local totalWidth = 0
	for i, item in ipairs(items) do
		local tw = surface.GetTextSize(item.text)
		local w = ITEM_PAD + (item.icon and (ICON_SIZE + ICON_GAP) or 0) + tw + ITEM_PAD
		widths[i] = w
		totalWidth = totalWidth + w
	end

	local x = ScrW() - totalWidth
	surface.SetDrawColor(Config.colors.background)
	surface.DrawRect(x, 0, totalWidth, BAR_H)

	local cx = x
	for i, item in ipairs(items) do
		local w = widths[i]
		local tx = cx + ITEM_PAD

		if item.icon then
			drawIcon(item.icon, tx, (BAR_H - ICON_SIZE) / 2, ICON_SIZE, Config.colors.accent)
		end

		draw.SimpleText(item.text, MaxHUD.Fonts.label, cx + w - ITEM_PAD, BAR_H / 2, Config.colors.text, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)

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
	x = drawStatSegment(x, 0, ply:Armor(), Config.armorMax, Config.colors.armor, "armor")

	local hungerPct = math.Round(((MaxHUD.MyHunger or Config.hunger.max) / Config.hunger.max) * 100)
	drawStatSegment(x, 0, hungerPct, 100, Config.colors.hunger, "hunger", "%")

	drawInfoStrip(buildInfoItems(ply))
end)
