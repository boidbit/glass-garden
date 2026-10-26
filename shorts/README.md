# Glass Run shorts

YouTube Shorts of Glass Run, made on GitHub with nothing installed on your computer: the bot plays the game,
Godot records it in a tall 1080×1920 window, and a script cuts it to music made in code.

## Making shorts

On GitHub: **Actions → Glass Run shorts → Run workflow**. Choose how many and what kind (random gives each short a
different kind), and run it. When it is done (about half an hour to an hour; the shorts are made side by side),
open the run and download **glass-run-shorts**: an `.mp4` for each short and a `.txt` with a title and a description
to paste into YouTube.

To make the same shorts again, give the seed the run printed in its **Plan the shorts** step.

## What kind

- **perfect**: a clean run, nothing missed
- **clutch**: the ball count is on screen, red and beating; the bot plays on its last few balls
- **power**: crystals of power everywhere: hot iron, three balls a throw, slow time
- **tour**: one world after another, through the checkpoint doors
- **wheel**: a run up to the great glass wheel
- **fail**: a good run that goes wrong at the end
- **sniper**: glass broken far ahead
- **chaos**: the bot throws at every glass it sees

## How each one comes out different

Each short has its own seed, and from it its own rooms, bot, length (30 to 50 s), pace, transitions, colour,
words and music. The cut follows what happened in the run (the game writes it down as it plays): the first bar is a
hook (the best moment, or the lowest the balls got); big moments come on a speed ramp or in slow motion; busy
stretches play as they were; quiet stretches are fast-forwarded or cut out. Every cut is on the beat, and the drop
of the music lands on the biggest moment. It ends on "PART 2?", loops back to the start, or (for a fail) winds down.

The music is synthesised by `music.mjs` (phonk, trap, EDM, lo-fi, cinematic or synthwave, in a new key and tune each
time): no samples, nothing to license. To hear one of each: `node shorts/music.mjs --demo demo/`.

## Files

- `plan.py`: the recipe for each short (what to record, how to cut it, the words)
- `record.py`: plays and records the takes (the game's `--shorts` mode, Godot's Movie Maker)
- `edit.py`: cuts the takes into the short; `--selftest` checks the whole cut on made-up takes
- `music.mjs`: the music
