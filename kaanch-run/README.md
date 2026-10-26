# Glass Run

A glass-breaking run through the glass traditions of the world, made with Godot (4.7.2 for the Play Store build) (separate from the web game, which stays as it is).

You fly forward through halls of glass. Tap to throw heavy iron balls and break the glass before you reach it. No glass takes more than two balls. Running into glass costs balls; when they run out, the run ends. The only sounds are the balls, the glass and calm music, and nothing is written on the screen while you play but the number of balls, which turns red and beats when you are running low. Crystals give balls: hit them where they stand at the sides, float on islands below the sky, or hang in the way.

## Modes

- **Level 1 · First Light** — a 90-second run through a stained-glass cathedral: the crypt tunnel, the great hall, out through the roof into the sky, and back in for a rose-window finale. Finishing it gives up to three stars (for accuracy and no crashes) and unlocks Endless.
- **Endless** — 50 rooms made by hand, 200 m each; a checkpoint door comes every three rooms (600 m, a minute or more), and through each door is a new world: Cathedral, Venice (Murano), Lanterns, Mosaic and Sheesh Mahal, each with its own music. Breaking the door is a moment of its own: time slows, the light flares, you are pushed through, and you get five balls. Every tenth room ends with a great wheel of glass. No room comes twice in a run; after all 50 (10 km) they come again as a remix, faster and the other way round. The rooms are written in `tools/rooms.py`, which checks them and writes `scripts/rooms.gd`.
- **Calm** — slower, with no penalties and unlimited marbles.

## The way

The way is wide. No glass floats: every pane sits in a metal frame and stands in a slot in the floor, on posts, hangs on a rod from a rail overhead, or turns on an axle held from above. Rooms differ in their shape, not just their light: platforms with steps along the walls, square pillars, great blocks hanging from the roof, channels in the floor, and rooms open to the sky with a colonnade either side and beams overhead. Crystals stand on stands.

Far off, each world has its own skyline (spires, bell towers and domes, pagodas, minarets, onion domes) behind layers of haze, and specks of dust drift past everywhere.


Each world changes shape as you go: narrow round **tunnels**, wide **great halls** with crystals on stands at the sides, and the open **sky**, where the glass floats and falls from above and crystals sit on little islands below.

## Glass

All the glass is one colour of glass: thin (tinkles), mid, thick and slab (2 hits each), which you can see are thick, glass bricks that break into heavy chunks with a deep crunch, mirror (bounces the marble back), tempered (breaks into crumbs), laminated (sags, then falls), frosted (hides what is behind), blast glass (breaks everything near it). The glass moves too: it drops from the sky, slides, rises, swings open on a hinge, spins, swings as a pendulum, flies in, shuts in time with the music, dodges the marble, splits in two and falls when its supports break. Some panes only break at a marked weak spot.

More glass: giant cubes of glass two metres deep, blocks that slide or come crashing down from above, long pendulum blades, scissor blades, round saw blades, diagonal blades and lines of turning blades; doors of glass that open by themselves (or stick, or slide shut), shutters, revolving and button doors; chessboards of thick and thin squares, falling tiles, a turning grid, tiles that slide out of the walls, a pane with a hole in it, rings of glass to fly through, half-thin half-thick panes, dominoes, and brick walls that come down in one. Each room of the endless run is built round one of these, and in some rooms the whole room turns about you.

Big panes break where the ball strikes: a hole opens and the rest stays, cracked, so you aim at the place you will pass through. Glass is one misty blue-grey with fine scratches, and comes out of the haze close in front of you. Each stretch starts slow past its checkpoint door and gets faster towards the next. A ring round the ball count shows how near the next extra ball per throw is; balls in circles down the left show how many each throw sends.

The ball is a heavy ball of steel: it leaves your hand slower than before and drops in a firm curve (the throw is lifted for the drop, so it lands where you tap). One ball, one glass: the first pane it reaches takes it. If the pane breaks, the ball stops there and falls through the hole; if the pane holds, it knocks back off it with a dull thud. It can never go on to break a second pane behind the first, and the two or three balls of one throw strike only the one wall of glass between them. Against the side walls it glances off heavily, with a knock and a small shake; a steel grille, posts and the pillars stop it. Every pane hit is counted once; `--screen=balltest` runs the checks (one pane, panes close behind each other, thick glass, the wall, the grille, a miss, many shots, three balls).

## Around you

None of this can hurt you. Pillars come up out of the floor at the sides as you come, so the room builds itself in front of you; in the great halls the roof swings open to the sky, and a great glass chandelier comes down and smashes on the floor beside you; out in the open sky, mountains of glass crystal float on rocks, turning slowly.

Glass that turns about the middle of the way runs in a steel ring held from the walls, so nothing stands where you pass; other turning glass turns on axles at the sides. Where you have to get through, only one piece of glass is in your way: falling blocks come down beside you, only the last in front of you.

Now and then a crystal of power stands in place of a crystal of balls: gold slows time, green sends three balls with every throw, orange makes the ball hot iron that breaks any glass at one hit. A ring at the bottom right shows which, and how long it lasts.

## Build

Every push that changes this folder builds an APK on GitHub (**Actions → Glass Run APK**) and puts it on the [run-latest release](../../../releases/tag/run-latest) as `KaanchRun.apk`. It installs next to Kaanch Ka Kamra.

Run it on a computer: open this folder in Godot 4.3, or `godot --path kaanch-run`.
