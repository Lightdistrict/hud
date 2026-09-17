-- Force-downloads the same bundled font the scoreboard uses so this addon's
-- HUD text looks right even on a client that doesn't have the scoreboard
-- addon (redundant, harmless duplicate if they do -- resource.AddFile just
-- no-ops for a file already queued).
resource.AddFile('resource/fonts/montserrat-regular.ttf')
