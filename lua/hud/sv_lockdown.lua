-- DarkRP's own lockdown flow (modules/police/sv_commands.lua, a "DON'T
-- TOUCH" file) broadcasts through DarkRP.notifyAll, which checks a real,
-- documented "onNotify" hook and skips its own broadcast entirely if any
-- hook returns true -- suppressed here for the lockdown phrase
-- specifically, so every other DarkRP notification (paydays, purchases,
-- etc) is unaffected. The pulsing on-screen lockdown text is a separate
-- HUD panel ("DarkRP_LockdownHUD"), suppressed client-side via
-- HUDShouldDraw instead (see cl_hud.lua). The lockdown sound itself is a
-- direct ConCommand play, not part of either -- it's untouched and keeps
-- playing normally.
--
-- The chat "tip" message (DarkRP.printMessageAll with HUD_PRINTTALK) has
-- no equivalent hook -- it's a raw PrintMessage call with nothing to
-- intercept, so it can't be suppressed without editing that DON'T TOUCH
-- file directly.

hook.Add("onNotify", "maxhud_suppress_lockdown_notify", function(players, msgtype, len, msg)
	if msg == DarkRP.getPhrase("lockdown_started") or msg == DarkRP.getPhrase("lockdown_ended") then
		return true
	end
end)
