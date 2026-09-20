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

-- Reuses the exact same font (and cam.Start3D2D scale) as cl_doorinfo.lua's
-- door price text -- "maxhud.door_title" -- for both name and job, so
-- overhead tags read as the same UI system as the on-door text. Name/job
-- always render the same way regardless of wanted/arrested status; the
-- status line is a separate, additional line above them rather than
-- something that changes their own look.

local NAMETAG_RANGE = 700
local STATUS_RANGE = 2000
local SCALE = 0.05

--[[
- @return number -- t interpolated between two colors (0..1)
]]
local function lerpColor(t, a, b)
	return Color(Lerp(t, a.r, b.r), Lerp(t, a.g, b.g), Lerp(t, a.b, b.b))
end

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

		cam.Start3D2D(pos, billboardAng, SCALE)
			-- Name always sits at the same anchor (y=0, bottom-aligned) no
			-- matter what -- wanted/arrested never move or restyle it.
			if showNametag then
				draw.SimpleTextOutlined(ply:Nick(), "maxhud.door_title", 0, 0, ColorAlpha(teamColor, 255 * fadeMul), TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM, 1, ColorAlpha(color_black, 200 * fadeMul))

				-- Same font/size/weight as the name, just a different color,
				-- immediately below it.
				local job = ply:getDarkRPVar("job") or team.GetName(ply:Team())
				draw.SimpleTextOutlined(job, "maxhud.door_title", 0, 10, ColorAlpha(Config.colors.text, 220 * fadeMul), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP, 1, ColorAlpha(color_black, 200 * fadeMul))
			end

			-- Status line: a separate line above the name, never altering
			-- the name/job's own position or style. Wanted pulses between
			-- the same two reds as the lockdown alert (cl_hud.lua); Arrested
			-- is the same red family but held static, not pulsing.
			if wanted then
				local pulse = (math.sin(RealTime() * 6) + 1) / 2
				local glowColor = lerpColor(pulse, Config.colors.lockdownGlowLow, Config.colors.lockdownGlowHigh)
				draw.SimpleTextOutlined("WANTED", "maxhud.door_title", 0, -95, ColorAlpha(glowColor, 255 * fadeMul), TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM, 1, ColorAlpha(color_black, 200 * fadeMul))
			elseif arrested then
				draw.SimpleTextOutlined("ARRESTED", "maxhud.door_title", 0, -95, ColorAlpha(Config.colors.lockdownGlowLow, 255 * fadeMul), TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM, 1, ColorAlpha(color_black, 200 * fadeMul))
			end
		cam.End3D2D()
	end
end)
