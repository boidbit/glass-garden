# Glass Rush

An endless flight, fast, through the glass worlds of Glass Run. It is its own app (`com.boidbit.glassrush`), made with Godot 4.7, and it is held upright.

## How it plays

- **Drag to steer.** The ship follows your finger anywhere on the screen, side to side and up and down, and leans into the turn.
- **Thin glass you smash through** (clear and light): +10, and it bursts round you.
- **Thick glass you must miss** (darker, deeper blue): flying into it costs a shield. You have three; they show as diamonds at the top left. After a hit the ship blinks and nothing can hit it for a moment. With no shields left the ship breaks up and the run ends.
- **Near miss:** pass a wall close to thick glass without touching it: +25, more for several in a row (up to five times).
- **Crystals** float in lines between the walls. Five fill the bar at the bottom and give a **boost**: faster, and thick glass bursts instead of hurting you. A green crystal mends a shield.
- **It never ends and keeps getting harder:** the speed climbs from about 100 to over 230 km/h, the walls come closer together, the open cells get fewer, and new kinds of wall come in as you go (three at first, all eight by about 3.5 km): a three-by-three grid, a wall of thin glass to smash, tall bars, a wall with a square hole, a sliding sheet, doors closing from above and below, a turning blade, and two blades in a cross.
- The way changes shape every 240 m (corridor, tunnel, great hall, open sky) and the world every 1.44 km (neon city, ocean, aurora, dunes, ice), each with its own music.

## Shared with Glass Run

The worlds, the glass, the sounds and the little effects are Glass Run's own files (`scripts/worlds.gd`, `glass.gd`, `sfx.gd`, `fx.gd` and the fonts), copied here by `tools/sync_shared.sh`, because a Godot project only sees its own folder. Never edit the copies: change them in `glass-run/` and run the script. The APK workflow runs it too, so a build always has the newest.

Glass Rush's own files are `scripts/rush.gd` (the flight, the walls, the rules) and `scripts/rush_hud.gd` (the screens).

## Build

Every push to main that changes this folder (or the shared Glass Run files) builds an APK (**Actions → Glass Rush APK**). A short flight by the bot with no screen comes first, so a broken script fails the build. The APK goes on the [rush-latest release](../../../releases/tag/rush-latest) as `GlassRush.apk`. It installs next to Glass Run.

Run it on a computer: `godot --path glass-rush`. A bot can fly it: `godot --path glass-rush -- --auto` (also `--seed=n`, `--quit-at=metres`, `--shots=m,m --shot-dir=dir/` for pictures).
