-- RealTime()-based deadline for the arrested countdown -- nil means not
-- currently known (not yet synced).
MaxHUD.ArrestedExpiresAt = nil

net.Receive("maxhud_arrested", function()
	local duration = net.ReadUInt(16)
	MaxHUD.ArrestedExpiresAt = duration > 0 and (RealTime() + duration) or nil
end)

local function formatMMSS(seconds)
	local m = math.floor(seconds / 60)
	local s = seconds % 60
	return string.format("%d:%02d", m, s)
end

--[[
- @return string -- "Arrested (1:59)" if a countdown is known, else just "Arrested"
]]
function MaxHUD.GetArrestedText()
	if MaxHUD.ArrestedExpiresAt then
		local remaining = math.max(0, math.ceil(MaxHUD.ArrestedExpiresAt - RealTime()))
		return "Arrested (" .. formatMMSS(remaining) .. ")"
	end
	return "Arrested"
end
