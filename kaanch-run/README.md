# Kaanch Run

A glass-breaking run through the glass traditions of the world, made with Godot 4.3 (separate from the web game, which stays as it is).

You fly forward through halls of glass. Tap to throw marbles and break the glass before you reach it. Running into glass costs marbles; when they run out, the run ends.

## Modes

- **Level 1 · First Light** — a 75-second run through a stained-glass cathedral, ending in a rose-window finale. Finishing it gives up to three stars (for accuracy and no crashes) and unlocks Endless.
- **Endless** — rooms of 200 m that change world as you go: Cathedral, Venice (Murano), Lanterns, Mosaic and Sheesh Mahal, each with its own music. Doors between rooms are checkpoints.
- **Calm** — slower, with no penalties and unlimited marbles.

## Glass

Thin, mid, thick (2 hits), slab (3 hits), mirror (bounces the marble back), tempered (breaks into crumbs), laminated (sags, then falls), frosted (hides what is behind), blast glass (breaks everything near it). The glass moves too: it slides, rises, swings open on a hinge, spins, swings as a pendulum, flies in, shuts in time with the music, dodges the marble, splits in two and falls when its supports break. Some panes only break at a marked weak spot.

**Prism chain:** hitting a prism fires beams that break every pane of its colour. Breaking panes of the same colour in a row builds a colour combo; every five in a row give two marbles.

## Build

Every push that changes this folder builds an APK on GitHub (**Actions → Kaanch Run APK**) and puts it on the [run-latest release](../../../releases/tag/run-latest) as `KaanchRun.apk`. It installs next to Kaanch Ka Kamra.

Run it on a computer: open this folder in Godot 4.3, or `godot --path kaanch-run`.
