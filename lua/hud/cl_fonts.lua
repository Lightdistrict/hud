-- Same bundled font as the scoreboard (resource/fonts/montserrat-regular.ttf,
-- internal family name "Montserrat" -- not a stock GMod font) so the HUD
-- looks cohesive with the rest of the MAX UI.

local identifier = "maxhud"

--[[
- @param string name
- @param table|nil options
-
- @return string -- the full (prefixed) font name
]]
function MaxHUD.font(name, options)
	name = identifier .. "." .. name

	if options ~= nil then
		surface.CreateFont(name, options)
	end

	return name
end
local font = MaxHUD.font

-- Base sizes are 40% larger than the original pass (17->24, 14->20) to
-- match the whole HUD being scaled up; money/level/time/date each get an
-- additional per-item bump on top of that base label size, per spec.
local baseLabelSize = 20

-- weight = 400 (the bundled TTF's real, only weight -- montserrat-regular.ttf)
-- everywhere below. Asking for a heavier weight than a font file actually
-- has makes GMod's renderer fake-bold it via synthetic thickening, which
-- is what made this text look chunky/thick instead of sleek.
MaxHUD.Fonts = {
	value = font("value", { font = "Montserrat", size = 24, weight = 400, antialias = true }),
	label = font("label", { font = "Montserrat", size = baseLabelSize, weight = 400, antialias = true }),
	money = font("money", { font = "Montserrat", size = math.Round(baseLabelSize * 1.25), weight = 400, antialias = true }),
	level = font("level", { font = "Montserrat", size = math.Round(baseLabelSize * 1.25), weight = 400, antialias = true }),
	time = font("time", { font = "Montserrat", size = math.Round(baseLabelSize * 1.15), weight = 400, antialias = true }),
	date = font("date", { font = "Montserrat", size = math.Round(baseLabelSize * 1.20), weight = 400, antialias = true }),
	job = font("job", { font = "Montserrat", size = baseLabelSize, weight = 400, antialias = true }),
	brand = font("brand", { font = "Montserrat", size = baseLabelSize, weight = 400, antialias = true }),
}
