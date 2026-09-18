-- Draws the Laws board (mayor-managed, visible to everyone) below the
-- right side of the top strip, when a law text has been set. Icon section
-- + header fused as one pill (same pattern as every other chip), then a
-- red-tinted body box with the wrapped law text underneath.

local Config = MaxHUD.Config

MaxHUD.LawsText = Config.defaultLaws

net.Receive("maxhud_laws", function()
	MaxHUD.LawsText = net.ReadString()
end)

local BOARD_W = 300
local PAD = 10

--[[
- Word-wraps `text` to fit within `maxWidth` using the currently-set font.
- Respects existing newlines (e.g. a numbered rule list) as hard breaks,
- only wrapping within each of those lines when it's too long on its own.
-
- @return table -- array of line strings
]]
local function wrapText(text, maxWidth)
	local lines = {}

	for paragraph in string.gmatch(text .. "\n", "([^\n]*)\n") do
		local line = ""
		for word in string.gmatch(paragraph, "%S+") do
			local candidate = line == "" and word or (line .. " " .. word)
			if surface.GetTextSize(candidate) > maxWidth and line ~= "" then
				table.insert(lines, line)
				line = word
			else
				line = candidate
			end
		end
		table.insert(lines, line)
	end

	return lines
end

hook.Add("HUDPaint", "maxhud_draw_laws", function()
	if MaxHUD.LawsText == "" then return end
	if not IsValid(LocalPlayer()) or not LocalPlayer():Alive() then return end

	local barH = MaxHUD.BarHeight
	local iconW = MaxHUD.IconSectionWidth
	local radius = MaxHUD.ChipRadius
	local font = MaxHUD.Fonts.label

	surface.SetFont(font)
	local lines = wrapText(MaxHUD.LawsText, BOARD_W - PAD * 2)
	local _, lineH = surface.GetTextSize("A")
	local bodyH = PAD * 2 + (#lines * (lineH + 4)) - 4

	local x = ScrW() - BOARD_W - 8
	local y = barH + 6

	-- Header: icon section fused against a "THE LAWS" title section.
	MaxHUD.drawIconSection(x, y, iconW, barH, "agenda", Config.iconBadges.agenda, false)
	draw.RoundedBoxEx(radius, x + iconW, y, BOARD_W - iconW, barH, Config.colors.chip, false, true, false, true)
	draw.SimpleText("THE LAWS", font, x + iconW + PAD, y + barH / 2, Config.colors.text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

	-- Body
	local bodyY = y + barH + 4
	draw.RoundedBox(radius, x, bodyY, BOARD_W, bodyH, Config.colors.lawsBody)

	local ly = bodyY + PAD
	for _, line in ipairs(lines) do
		draw.SimpleText(line, font, x + PAD, ly, Config.colors.text, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
		ly = ly + lineH + 4
	end
end)
