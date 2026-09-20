-- F2 door menu, replacing the old default DarkRP-adjacent "Door options"
-- popup with something matching the rest of the MAX UI (dark panels,
-- accent color, Montserrat, light 1px outline -- same recipe as the
-- Skills tab). All actions are the real DarkRP chat commands
-- (gamemode/modules/doorsystem/sv_doors.lua) run silently via the "say"
-- concommand -- DarkRP's own chat handler swallows a recognized command
-- and never echoes it to chat (modules/chat/sv_chat.lua returns "" once
-- it dispatches), so this never spams anyone's chat.
--
-- "Disallow/Allow ownership" and "Edit door group" are gated the same way
-- DarkRP's own crosshair text gates them (cl_doors.lua): a CAMI check for
-- the "DarkRP_ChangeDoorSettings" privilege, polled on a timer since
-- there's no "permission changed" hook.

local Config = MaxHUD.Config

-- Some other installed addon (source not found in any repo this project
-- has access to -- not DarkRP core, confirmed against the actual gamemode
-- source) still pops its own plain blue "Door options" DFrame on F2
-- alongside this one. Since its source can't be edited directly, this
-- wraps vgui.Create itself: every time a DFrame is actually created, its
-- own SetTitle is patched (instance-level, not the shared class table --
-- vgui.GetControlTable("DFrame") isn't reliably populated yet this early
-- in client load, which is what threw "attempt to index a nil value"
-- here before) to auto-remove it the instant its title is set to
-- exactly "Door options", which is how vgui panels normally get their
-- title assigned right after creation. Doesn't touch our own menu (a
-- DPanel with a hand-drawn title, never calls DFrame:SetTitle).
do
	local baseVguiCreate = vgui.Create
	function vgui.Create(class, ...)
		local panel = baseVguiCreate(class, ...)
		if class == "DFrame" and IsValid(panel) then
			local baseSetTitle = panel.SetTitle
			panel.SetTitle = function(self, title, ...)
				baseSetTitle(self, title, ...)
				if title == "Door options" then
					self:Remove()
				end
			end
		end
		return panel
	end
end

local COLOR_BG = Color(12, 12, 15, 245)
local COLOR_PANEL = Color(0, 0, 0, 225)
local COLOR_PANEL_HOVER = Color(0, 0, 0, 255)
local COLOR_OUTLINE = Color(255, 255, 255, 25)
local COLOR_CLOSE = Color(200, 60, 60)
local COLOR_CLOSE_HOVER = Color(230, 80, 80)

local FONT_TITLE = MaxHUD.font("doormenu_title", { font = "Montserrat", size = 18, weight = 400, antialias = true })
local FONT_BUTTON = MaxHUD.font("doormenu_button", { font = "Montserrat", size = 16, weight = 400, antialias = true })

local MENU_RANGE = 200
local MENU_W = 300
local BTN_H = 44
local BTN_GAP = 8
local PAD = 14

local changeDoorAccess = false
local function updateDoorAccess()
	if not CAMI then return end
	CAMI.PlayerHasAccess(LocalPlayer(), "DarkRP_ChangeDoorSettings", function(has) changeDoorAccess = has end)
end
hook.Add("InitPostEntity", "maxhud_doormenu_privs", function()
	updateDoorAccess()
	timer.Create("maxhud_doormenu_privs", 2, 0, updateDoorAccess)
end)

--[[
- Draws a rounded panel with a faint 1px light outline -- same recipe as
- the Skills tab (levelsystem/cl_skills_tab.lua) so this reads as part of
- the same UI family.
]]
local function drawPanel(w, h, fillColor, radius)
	radius = radius or 8
	draw.RoundedBox(radius, 0, 0, w, h, COLOR_OUTLINE)
	draw.RoundedBox(radius, 1, 1, w - 2, h - 2, fillColor)
end

local mainFrame, groupFrame

