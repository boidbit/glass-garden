# Glass Run shorts

YouTube Shorts of Glass Run, made on GitHub with nothing installed on your computer: the bot plays the game,
Godot records it in a tall 1080×1920 window, and a script cuts it to music made in code.

## Making shorts

On GitHub: **Actions → Glass Run shorts → Run workflow**. Choose how many and what kind (random gives each short a
different kind), and run it. When it is done (about half an hour to an hour; the shorts are made side by side),
open the run and download **glass-run-shorts**: an `.mp4` for each short and a `.txt` with a title and a description
to paste into YouTube.

To make the same shorts again, give the seed the run printed in its **Plan the shorts** step.

## Shorts with a meme

**Actions → Glass Run shorts + memes** does everything above, and for some shorts cuts the same recorded takes a
second time with a reaction meme from Giphy right after the biggest moment. Each short comes out as
`short-01-fail.mp4` (as before) and `short-01-fail-meme.mp4`, so the two can be compared on YouTube. The `memes`
choice picks which shorts get the second cut: `fail-clutch` (the default), `all`, or `none`.

- Needs the repo secret `GIPHY_API_KEY` (Settings → Secrets and variables → Actions).
- The words to search come from the style and the biggest moment (`oh no` after a miss, `wow` at a door, and so on;
  see `meme.py`). Only G and PG clips of 1 to 8 seconds. The meme's search word and link are in its `.txt`/`.json`.
- The clip is shown as a card on a blurred copy of itself, for 2 to 6 beats, never in the first shot or the ending.
  Giphy's mp4s have no sound, so the music goes on under it, with a hit as it lands.
- If Giphy gives nothing, `memes-backup.txt` (direct mp4 links, empty to begin with) is tried; after that the meme
  cut is made without a meme. The plain short is made first and is never held up.
- `python3 shorts/edit.py --selftest work --style tour --meme` checks the meme cut with a made-up clip, no web needed.

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
- `meme.py`: finds a meme on Giphy and cuts it to a card (only with `edit.py --meme`)
- `memes-backup.txt`: direct links to use when Giphy gives nothing
