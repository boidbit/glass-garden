#!/usr/bin/env bash
# Glass Rush flies through the worlds of Glass Run: the worlds, the glass, the sounds and the little effects are
# Glass Run's own files, copied here unchanged (a Godot project only sees its own folder). Run this after changing
# them in glass-run/; the APK workflow runs it too, so a build always has the newest. Never edit the copies here.
set -e
here="$(cd "$(dirname "$0")/.." && pwd)"
run="$here/../glass-run"
for f in worlds.gd glass.gd sfx.gd fx.gd; do
  cp "$run/scripts/$f" "$here/scripts/$f"
done
cp "$run/fonts/bricolage-600.woff2" "$run/fonts/bricolage-800.woff2" "$here/fonts/"
echo "shared files copied from glass-run"
