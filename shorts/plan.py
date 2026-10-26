#!/usr/bin/env python3
"""Plans Glass Run shorts. Each short gets a recipe from its seed: a style (how the bot plays and what the
video is about), the takes to record (which room to start in, which bot, when to stop), how to cut it (length,
pace, ending, transitions, colour), the music (style, tempo) and the words on screen.

  python3 shorts/plan.py --matrix --count 5 [--style random] [--seed 123]   the list of shorts, for the workflow
  python3 shorts/plan.py --recipe --seed 12301 --style clutch               one short's recipe, as JSON
"""
import argparse
import json
import random
import sys
import time

STYLES = ["perfect", "clutch", "power", "tour", "wheel", "fail", "sniper", "chaos"]

# the endless run: a new world every three rooms (a checkpoint door at the end of the third),
# a great glass wheel at the end of every tenth room
WORLDS = ["cathedral", "venice", "lanterns", "mosaic", "sheesh"]
WORLD_NAMES = {"cathedral": "CATHEDRAL", "venice": "VENICE", "lanterns": "LANTERN NIGHT", "mosaic": "MOSAIC COURT", "sheesh": "SHEESH MAHAL"}


def world_of(room):
    return WORLDS[(room // 3) % len(WORLDS)]


DOOR_ROOMS = list(range(2, 100, 3))
WHEEL_ROOMS = list(range(9, 100, 10))

# music for each style of short, and the tempo range of each music style (as in shorts/music.mjs)
MUSIC_FOR = {
    "perfect": ["lofi", "edm", "synthwave"],
    "clutch": ["phonk", "trap", "cinematic"],
    "power": ["edm", "phonk", "trap"],
    "tour": ["cinematic", "edm", "synthwave"],
    "wheel": ["cinematic", "phonk", "edm"],
    "fail": ["trap", "phonk"],
    "sniper": ["lofi", "synthwave", "cinematic"],
    "chaos": ["edm", "phonk", "trap"],
}
BPM = {"phonk": (128, 148), "trap": (136, 156), "edm": (122, 128), "lofi": (74, 88), "cinematic": (92, 108), "synthwave": (100, 116)}

# the first words on screen. *word* is drawn in the highlight colour.
# {n} balls left, {glass} glass broken in the video, {worlds} worlds in the video, {sec} seconds of video
HOOKS = {
    "perfect": ["THE MOST *SATISFYING* RUN EVER", "*ZERO* MISSES. WATCH.", "PERFECT RUN. *NO CRASHES.*", "TELL ME THIS ISN'T *SATISFYING*",
                "I BROKE *EVERY* SINGLE GLASS", "THIS IS *SO* SATISFYING"],
    "clutch": ["*{n}* BALLS LEFT...", "LAST BALL. *NO PRESSURE.*", "ONE MISS AND IT'S *OVER*", "HEART RATE: *200*",
               "HOW IS THIS *STILL ALIVE?*", "DON'T. MISS. *NOW.*"],
    "power": ["HOT IRON BREAKS *EVERYTHING*", "THIS POWER-UP IS *BROKEN*", "*TRIPLE BALL* MODE", "POWER-UPS MAKE THIS *INSANE*"],
    "tour": ["*{worlds}* WORLDS OF GLASS IN *{sec}* SECONDS", "WHICH WORLD IS *YOUR* FAVORITE?", "GLASS AROUND *THE WORLD*",
             "FROM CATHEDRAL TO *SHEESH MAHAL*"],
    "wheel": ["THE *GIANT* GLASS WHEEL", "ONLY *1%* REACH THIS WHEEL", "WAIT FOR *THE WHEEL...*", "THE BIGGEST GLASS *IN THE GAME*"],
    "fail": ["THIS RUN WAS PERFECT... *UNTIL*", "WAIT FOR *THE ENDING*", "SO CLOSE. *SO CLOSE.*", "I SHOULDN'T HAVE *MISSED THAT*"],
    "sniper": ["LONG RANGE *GLASS SNIPER*", "BREAKING GLASS FROM *40M* AWAY", "NEVER LET IT *GET CLOSE*", "*PERFECT* AIM ONLY"],
    "chaos": ["BREAK *EVERYTHING*", "MAXIMUM *DESTRUCTION*", "HOW MUCH GLASS CAN I *BREAK?*", "*{glass}* GLASS IN *{sec}* SECONDS"],
}
REACT = ["NO WAY", "SO CLEAN", "PERFECT", "BOOM", "TOO EASY", "INSANE", "WHAT?!", "SATISFYING"]
REACT_CLUTCH = ["SAVED!", "CLOSE ONE", "PHEW", "+5 BALLS", "STILL ALIVE"]
BEFORE_BIG = ["WAIT FOR IT...", "HERE IT COMES...", "WATCH THIS"]
ENDS = {
    "part2": ["PART 2?", "HOW FAR CAN IT GO?", "SHOULD I KEEP GOING?", "COMMENT YOUR *SCORE*"],
    "fail": ["SO CLOSE...", "RUN OVER.", "ONE MORE TRY?", "I WAS *SO* CLOSE"],
    "clean": ["*{glass}* GLASS. *0* MISSES.", "FOLLOW FOR *MORE*", "SATISFYING? *YES.*", ""],
}
TITLE_TAGS = "#shorts #glassrun #satisfying #glass #asmr #gaming #mobilegame"


def recipe(seed, style):
    r = random.Random(seed)
    takes = []

    def take(room, bot="perfect", max_time=26.0, quit_on="", quit_after=3.0, balls=-1, pow_rate=0.2, hud=False, fail_after=0.0):
        takes.append({
            "name": "t%d" % (len(takes) + 1), "room": room, "world": world_of(room), "bot": bot,
            "seed": r.randrange(1, 10 ** 6), "max_time": round(max_time, 1), "quit_on": quit_on, "quit_after": quit_after,
            "balls": balls, "pow": pow_rate, "hud": hud, "fail_after": round(fail_after, 1), "fov": round(r.uniform(14.0, 19.0), 1),
        })

    def some_rooms(k, lo=1, hi=60):
        return r.sample(range(lo, hi), k)

    if style in ("perfect", "sniper", "chaos"):
        bot = style
        pr = 0.4 if style == "chaos" else 0.2
        rooms = some_rooms(r.choice([2, 3]))
        for room in rooms:
            take(room, bot, r.uniform(20, 28), pow_rate=pr)
        if r.random() < 0.6:
            take(r.choice(DOOR_ROOMS[:20]), bot, 36, quit_on="door", quit_after=3.0, pow_rate=pr)
    elif style == "power":
        for room in some_rooms(3, 1, 50):
            take(room, "power", r.uniform(22, 28), pow_rate=0.75)
    elif style == "clutch":
        for room in r.sample(DOOR_ROOMS[:16], 2):
            take(room, "clutch", 40, quit_on="door", quit_after=3.0, balls=r.randint(5, 8), hud=True)
    elif style == "tour":
        n = r.choice([3, 4])
        k = r.randrange(0, 5)
        for i in range(n):
            room = DOOR_ROOMS[(k + i) % 5 + 5 * r.choice([0, 0, 1])]
            take(room, r.choice(["perfect", "sniper"]), 36, quit_on="door", quit_after=2.5)
    elif style == "wheel":
        take(r.choice(some_rooms(3)), "perfect", r.uniform(16, 22))
        take(r.choice(WHEEL_ROOMS[:6]), r.choice(["perfect", "sniper"]), 42, quit_on="finale", quit_after=3.5)
    elif style == "fail":
        take(r.choice(some_rooms(3)), "perfect", r.uniform(16, 22))
        take(r.choice(some_rooms(3, 3, 50)), "fail", 44, quit_on="over", quit_after=2.5, balls=r.randint(10, 14),
             fail_after=r.uniform(6, 12))

    music = r.choice(MUSIC_FOR[style])
    if style == "fail":
        ending = "fail"
    else:
        ending = r.choice(["loop", "part2", "clean", "loop"])
    pace = {"tour": ["hyper", "mixed"], "chaos": ["hyper", "mixed"], "power": ["hyper", "mixed"],
            "perfect": ["flow", "mixed"], "sniper": ["flow", "mixed"], "clutch": ["mixed", "flow"],
            "wheel": ["mixed", "hyper", "flow"], "fail": ["mixed", "flow"]}[style]
    trans = r.sample(["flash", "zoom", "whip", "glitch", "shatter", "iris"], r.choice([3, 4]))
    return {
        "seed": seed, "style": style,
        "takes": takes,
        "edit": {
            "length": r.randint(30, 50),
            "pace": r.choice(pace),
            "ending": ending,
            "hook": "low" if style == "clutch" else r.choice(["flash", "flash", "cold"]),
            "transitions": trans,
            "counter": style in ("perfect", "sniper", "chaos", "power") and r.random() < 0.55,
            "react": r.random() < 0.75,
            "grade": {"sat": round(r.uniform(1.0, 1.28), 2), "contrast": round(r.uniform(1.0, 1.14), 2), "warm": round(r.uniform(-0.04, 0.07), 3)},
            "accent": r.choice(["#FFD36B", "#5FF2DC", "#FF5A5A", "#FF9F45", "#B98CFF"]),
            "game_db": {"lofi": 0.0, "cinematic": -2.0, "synthwave": -2.0}.get(music, -3.5),
        },
        "music": {"style": music, "bpm": r.randint(*BPM[music]), "seed": r.randrange(1, 10 ** 6)},
        "text": {
            "hook": r.choice(HOOKS[style]),
            "react": r.choice(REACT_CLUTCH if style == "clutch" else REACT),
            "before": r.choice(BEFORE_BIG),
            "end": r.choice(ENDS.get(ending, [""])),
        },
    }


def styles_for(count, style, r):
    if style != "random":
        return [style] * count
    out = []
    while len(out) < count:
        bag = STYLES[:]
        r.shuffle(bag)
        out += bag
    return out[:count]


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--matrix", action="store_true")
    ap.add_argument("--recipe", action="store_true")
    ap.add_argument("--count", type=int, default=3)
    ap.add_argument("--style", default="random")
    ap.add_argument("--seed", default="")
    a = ap.parse_args()
    if a.style != "random" and a.style not in STYLES:
        sys.exit("style must be random or one of: " + ", ".join(STYLES))
    base = int(a.seed) if str(a.seed).strip() else int(time.time()) % 1000000
    if a.matrix:
        r = random.Random(base)
        styles = styles_for(a.count, a.style, r)
        inc = [{"n": i + 1, "seed": base * 100 + i + 1, "style": s} for i, s in enumerate(styles)]
        print("matrix=" + json.dumps({"include": inc}))
    else:
        print(json.dumps(recipe(base, a.style if a.style != "random" else random.Random(base).choice(STYLES)), indent=1))


if __name__ == "__main__":
    main()
