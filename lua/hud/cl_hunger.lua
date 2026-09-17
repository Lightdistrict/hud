MaxHUD.MyHunger = MaxHUD.Config.hunger.max

net.Receive("maxhud_hunger", function()
	MaxHUD.MyHunger = net.ReadUInt(8)
end)
