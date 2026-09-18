MaxHUD.WarrantCount = 0

net.Receive("maxhud_warrant_count", function()
	MaxHUD.WarrantCount = net.ReadUInt(8)
end)
