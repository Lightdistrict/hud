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

MaxHUD.Fonts = {
	value = font("value", { font = "Montserrat", size = 17, weight = 700, antialias = true }),
	label = font("label", { font = "Montserrat", size = 14, weight = 600, antialias = true }),
}
