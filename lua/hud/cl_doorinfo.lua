-- 3D2D door info: replaces DarkRP's own crosshair-centered door text
-- (meta:drawOwnableInfo, gamemode/modules/doorsystem/cl_doors.lua) with
-- text drawn directly on the door itself, matching the rest of the MAX UI
-- (Montserrat, accent color, dark outline). Suppressing the default text
-- is done the documented way -- HUDDrawDoorData returning true, exactly
-- what meta:drawOwnableInfo itself checks before drawing.
--
-- All entity checks below (isDoor/isKeysOwnable/getKeysTitle/getDoorOwner/
-- getKeysCoOwners/isKeysAllowedToOwn/getKeysDoorGroup/getKeysDoorTeams) are
-- real DarkRP core meta functions (gamemode/modules/doorsystem/sh_doors.lua),
-- not guessed.

local Config = MaxHUD.Config

surface.CreateFont("maxhud.door_title", { font = "Montserrat", size = 90, weight = 800, antialias = true })
surface.CreateFont("maxhud.door_sub", { font = "Montserrat", size = 60, weight = 600, antialias = true })

local DRAW_DISTANCE = 250

local function isOwnableDoor(door)
	return IsValid(door) and door.isDoor and door.isKeysOwnable and door:isDoor() and door:isKeysOwnable() and not door:getKeysNonOwnable()
end

local function getCoowners(door, owner)
	local coowners = {}
	for _, ply in ipairs(player.GetAll()) do
		if ply ~= owner and door:isKeysOwnedBy(ply) then
			table.insert(coowners, ply)
		end
	end
	return coowners
end

local function getAllowedGroupNames(door)
	local names = {}

	local group = door:getKeysDoorGroup()
	if group then
		table.insert(names, group)
	else
		for teamID, allowed in pairs(door:getKeysDoorTeams() or {}) do
			if allowed and team.GetName(teamID) then
				table.insert(names, team.GetName(teamID))
			end
		end
	end

	return names
end

-- Suppresses DarkRP's own crosshair door text (see file header) so only
-- our on-door version shows.
hook.Add("HUDDrawDoorData", "maxhud_hide_default_doorinfo", function(door)
	if isOwnableDoor(door) then return true end
end)

local doorAnchors = {}

