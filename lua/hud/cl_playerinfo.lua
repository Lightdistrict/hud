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

-- Reuses the exact same fonts (and cam.Start3D2D scale) as cl_doorinfo.lua's
-- door price text -- "maxhud.door_title"/"maxhud.door_sub" -- so overhead
-- tags read as the same UI system as the on-door text instead of a
-- separately-tuned look.

local NAMETAG_RANGE = 700
local STATUS_RANGE = 2000
local SCALE = 0.05

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
		local teamColor = team.GetColor(ply:Team())

		-- Whichever line is most important becomes the big "door_title"
		-- line (bottom-aligned at y=0, exactly like the door price text),
		-- everything else stacks below it as smaller "door_sub" lines --
		-- same two-tier look as the door info, just applied to a person.
		local primaryText, primaryColor
		if wanted then
			primaryText, primaryColor = "WANTED", Config.colors.health
		elseif arrested then
			primaryText, primaryColor = "ARRESTED", Config.colors.text
		elseif showNametag then
			primaryText, primaryColor = ply:Nick(), teamColor
		end

		if not primaryText then continue end

		cam.Start3D2D(pos, billboardAng, SCALE)
			draw.SimpleTextOutlined(primaryText, "maxhud.door_title", 0, 0, ColorAlpha(primaryColor, 255 * fadeMul), TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM, 1, ColorAlpha(color_black, 200 * fadeMul))

			local y = 10
			if showNametag then
				if wanted or arrested then
					draw.SimpleTextOutlined(ply:Nick(), "maxhud.door_sub", 0, y, ColorAlpha(teamColor, 255 * fadeMul), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP, 1, ColorAlpha(color_black, 200 * fadeMul))
					y = y + 65
				end

				local job = ply:getDarkRPVar("job") or team.GetName(ply:Team())
				draw.SimpleTextOutlined(job, "maxhud.door_sub", 0, y, ColorAlpha(Config.colors.text, 220 * fadeMul), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP, 1, ColorAlpha(color_black, 200 * fadeMul))
			end
		cam.End3D2D()
	end
end)
