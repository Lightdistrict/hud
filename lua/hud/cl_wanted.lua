-- RealTime()-based deadline for the wanted countdown -- nil means
-- indefinite (no wantedtime configured) or not yet received.
MaxHUD.WantedExpiresAt = nil

net.Receive("maxhud_wanted", function()
	local duration = net.ReadUInt(16)
	MaxHUD.WantedExpiresAt = duration > 0 and (RealTime() + duration) or nil
end)

local function formatMMSS(seconds)
	local m = math.floor(seconds / 60)
	local s = seconds % 60
	return string.format("%d:%02d", m, s)
end

--[[
- @return string -- "Wanted (1:59)" if a countdown is known, else just "Wanted"
]]
function MaxHUD.GetWantedText()
	if MaxHUD.WantedExpiresAt then
		local remaining = math.max(0, math.ceil(MaxHUD.WantedExpiresAt - RealTime()))
		return "Wanted (" .. formatMMSS(remaining) .. ")"
	end
	return "Wanted"
end
