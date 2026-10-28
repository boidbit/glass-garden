#!/usr/bin/env python3
"""Finds one reaction meme for a short, on Giphy, and cuts it to a card for the edit (shorts/edit.py --meme).

What it picks from: the style of the short and its biggest moment give the words to search for; the seed picks among
the words and the results. Only G and PG clips, 1 to 8 seconds long. Needs GIPHY_API_KEY in the environment (a repo
secret on GitHub). Without it, or when nothing is found, it falls back to the links in shorts/memes-backup.txt, and
after that there is no meme and the short is cut without one: a missing meme never stops a run.

Giphy's mp4s have no sound, so the meme is a picture only; the music goes on under it.

  python3 shorts/meme.py --try "oh no" [--out work/]      what a search finds, to check the key
"""
import argparse
import json
import os
import random
import subprocess
import sys
import urllib.error
import urllib.parse
import urllib.request

HERE = os.path.dirname(os.path.abspath(__file__))
API = "https://api.giphy.com/v1/gifs/search"
BACKUP = os.path.join(HERE, "memes-backup.txt")
UA = {"User-Agent": "glass-run-shorts"}
MIN_S, MAX_S = 1.0, 8.0
MAX_BYTES = 12_000_000
# the mp4 to take from a result, best first
RENDITIONS = ("hd", "original_mp4", "original", "fixed_height", "fixed_width", "downsized_small")
NET_ERRORS = (urllib.error.URLError, OSError, ValueError)

# what to search for: from the biggest moment of the short, and from its style
BY_MOMENT = {
    "over": ["oh no", "bruh", "nooo"],
    "crash": ["oh no", "bruh", "nooo"],
    "door": ["wow", "wait what", "amazing"],
    "finale": ["shocked", "omg", "mind blown"],
    "blast": ["explosion", "mind blown", "lets go"],
    "chain": ["wow", "satisfying", "nice"],
    "prism": ["wow", "amazing", "nice"],
    "chandelier": ["wow", "oh no", "amazing"],
    "power": ["lets go", "mind blown", "unstoppable"],
}
BY_STYLE = {
    "perfect": ["satisfying", "nice", "chefs kiss"],
    "clutch": ["sweating", "nervous", "phew"],
    "power": ["lets go", "unstoppable", "mind blown"],
    "tour": ["wow", "amazing", "wait what"],
    "wheel": ["shocked", "omg", "mind blown"],
    "fail": ["oh no", "bruh", "sad"],
    "sniper": ["headshot", "nice shot", "sniper"],
    "chaos": ["explosion", "chaos", "mind blown"],
}
# styles about the place or the thing (what the moment is), the rest are about how it went (the style)
MOMENT_FIRST = ("tour", "wheel", "power", "chaos")
GENERIC = ["reaction", "wow", "oh no"]


def terms_for(style, kind):
    by_m, by_s = list(BY_MOMENT.get(kind, [])), list(BY_STYLE.get(style, []))
    return (by_m, by_s) if style in MOMENT_FIRST else (by_s, by_m)


def search(key, term, limit=25):
    q = urllib.parse.urlencode({"api_key": key, "q": term, "limit": limit, "rating": "pg", "lang": "en"})
    with urllib.request.urlopen(urllib.request.Request(API + "?" + q, headers=UA), timeout=20) as r:
        return json.load(r).get("data") or []


def mp4_of(item):
    imgs = item.get("images") or {}
    for k in RENDITIONS:
        u = (imgs.get(k) or {}).get("mp4")
        if u:
            return u
    return None


def download(url, path):
    with urllib.request.urlopen(urllib.request.Request(url, headers=UA), timeout=30) as r:
        data = r.read(MAX_BYTES + 1)
    if len(data) > MAX_BYTES or len(data) < 1000:
        return False
    with open(path, "wb") as f:
        f.write(data)
    return True


def probe(path):
    p = subprocess.run(["ffprobe", "-v", "error", "-show_entries", "format=duration", "-of", "csv=p=0", path],
                       capture_output=True, text=True)
    try:
        return float(p.stdout.strip().split(",")[0])
    except ValueError:
        return None


def take_if_good(url, work):
    """downloads the clip; the clip, or None if it is no good (too big, too short, too long, not a video)"""
    path = os.path.join(work, "meme-raw.mp4")
    try:
        if not download(url, path):
            return None
    except NET_ERRORS:
        return None
    d = probe(path)
    if d is None or not MIN_S <= d <= MAX_S:
        return None
    return path, d