local function closeAll()
	if IsValid(mainFrame) then mainFrame:Remove() end
	if IsValid(groupFrame) then groupFrame:Remove() end
	mainFrame, groupFrame = nil, nil
end

local function sendDoorCommand(cmd)
	RunConsoleCommand("say", "/" .. cmd)
end

--[[
- Adds one styled option button to `parent`, stacked below whatever's
- already been added (tracked via parent.nextY).
]]
local function addButton(parent, label, onClick)
	local y = parent.nextY or 0
	parent.nextY = y + BTN_H + BTN_GAP

	local btn = vgui.Create("DButton", parent)
	btn:SetText("")
	btn:SetPos(PAD, y)
	btn:SetSize(MENU_W - PAD * 2, BTN_H)
	btn.Paint = function(self, w, h)
		drawPanel(w, h, self:IsHovered() and COLOR_PANEL_HOVER or COLOR_PANEL, 6)
		local textColor = self:IsHovered() and Config.colors.accent or Config.colors.text
		draw.SimpleText(label, FONT_BUTTON, w / 2, h / 2, textColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end
	btn.DoClick = function()
		surface.PlaySound("buttons/button15.wav")
		onClick()
	end
	return btn
end

--[[
- The "Edit door group" submenu -- lists every real door group
- (RPExtraTeamDoors, gamemode/modules/base/sh_createitems.lua) plus a
- "None" entry to clear it, next to the main frame.
]]
local function openGroupMenu(door)
	if IsValid(groupFrame) then groupFrame:Remove() end

	local names = { }
	for name in pairs(RPExtraTeamDoors or {}) do
		table.insert(names, name)
	end
	table.sort(names)

	local rowCount = #names + 1
	local h = PAD * 2 + rowCount * (BTN_H + BTN_GAP) - BTN_GAP

	groupFrame = vgui.Create("DPanel")
	groupFrame:SetSize(MENU_W, h)
	groupFrame:SetPos(mainFrame:GetX() + mainFrame:GetWide() + 12, mainFrame:GetY())
	groupFrame:MakePopup()
	groupFrame:SetKeyboardInputEnabled(false)
	groupFrame.Paint = function(self, w, h) drawPanel(w, h, COLOR_BG, 10) end
	groupFrame.nextY = PAD

	addButton(groupFrame, "None", function()
		sendDoorCommand("togglegroupownable ")
		closeAll()
	end)
	for _, name in ipairs(names) do
		addButton(groupFrame, name, function()
			sendDoorCommand("togglegroupownable " .. name)
			closeAll()
		end)
	end
end

--[[
- A small submenu with one free-text field + confirm button, next to the
- main frame -- used for "Set Door Title". Reuses the `groupFrame` slot
- since only one submenu is ever open at a time.
-
- The text field is a plain, un-skinned DTextEntry nested inside its own
- background DPanel (drawn as a sibling, not by overriding the entry's
- own Paint) -- an earlier version replaced DTextEntry:Paint entirely to
- draw our background inline, which broke clicking into it to place the
- caret/type. Docking it to fill a separate background panel keeps the
- entry itself completely stock so its normal click/focus/typing
- behavior is untouched.
-
- @param string title
- @param string placeholder
- @param function onConfirm -- function(text) end
]]
local function openTextPrompt(title, placeholder, onConfirm)
	if IsValid(groupFrame) then groupFrame:Remove() end

	local titleH = 24
	local entryH = 24
	local entryY = PAD + titleH
	local buttonY = entryY + entryH + 8
	local h = buttonY + BTN_H + PAD

	groupFrame = vgui.Create("DPanel")
	groupFrame:SetSize(MENU_W, h)
	groupFrame:SetPos(mainFrame:GetX() + mainFrame:GetWide() + 12, mainFrame:GetY())
	groupFrame:MakePopup()
	groupFrame.Paint = function(self, w, h)
		drawPanel(w, h, COLOR_BG, 10)
		draw.SimpleText(title, FONT_BUTTON, PAD, PAD, Config.colors.text, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
	end

	local entryBg = vgui.Create("DPanel", groupFrame)
	entryBg:SetPos(PAD, entryY)
	entryBg:SetSize(MENU_W - PAD * 2, entryH)
	entryBg.Paint = function(self, w, h) drawPanel(w, h, COLOR_PANEL, 4) end

	local entry = vgui.Create("DTextEntry", entryBg)
	entry:Dock(FILL)
	entry:DockMargin(8, 0, 8, 0)
	entry:SetPlaceholderText(placeholder)
	entry:SetPaintBackground(false)
	entry:SetFont(FONT_BUTTON)
	entry:SetTextColor(Config.colors.text)
	entry:RequestFocus()

	local function confirm()
		local text = string.Trim(entry:GetValue())
		if text == "" then return end
		onConfirm(text)
		closeAll()
	end
	entry.OnEnter = confirm

	groupFrame.nextY = buttonY
	addButton(groupFrame, "Confirm", confirm)
end

--[[
- A submenu listing every currently-connected player (excluding
- yourself) -- used for "Add Owner"/"Remove Owner" so you pick a real
- online player instead of typing their name.
-
- @param string title
- @param function onPick -- function(player) end
]]
local function openPlayerListMenu(title, onPick)
	if IsValid(groupFrame) then groupFrame:Remove() end

	local players = {}
	for _, p in ipairs(player.GetAll()) do
		if p ~= LocalPlayer() then table.insert(players, p) end
	end
	table.sort(players, function(a, b) return a:Nick() < b:Nick() end)

	local titleH = 24
	local rowCount = math.max(#players, 1)
	local h = PAD + titleH + rowCount * (BTN_H + BTN_GAP) - BTN_GAP + PAD

	groupFrame = vgui.Create("DPanel")
	groupFrame:SetSize(MENU_W, h)
	groupFrame:SetPos(mainFrame:GetX() + mainFrame:GetWide() + 12, mainFrame:GetY())
	groupFrame:MakePopup()
	groupFrame:SetKeyboardInputEnabled(false)
	groupFrame.Paint = function(self, w, h)
		drawPanel(w, h, COLOR_BG, 10)
		draw.SimpleText(title, FONT_BUTTON, PAD, PAD, Config.colors.text, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
	end
	groupFrame.nextY = PAD + titleH

	if #players == 0 then
		addButton(groupFrame, "No other players online", function() end)
	end
	for _, p in ipairs(players) do
		addButton(groupFrame, p:Nick(), function()
			onPick(p)
			closeAll()
		end)
	end
end

local function buildMenu(door)
	closeAll()

	local owner = door:getDoorOwner()
	local mine = IsValid(owner) and door:isKeysOwnedBy(LocalPlayer())
	local blocked = door:getKeysNonOwnable()

	local showBuySell = mine or (not IsValid(owner) and not blocked)
	local rows = (showBuySell and 1 or 0) + (mine and 3 or 0) + (changeDoorAccess and 2 or 0)
	local h = PAD * 2 + 32 + math.max(rows, 1) * (BTN_H + BTN_GAP) - BTN_GAP

	mainFrame = vgui.Create("DPanel")
	mainFrame.door = door
	mainFrame:SetSize(MENU_W, h)
	mainFrame:SetPos(ScrW() / 2 - MENU_W / 2, ScrH() / 2 - h / 2)
	mainFrame:MakePopup()
	mainFrame:SetKeyboardInputEnabled(false)
	-- Owned by someone else, nothing this player (or an admin) can do here
	-- besides look -- shown so the menu isn't just an empty box.
	local ownedByOther = IsValid(owner) and not mine and owner:Nick()

	mainFrame.Paint = function(self, w, h)
		drawPanel(w, h, COLOR_BG, 10)
		draw.SimpleText("DOOR OPTIONS", FONT_TITLE, PAD, PAD, Config.colors.text, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
		if ownedByOther then
			draw.SimpleText("Owned by " .. ownedByOther, FONT_BUTTON, PAD, 32 + PAD, Config.colors.text, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
		end
	end

	local close = vgui.Create("DButton", mainFrame)
	close:SetText("")
	close:SetSize(22, 22)
	close:SetPos(MENU_W - PAD - 22, PAD)
	close.Paint = function(self, w, h)
		draw.RoundedBox(11, 0, 0, w, h, self:IsHovered() and COLOR_CLOSE_HOVER or COLOR_CLOSE)
		draw.SimpleText("x", FONT_BUTTON, w / 2, h / 2 - 1, Config.colors.text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end
	close.DoClick = closeAll

	mainFrame.nextY = 32 + PAD

	if not IsValid(owner) and not mine then
		if blocked and changeDoorAccess then
			-- Blocked doors don't show a buy option -- only an admin can
			-- re-enable them (below), so there's nothing else to offer here.
		elseif not blocked then
			addButton(mainFrame, "Buy Door (" .. DarkRP.formatMoney(GAMEMODE.Config.doorcost) .. ")", function()
				sendDoorCommand("toggleown")
				closeAll()
			end)
		end
	elseif mine then
		addButton(mainFrame, "Sell Door", function()
			sendDoorCommand("toggleown")
			closeAll()
		end)
	end

	if mine then
		addButton(mainFrame, "Add Owner", function()
			openPlayerListMenu("Add Owner", function(target)
				sendDoorCommand("addowner " .. target:Nick())
			end)
		end)
		addButton(mainFrame, "Remove Owner", function()
			openPlayerListMenu("Remove Owner", function(target)
				sendDoorCommand("removeowner " .. target:Nick())
			end)
		end)
		addButton(mainFrame, "Set Door Title", function()
			openTextPrompt("Set Door Title", "Title", function(text)
				sendDoorCommand("title " .. text)
			end)
		end)
	end

	if changeDoorAccess then
		addButton(mainFrame, blocked and "Allow Ownership" or "Disallow Ownership", function()
			sendDoorCommand("toggleownable")
			closeAll()
		end)
		addButton(mainFrame, "Edit Door Group", function()
			openGroupMenu(door)
		end)
	end
end

-- Edge-detected F2 (GMod's own KEY_F2 constant, unrelated to DarkRP's
-- "gm_showspare1" bind which only toggles the mouse cursor by default --
-- see modules/base/cl_gamemode_functions.lua) so it fires once per press
-- rather than every frame it's held.
local f2WasDown = false
hook.Add("Think", "maxhud_doormenu_f2", function()
	local down = input.IsKeyDown(KEY_F2)
	if down and not f2WasDown then
		if IsValid(mainFrame) then
			closeAll()
		else
			local ply = LocalPlayer()
			local door = ply:GetEyeTrace().Entity
			-- Deliberately not MaxHUD.IsOwnableDoor here -- that one excludes
			-- blocked doors (right, for the on-door price text), but an admin
			-- still needs F2 to work on a blocked door to re-allow it.
			local isDoorClass = IsValid(door) and door.isDoor and door.isKeysOwnable and door:isDoor() and door:isKeysOwnable()
			local inRange = isDoorClass and ply:GetPos():DistToSqr(door:GetPos()) < MENU_RANGE * MENU_RANGE
			if inRange and (not door:getKeysNonOwnable() or changeDoorAccess) then
				buildMenu(door)
			end
		end
	end
	f2WasDown = down

	-- Auto-close if the menu's been open a while and the player's walked
	-- away from the door -- a stale purchase menu floating mid-air while
	-- you're across the map looks broken.
	if IsValid(mainFrame) and mainFrame.door and IsValid(mainFrame.door) then
		if LocalPlayer():GetPos():DistToSqr(mainFrame.door:GetPos()) > (MENU_RANGE * 1.5) ^ 2 then
			closeAll()
		end
	end
end)
