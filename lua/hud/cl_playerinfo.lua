-- 3D2D overhead player info, replacing DarkRP's own screen-space version
-- (plyMeta:drawPlayerInfo/drawWantedInfo, gamemode/modules/hud/cl_hud.lua
-- -- both suppressed via "DarkRP_EntityDisplay" in cl_hud.lua) with world-
-- space text drawn above each player's head, matching the rest of the MAX
-- UI (Montserrat, dark outline).
--
-- Name/job are shown for anyone within NAMETAG_RANGE. Wanted/Arrested are
-- shown from much further away (STATUS_RANGE) regardless of proximity --
-- DarkRP's own wanted text already works this way (drawn for every wanted
-- player every frame, not just when looked at, gamemode/modules/hud/
-- cl_hud.lua's DrawEntityDisplay); Arrested doesn't have a DarkRP
-- equivalent above-head, so this adds it to match.

local Config = MaxHUD.Config

surface.CreateFont("maxhud.playertag_name", { font = "Montserrat", size = 34, weight = 700, antialias = true })
surface.CreateFont("maxhud.playertag_job", { font = "Montserrat", size = 26, weight = 600, antialias = true })
surface.CreateFont("maxhud.playertag_status", { font = "Montserrat", size = 30, weight = 800, antialias = true })

local NAMETAG_RANGE = 700
local STATUS_RANGE = 2000

hook.Add("PostDrawTranslucentRenderables", "maxhud_draw_playerinfo", function()
	local lp = LocalPlayer()
	if not IsValid(lp) then return end

	-- Billboard angle: always faces the local camera's yaw, the standard
	-- GMod 3D2D nametag technique -- independent of each target's own
	-- position, so it's computed once per frame rather than per player.
	local billboardAng = Angle(0, lp:EyeAngles().y - 90, 90)

	for _, ply in ipairs(player.GetAll()) do
		if ply == lp or not IsValid(ply) or not ply:Alive() then continue end

		local dist = ply:GetPos():Distance(lp:GetPos())
		if dist > STATUS_RANGE then continue end

		local wanted = ply:isWanted()
		local arrested = ply:isArrested()
		local showNametag = dist <= NAMETAG_RANGE

		if not showNametag and not wanted and not arrested then continue end

		local pos = ply:EyePos() + Vector(0, 0, 14)
		local fadeMul = math.Clamp(1 - (dist / STATUS_RANGE), 0.3, 1)

		cam.Start3D2D(pos, billboardAng, 0.1)
			local y = 0

			if wanted then
				draw.SimpleTextOutlined("WANTED", "maxhud.playertag_status", 0, y, ColorAlpha(Config.colors.health, 255 * fadeMul), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP, 1, ColorAlpha(color_black, 200 * fadeMul))
				y = y + 34
			elseif arrested then
				draw.SimpleTextOutlined("ARRESTED", "maxhud.playertag_status", 0, y, ColorAlpha(Config.colors.text, 255 * fadeMul), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP, 1, ColorAlpha(color_black, 200 * fadeMul))
				y = y + 34
			end

			if showNametag then
				local teamColor = team.GetColor(ply:Team())
				draw.SimpleTextOutlined(ply:Nick(), "maxhud.playertag_name", 0, y, ColorAlpha(teamColor, 255 * fadeMul), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP, 1, ColorAlpha(color_black, 200 * fadeMul))
				y = y + 30

				local job = ply:getDarkRPVar("job") or team.GetName(ply:Team())
				draw.SimpleTextOutlined(job, "maxhud.playertag_job", 0, y, ColorAlpha(Config.colors.text, 220 * fadeMul), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP, 1, ColorAlpha(color_black, 200 * fadeMul))
			end
		cam.End3D2D()
	end
end)