def from_giphy(key, terms, rng, work):
    for term in terms[:4]:
        try:
            items = search(key, term)
        except urllib.error.HTTPError as e:
            print("meme: Giphy said %d for '%s'" % (e.code, term))
            if e.code in (401, 403, 429):
                return None  # a wrong key, or too many searches: the next word will not help
            continue
        except NET_ERRORS as e:
            print("meme: search '%s' failed (%s)" % (term, e))
            continue
        rng.shuffle(items)
        for it in items[:8]:
            url = mp4_of(it)
            got = take_if_good(url, work) if url else None
            if got:
                return {"path": got[0], "dur": got[1], "term": term, "id": it.get("id", ""), "title": it.get("title", ""), "url": url}
        print("meme: nothing usable for '%s'" % term)
    return None


def from_backup(rng, work):
    if not os.path.exists(BACKUP):
        return None
    urls = []
    for line in open(BACKUP, encoding="utf-8"):
        line = line.strip()
        if line and not line.startswith("#"):
            urls.append(line)
    rng.shuffle(urls)
    for url in urls[:6]:
        got = take_if_good(url, work)
        if got:
            return {"path": got[0], "dur": got[1], "term": "(backup list)", "id": "", "title": "", "url": url}
    return None


def pick(rec, kind, work, fake=None):
    """one meme for this short: {"path", "dur", "term", "id", "title", "url"}, or None.
    kind is the biggest moment of the short; fake is a clip to use instead of the web (for the self-test)."""
    os.makedirs(work, exist_ok=True)
    if fake:
        return {"path": fake, "dur": probe(fake) or 2.4, "term": "(selftest)", "id": "", "title": "selftest", "url": fake}
    rng = random.Random(rec["seed"] * 17 + 3)
    first, second = terms_for(rec["style"], kind)
    rng.shuffle(first)
    rng.shuffle(second)
    terms = first[:2] + second[:1] + GENERIC
    key = os.environ.get("GIPHY_API_KEY", "").strip()
    found = None
    if key:
        found = from_giphy(key, terms, rng, work)
    else:
        print("meme: GIPHY_API_KEY is not set")
    return found or from_backup(rng, work)


def card(src, out, dur, w, h):
    """the clip as a card on a blurred copy of itself, looped or cut to `dur` seconds, 30 fps, no sound"""
    fg_w, fg_h = w - 80, int(h * 0.85)
    graph = ("[0:v]fps=30,split[a][b];"
             "[a]scale=%d:%d:force_original_aspect_ratio=increase,crop=%d:%d,boxblur=20:2,eq=brightness=-0.12[bg];"
             "[b]scale=%d:%d:force_original_aspect_ratio=decrease:force_divisible_by=2:flags=lanczos[fg];"
             "[bg][fg]overlay=(W-w)/2:(H-h)/2,format=yuv420p[v]" % (w, h, w, h, fg_w, fg_h))
    p = subprocess.run(["ffmpeg", "-v", "error", "-y", "-stream_loop", "-1", "-i", src, "-t", "%.3f" % dur,
                        "-filter_complex", graph, "-map", "[v]", "-an", "-c:v", "libx264", "-preset", "veryfast",
                        "-crf", "17", out], capture_output=True, text=True)
    if p.returncode != 0:
        print("meme: the card failed: %s" % p.stderr[-400:])
        return False
    return os.path.exists(out)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--try", dest="term", help="search this word and report what comes back")
    ap.add_argument("--out", default="meme-test")
    a = ap.parse_args()
    if not a.term:
        sys.exit("use --try WORD, to check the Giphy key")
    key = os.environ.get("GIPHY_API_KEY", "").strip()
    if not key:
        print("::warning::GIPHY_API_KEY is empty: add it under Settings > Secrets and variables > Actions")
        return
    os.makedirs(a.out, exist_ok=True)
    got = from_giphy(key, [a.term], random.Random(1), a.out)
    if got:
        print("meme test: OK, '%s' gave %s (%.1f s) %s" % (a.term, got["title"] or got["id"], got["dur"], got["url"]))
    else:
        print("::warning::meme test: Giphy gave nothing for '%s' (wrong key? too many searches?)" % a.term)


if __name__ == "__main__":
    main()
