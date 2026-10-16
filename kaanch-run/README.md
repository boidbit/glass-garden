# Kaanch Run

A glass-breaking run through the glass traditions of the world, made with Godot 4.3 (separate from the web game, which stays as it is).

You fly forward through halls of glass. Tap to throw heavy iron balls and break the glass before you reach it. No glass takes more than two balls. Running into glass costs balls; when they run out, the run ends. The only sounds are the balls, the glass and the music.

## Modes

- **Level 1 · First Light** — a 90-second run through a stained-glass cathedral: the crypt tunnel, the great hall, out through the roof into the sky, and back in for a rose-window finale. Finishing it gives up to three stars (for accuracy and no crashes) and unlocks Endless.
- **Endless** — 50 rooms made by hand, 200 m each, ten in each world: Cathedral, Venice (Murano), Lanterns, Mosaic and Sheesh Mahal, each with its own music, the tenth room of each with a great wheel of glass. No room comes twice in a run; after all 50 (10 km) they come again as a remix, faster and the other way round. Doors between rooms are checkpoints. The rooms are written in `tools/rooms.py`, which checks them and writes `scripts/rooms.gd`.
- **Calm** — slower, with no penalties and unlimited marbles.

## The way

Far off, each world has its own skyline (spires, bell towers and domes, pagodas, minarets, onion domes) behind layers of haze, and specks of dust drift past everywhere.


Each world changes shape as you go: narrow round **tunnels**, wide **great halls** with bonus glass on racks at the sides, and the open **sky**, where the glass floats and falls from above, and little islands below carry bonus glass to break from the air. Bonus glass is never in your way; break all of an island or a rack for three marbles.

## Glass

Plain glass that looks like glass: thin (tinkles), mid, thick and slab (2 hits each), which you can see are thick, glass bricks that break into heavy chunks with a deep crunch, mirror (bounces the marble back), tempered (breaks into crumbs), laminated (sags, then falls), frosted (hides what is behind), blast glass (breaks everything near it). The glass moves too: it drops from the sky, slides, rises, swings open on a hinge, spins, swings as a pendulum, flies in, shuts in time with the music, dodges the marble, splits in two and falls when its supports break. Some panes only break at a marked weak spot.

More glass: giant cubes of glass two metres deep, blocks that slide or come crashing down from above, long pendulum blades, scissor blades, round saw blades, diagonal blades and lines of turning blades; doors of glass that open by themselves (or stick, or slide shut), shutters, revolving and button doors; chessboards of thick and thin squares, falling tiles, a turning grid, tiles that slide out of the walls, a pane with a hole in it, rings of glass to fly through, half-thin half-thick panes, dominoes, and brick walls that come down in one. Each room of the endless run is built round one of these, and in some rooms the whole room turns about you.

**Prism chain:** only the prism's own glass is tinted. Hitting a prism fires beams that break every pane of its colour. Breaking panes of the same colour in a row builds a colour combo; every five in a row give two marbles.

## Build

Every push that changes this folder builds an APK on GitHub (**Actions → Kaanch Run APK**) and puts it on the [run-latest release](../../../releases/tag/run-latest) as `KaanchRun.apk`. It installs next to Kaanch Ka Kamra.

Run it on a computer: open this folder in Godot 4.3, or `godot --path kaanch-run`.
