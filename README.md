# Glass Garden

Two games, each its own app:

- **Smash Room** (this page): rooms full of glass to break, in the browser and on Android. APK: `SmashRoom.apk`.
- **Glass Run** ([glass-run/](glass-run/README.md)): the Godot game, a run through worlds of glass. APK: `GlassRun.apk`. YouTube Shorts of it: [shorts/](shorts/README.md).

# Smash Room

A calm, stress-relief glass-breaking game, made with three.js (r170) and cannon-es. It runs in the browser and as an Android app.

- **Free play:** four cosy rooms full of glass to break with a slingshot, ball, hammer or an earthquake. Rewind puts every piece back.
- **Garden Run:** an endless path through a garden, a jungle, the mountains and along a river. Each zone has its own glass, and a glass pavilion comes down in slow motion before every checkpoint.
- **The sky:** after each pavilion the path lifts off into the clouds. Up there the glass moves: a spinning glass fan, glass scissors, a swinging lens, a glass serpent, a storm cloud charging a pane, flocks of glass birds, rings to fly through, and walls of thin and thick glass (thick takes two or three hits). Each sky ends with a great turning glass wheel, then a dive back down into the next zone.

## Android app

Every push to `main` builds an APK on GitHub (see **Actions → Android APK**).
The newest one is always on the [latest release](../../releases/tag/latest): download `SmashRoom.apk` on your phone and open it to install (allow installing from your browser when Android asks). It is a new app since the game was renamed: if the game is on your phone under its old name, uninstall that one.

The app has the game and its libraries inside, so it works offline.

If the download does not start, open the release link in Chrome itself (not inside another app's built-in browser), choose **Download anyway** if Chrome warns about the file, and **Install anyway** if Play Protect asks: it is a debug build, so Android does not know it yet.

## Play in the browser

Open `index.html` in a modern browser (it loads three.js and cannon-es from jsDelivr), or serve the folder:

```
npx serve .
```

## Phones

On phones the game runs at 30 frames a second, uses lighter glass and draws fewer pixels, so the phone stays cool. Settings → Graphics lets you pick Low / Medium / High and 30 or 60 frames a second.

## Project layout

- `index.html` — the whole game (web version).
- `scripts/build-app.mjs` — makes `www/`, the app's offline copy (libraries and font served locally).
- `android/` — the Capacitor Android project (full screen, screen kept on, app icon).
- `.github/workflows/android.yml` — builds the APK and publishes it to the `latest` release.

Build the APK yourself (needs Node 22, JDK 21 and the Android SDK):

```
npm ci
npm run sync
cd android && ./gradlew assembleDebug
```

The APK is signed with a test key kept in the repo, so each new build installs over the last one. A Play Store release needs its own private signing key (not in the repo).
