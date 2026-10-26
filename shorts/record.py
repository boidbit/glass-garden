#!/usr/bin/env python3
"""Records the takes of one short: Glass Run plays itself (the bot) in a tall window on a virtual screen,
and Godot's Movie Maker writes every frame and the game's sound to an AVI, at a steady 30 frames a second
however slowly the frames are drawn. The game also writes what happens (glass, doors, crashes) beside it.

  python3 shorts/record.py --recipe recipe.json --out takes/ --godot ~/godot/Godot_v4.x_linux.x86_64
"""
import argparse
import json
import os
import subprocess
import sys
import time

HERE = os.path.dirname(os.path.abspath(__file__))
PROJECT = os.path.join(os.path.dirname(HERE), "kaanch-run")
OVERRIDE = os.path.join(PROJECT, "override.cfg")


def tall_window(w, h):
    """Godot reads override.cfg beside project.godot as it starts: the window opens at this size from the first frame
    (with --resolution alone the first shorts came out wide, and were stretched). The base size of the screens is left
    as it is."""
    with open(OVERRIDE, "w") as f:
        f.write("[display]\n\nwindow/size/window_width_override=%d\nwindow/size/window_height_override=%d\n" % (w, h))


def video_size(path):
    p = subprocess.run(["ffprobe", "-v", "error", "-select_streams", "v:0", "-show_entries", "stream=width,height",
                        "-of", "csv=p=0", path], capture_output=True, text=True)
    try:
        w, h = p.stdout.strip().split(",")[:2]
        return int(w), int(h)
    except ValueError:
        return 0, 0


def read_events(path):
    out = []
    for line in open(path, encoding="utf-8"):
        try:
            out.append(json.loads(line))
        except ValueError:
            pass
    return out


def take_args(t, events, fps):
    a = ["--auto", "--shorts", "--mode=endless", "--from=%d" % t["room"], "--bot=" + t["bot"], "--seed=%d" % t["seed"],
         "--max-time=%s" % t["max_time"], "--fov=%s" % t["fov"], "--pow=%s" % t["pow"], "--fps=%d" % fps,
         "--events=" + events]
    if t["quit_on"]:
        a += ["--quit-on=" + t["quit_on"], "--quit-after=%s" % t["quit_after"]]
    if t["balls"] > 0:
        a.append("--balls=%d" % t["balls"])
    if t["hud"]:
        a.append("--hud=balls")
    if t["fail_after"] > 0:
        a.append("--fail-after=%s" % t["fail_after"])
    return a


def record(t, out, godot, size, fps, tries=2):
    w, h = size
    # absolute paths: Godot works from the project folder
    avi = os.path.abspath(os.path.join(out, t["name"] + ".avi"))
    events = os.path.abspath(os.path.join(out, t["name"] + ".jsonl"))
    for attempt in range(tries):
        for f in (avi, events):
            if os.path.exists(f):
                os.remove(f)
        side = max(w, h) + 200
        cmd = ["xvfb-run", "-a", "-s", "-screen 0 %dx%dx24" % (side, side),
               godot, "--rendering-driver", "opengl3", "--resolution", "%dx%d" % (w, h), "--fixed-fps", str(fps),
               "--write-movie", avi, "--path", PROJECT, "--"] + take_args(t, events, fps)
        print("take %s: room %d, %s bot, up to %ss" % (t["name"], t["room"], t["bot"], t["max_time"]), flush=True)
        t0 = time.time()
        env = dict(os.environ, LIBGL_ALWAYS_SOFTWARE="1")
        p = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True, env=env, timeout=5400)
        log = p.stdout or ""
        ok = os.path.exists(avi) and os.path.getsize(avi) > 100000 and os.path.exists(events)
        start = next((e for e in read_events(events) if e.get("e") == "start"), None) if ok else None
        print("  %s in %.0f s" % ("recorded" if start else "FAILED", time.time() - t0), flush=True)
        if start:
            # a picture of another shape would come out stretched: stop here and say so, rather than make a bad short
            got = video_size(avi)
            print("  %dx%d (the game saw a window of %s)" % (got[0], got[1], start.get("window")), flush=True)
            if got != (w, h):
                print("\n".join(log.splitlines()[-30:]))
                sys.exit("take %s came out %dx%d, not %dx%d" % (t["name"], got[0], got[1], w, h))
            return True
        print("\n".join(log.splitlines()[-30:]))
        t["seed"] += 1
    return False


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--recipe", required=True)
    ap.add_argument("--out", required=True)
    ap.add_argument("--godot", required=True)
    ap.add_argument("--size", default="1080x1920")
    ap.add_argument("--fps", type=int, default=30)
    a = ap.parse_args()
    rec = json.load(open(a.recipe))
    os.makedirs(a.out, exist_ok=True)
    size = tuple(int(x) for x in a.size.split("x"))
    good = 0
    tall_window(*size)
    try:
        for t in rec["takes"]:
            if record(t, a.out, os.path.expanduser(a.godot), size, a.fps):
                good += 1
    finally:
        os.remove(OVERRIDE)
    if good == 0:
        sys.exit("no take was recorded")
    print("%d of %d takes recorded" % (good, len(rec["takes"])))


if __name__ == "__main__":
    main()