--[[
- Computes (and caches) two local anchors for a door's floating text, one
- sitting just inside each physical face -- WorldSpaceAABB turned out to
- return degenerate bounds on some door collision models (nothing rendered
- at all), so this stays on the local-OBB approach.
-
- A single shared anchor (just flipping the angle to face whichever side
- the player is on) doesn't work for drawing both sides at once: that
- point sits right at one face, so from the opposite side the entire
- door's thickness lies between the camera and the text, and the door's
- own solid geometry occludes it. Each face needs its own point placed
- near *that* face instead.
-
- @return table -- { front = {pos=, ang=}, back = {pos=, ang=} }, all local
]]
local function getAnchor(door)
	local anchor = doorAnchors[door]
	if anchor then return anchor end

	-- The collision hull (what's actually solid) rather than the render
	-- bounding box: some door models bake hinges/frame trim into the
	-- render mesh, which inflates OBBMins/OBBMaxs well past the actual
	-- door leaf and threw the thickness estimate off per-model -- text
	-- ended up clipping into the door on some, floating far off it on
	-- others. The collision bounds track the real physical door instead.
	local mins, maxs = door:GetCollisionBounds()
	local dimens = maxs - mins
	local center = (mins + maxs) / 2

	local thinnest, axis = nil, 1
	for i = 1, 3 do
		if not thinnest or dimens[i] <= thinnest then
			thinnest = dimens[i]
			axis = i
		end
	end

	local norm = Vector()
	norm[axis] = 1
	local lang = Angle(0, norm:Angle().y + 90, 90)

	local heightOffset = door:GetClass() == "prop_door_rotating" and 25 or 15
	local base = Vector(center.x, center.y, center.z) + Vector(0, 0, heightOffset)
	-- Half the real thickness, minus a small fixed clearance so the text
	-- sits just proud of the surface instead of clipping into it -- but
	-- never less than 1 unit out, so very thin doors don't end up with the
	-- text buried at the center plane.
	local faceOffset = math.max((thinnest / 2) - 0.75, 1)

	local backAng = Angle(lang.p, lang.y, lang.r)
	backAng:RotateAroundAxis(backAng:Right(), 180)

	anchor = {
		front = { pos = base + lang:Up() * faceOffset, ang = lang },
		back = { pos = base - lang:Up() * faceOffset, ang = backAng },
	}
	doorAnchors[door] = anchor
	return anchor
end

hook.Add("PostDrawTranslucentRenderables", "maxhud_draw_doorinfo", function()
	local lp = LocalPlayer()
	if not IsValid(lp) then return end

	for _, door in ipairs(ents.GetAll()) do
		if not isOwnableDoor(door) then continue end
		local dist = door:GetPos():Distance(lp:GetShootPos())
		if dist > DRAW_DISTANCE then continue end

		local anchor = getAnchor(door)
		local fadeMul = math.Clamp(1 - (dist / DRAW_DISTANCE), 0, 1)

		local owner = door:getDoorOwner()
		local groups = getAllowedGroupNames(door)

		local function drawFace()
			if IsValid(owner) then
				local teamColor = team.GetColor(owner:Team())
				draw.SimpleTextOutlined(owner:Nick(), "maxhud.door_title", 0, 0, ColorAlpha(teamColor, 255 * fadeMul), TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM, 1, ColorAlpha(color_black, 200 * fadeMul))

				local title = door:getKeysTitle()
				if title and title ~= "" then
					draw.SimpleTextOutlined(title, "maxhud.door_sub", 0, 10, ColorAlpha(Config.colors.text, 255 * fadeMul), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP, 1, ColorAlpha(color_black, 200 * fadeMul))
				end

				local coowners = getCoowners(door, owner)
				if #coowners > 0 then
					local names = {}
					for _, ply in ipairs(coowners) do table.insert(names, ply:Nick()) end
					draw.SimpleTextOutlined(table.concat(names, ", "), "maxhud.door_sub", 0, 90, ColorAlpha(Config.colors.text, 200 * fadeMul), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP, 1, ColorAlpha(color_black, 200 * fadeMul))
				end
			elseif #groups > 0 then
				draw.SimpleTextOutlined(table.concat(groups, ", "), "maxhud.door_title", 0, 0, ColorAlpha(Config.colors.accent, 255 * fadeMul), TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM, 1, ColorAlpha(color_black, 200 * fadeMul))
			else
				draw.SimpleTextOutlined(DarkRP.formatMoney(GAMEMODE.Config.doorcost), "maxhud.door_title", 0, 0, ColorAlpha(Config.colors.accent, 255 * fadeMul), TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM, 1, ColorAlpha(color_black, 200 * fadeMul))
				draw.SimpleTextOutlined("Press F2 to purchase", "maxhud.door_sub", 0, 10, ColorAlpha(Config.colors.text, 255 * fadeMul), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP, 1, ColorAlpha(color_black, 200 * fadeMul))
			end
		end

		-- Drawn on both faces of the door -- each at its own point near that
		-- physical face (see getAnchor) so neither is occluded by the
		-- door's own thickness from the other side.
		cam.Start3D2D(door:LocalToWorld(anchor.front.pos), door:LocalToWorldAngles(anchor.front.ang), 0.05)
			drawFace()
		cam.End3D2D()

		cam.Start3D2D(door:LocalToWorld(anchor.back.pos), door:LocalToWorldAngles(anchor.back.ang), 0.05)
			drawFace()
		cam.End3D2D()
	end
end)

hook.Add("EntityRemoved", "maxhud_doorinfo_cleanup", function(ent)
	doorAnchors[ent] = nil
end)
