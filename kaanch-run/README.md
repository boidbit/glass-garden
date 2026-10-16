# Kaanch Run

A glass-breaking run through the glass traditions of the world, made with Godot 4.3 (separate from the web game, which stays as it is).

You fly forward through halls of glass. Tap to throw marbles and break the glass before you reach it. Running into glass costs marbles; when they run out, the run ends.

## Modes

- **Level 1 · First Light** — a 90-second run through a stained-glass cathedral: the crypt tunnel, the great hall, out through the roof into the sky, and back in for a rose-window finale. Finishing it gives up to three stars (for accuracy and no crashes) and unlocks Endless.
- **Endless** — 50 rooms made by hand, 200 m each, ten in each world: Cathedral, Venice (Murano), Lanterns, Mosaic and Sheesh Mahal, each with its own music, the tenth room of each with a great wheel of glass. No room comes twice in a run; after all 50 (10 km) they come again as a remix, faster and the other way round. Doors between rooms are checkpoints. The rooms are written in `tools/rooms.py`, which checks them and writes `scripts/rooms.gd`.
- **Calm** — slower, with no penalties and unlimited marbles.

## The way

Far off, each world has its own skyline (spires, bell towers and domes, pagodas, minarets, onion domes) behind layers of haze, and specks of dust drift past everywhere.


Each world changes shape as you go: narrow round **tunnels**, wide **great halls** with bonus glass on racks at the sides, and the open **sky**, where the glass floats and falls from above, and little islands below carry bonus glass to break from the air. Bonus glass is never in your way; break all of an island or a rack for three marbles.

## Glass

Plain glass that looks like glass: thin (tinkles), mid, thick (2 hits) and slab (3 hits), which you can see are thick, glass bricks that break into heavy chunks with a deep crunch, mirror (bounces the marble back), tempered (breaks into crumbs), laminated (sags, then falls), frosted (hides what is behind), blast glass (breaks everything near it). The glass moves too: it drops from the sky, slides, rises, swings open on a hinge, spins, swings as a pendulum, flies in, shuts in time with the music, dodges the marble, splits in two and falls when its supports break. Some panes only break at a marked weak spot.

**Prism chain:** only the prism's own glass is tinted. Hitting a prism fires beams that break every pane of its colour. Breaking panes of the same colour in a row builds a colour combo; every five in a row give two marbles.

## Build

Every push that changes this folder builds an APK on GitHub (**Actions → Kaanch Run APK**) and puts it on the [run-latest release](../../../releases/tag/run-latest) as `KaanchRun.apk`. It installs next to Kaanch Ka Kamra.

Run it on a computer: open this folder in Godot 4.3, or `godot --path kaanch-run`.
