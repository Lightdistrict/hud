MaxHUD = MaxHUD or {}
MaxHUD.Config = MaxHUD.Config or {}

local function include_shared(file)
	if SERVER then
		AddCSLuaFile(file)
	end
	include(file)
end

local function include_server(file)
	if SERVER then
		include(file)
	end
end

local function include_client(file)
	if SERVER then
		AddCSLuaFile(file)
	elseif CLIENT then
		include(file)
	end
end

include_shared("hud/sh_config.lua")

include_server("hud/sv_resources.lua")
include_server("hud/sv_laws.lua")
include_server("hud/sv_wanted.lua")
include_server("hud/sv_arrested.lua")
include_server("hud/sv_warrants.lua")
include_server("hud/sv_lockdown.lua")

include_client("hud/cl_fonts.lua")
include_client("hud/cl_wanted.lua")
include_client("hud/cl_arrested.lua")
include_client("hud/cl_warrants.lua")
include_client("hud/cl_hud.lua")
include_client("hud/cl_laws.lua")
