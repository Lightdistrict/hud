# MAX HUD

A minimalistic, from-scratch DarkRP HUD replacing DarkRP's own built-in HUD panel.

## Install

Drop this whole repo into `garrysmod/addons/hud/` and restart. Works standalone; the leveling pill only appears if the `levelsystem` addon is also installed.

## What it shows

**Top-left:** one continuous flat strip, flush to the corner -- Health, Armor, and Hunger segments (red/blue/orange), each an icon block butted directly against its fill bar, no gaps between segments.

**Top-right:** one continuous flat strip, flush to the corner, with a thin divider between each item, left to right: hourly salary, total money, level/prestige/XP% (only if `levelsystem` is installed), current time, and today's date. Time and date are read with `os.date()` client-side, so they always match that specific player's own system clock, not the server's.

## Icons

Uses `icon_health`, `icon_armor`, `icon_hunger`, `icon_salary`, `icon_money`, `icon_leveling`, and `icon_clock2` from the "MAX Assets" workshop addon. If those materials live in a subfolder under `materials/` in that addon (rather than the root), set `Config.iconFolder` in `lua/hud/sh_config.lua` to match (e.g. `"hud/"`) instead of editing every filename.

## Hunger

Nothing else on the server tracks hunger, so this addon owns a minimal version of it: starts full on spawn, decays passively over time (`Config.hunger.decayPerTick` / `tickInterval` in `sh_config.lua`), and is in-memory only (not persisted). `MaxHUD.AddHunger(ply, amount)` is exposed server-side for a food item/entity to hook into later, if you want eating to actually restore it.

## Configuration

Everything tunable lives in `lua/hud/sh_config.lua`: colors, icon filenames/folder, hunger decay rate, armor's display max (100 by default, matching vanilla HL2's cap), and the pay-interval fallback used to compute the hourly salary figure (reads DarkRP's real `GAMEMODE.Config.paydelay` when available).

## Notes

- DarkRP's own HUD is fully replaced by hiding its `"DarkRP_LocalPlayerHUD"` panel via the real `HUDShouldDraw` hook -- verified against DarkRP's actual gamemode source, not guessed. The default ammo counter is left alone.
- Salary/money read DarkRP's real `getDarkRPVar("salary"/"money")` and format with `DarkRP.formatMoney()`, so the currency symbol always matches your server's DarkRP config.
- Uses the same bundled Montserrat font as the scoreboard addon for visual consistency.
