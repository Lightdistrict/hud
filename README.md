# MAX HUD

A minimalistic, from-scratch DarkRP HUD replacing DarkRP's own built-in HUD panel.

## Install

Drop this whole repo into `garrysmod/addons/hud/` and restart. Works standalone; the leveling pill only appears if the `levelsystem` addon is also installed.

## What it shows

One shared translucent strip spans the full screen width; individual rounded chips (with a small gap between each) sit on top of it. Every chip's icon sits on its own lighter rounded badge, drawn pure white; chip text is a slightly muted off-white.

**Left cluster:** job name, Health, Armor, Hunger, and (only if `levelsystem` is installed) a leveling/XP progress bar showing level, prestige, and % to next level.

**Right cluster:** hourly salary, total money, current time, today's date, and a static "MAX" (cyan)/"Servers" (white) brand chip. Time and date are read with `os.date()` client-side, so they always match that specific player's own system clock, not the server's.

## Icons

Uses `icon_health`, `icon_armor`, `icon_hunger`, `icon_leveling`, `icon_money`, and `icon_clock2` from the "MAX Assets" workshop addon, under `materials/hud/icons/` (`Config.iconFolder` in `lua/hud/sh_config.lua`). Two more, per spec: the job chip uses `icon_salary.png` and the hourly-salary chip uses `icon_dollar.png` -- if that turns out to be backwards once you see it in-game, swap the two filenames in `Config.icons` (`job` and `hourlySalary` keys).

## Hunger

The hunger chip reads DarkRP's own real "Energy" DarkRP var (`ply:getDarkRPVar("Energy")`) -- decayed, starvation-damaged, and restored by eating food, all handled by DarkRP's built-in `hungermod` module (see the `darkrp_modification` config for enabling it and the Chef job). This addon doesn't track hunger itself; there's nothing to configure here.

## Configuration

Everything tunable lives in `lua/hud/sh_config.lua`: colors, icon filenames/folder, armor's display max (100 by default, matching vanilla HL2's cap), and the pay-interval fallback used to compute the hourly salary figure (reads DarkRP's real `GAMEMODE.Config.paydelay` when available).

## Notes

- DarkRP's own HUD is fully replaced by hiding its `"DarkRP_LocalPlayerHUD"` panel via the real `HUDShouldDraw` hook -- verified against DarkRP's actual gamemode source, not guessed. The default ammo counter is left alone.
- Salary/money read DarkRP's real `getDarkRPVar("salary"/"money")` and format with `DarkRP.formatMoney()`, so the currency symbol always matches your server's DarkRP config.
- Uses the same bundled Montserrat font as the scoreboard addon for visual consistency.
